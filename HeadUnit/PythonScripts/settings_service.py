#!/usr/bin/env python3

"""
Extended Settings Service with WiFi, Bluetooth, Sound, and Clock control
Uses proper BlueZ D-Bus API for Bluetooth operations
"""

import sys
import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib
import subprocess
from datetime import datetime

SERVICE_NAME = "com.headunit.SettingsService"
OBJECT_PATH = "/com/headunit/Settings"
INTERFACE_NAME = "com.headunit.Settings"

# BlueZ D-Bus constants
BLUEZ_SERVICE = "org.bluez"
ADAPTER_INTERFACE = "org.bluez.Adapter1"
DEVICE_INTERFACE = "org.bluez.Device1"


class SettingsService(dbus.service.Object):
    """DBus service for system settings"""
    
    def __init__(self, bus, object_path):
        super().__init__(bus, object_path)
        self.system_volume = 50
        self.bluetooth_adapter = None
        self.system_bus = None
        self._load_initial_volume()
        self._init_bluetooth()
        print(f"Settings service started on {OBJECT_PATH}")
    
    def _load_initial_volume(self):
        """Load current system volume"""
        try:
            result = subprocess.run(
                ['amixer', 'get', 'Master'],
                capture_output=True,
                text=True,
                timeout=2
            )
            # Parse volume from output
            for line in result.stdout.split('\n'):
                if '[' in line and '%' in line:
                    vol_str = line.split('[')[1].split('%')[0]
                    self.system_volume = int(vol_str)
                    break
        except Exception as e:
            print(f"Failed to load initial volume: {e}")
    
    def _init_bluetooth(self):
        """Initialize Bluetooth D-Bus connection"""
        try:
            # Connect to system bus for Bluetooth
            self.system_bus = dbus.SystemBus()
            
            # Get the default Bluetooth adapter (usually hci0)
            adapter_path = "/org/bluez/hci0"
            self.bluetooth_adapter = self.system_bus.get_object(
                BLUEZ_SERVICE, 
                adapter_path
            )
            print(f"Bluetooth adapter initialized: {adapter_path}")
        except Exception as e:
            print(f"Bluetooth initialization error: {e}")
            self.bluetooth_adapter = None
    
    def _get_adapter_properties(self):
        """Get Bluetooth adapter properties interface"""
        if not self.bluetooth_adapter:
            return None
        return dbus.Interface(
            self.bluetooth_adapter, 
            "org.freedesktop.DBus.Properties"
        )
    
    def _get_adapter_interface(self):
        """Get Bluetooth adapter interface"""
        if not self.bluetooth_adapter:
            return None
        return dbus.Interface(self.bluetooth_adapter, ADAPTER_INTERFACE)
    
    # ========== WiFi Methods ========== (Keep as before)
    
    @dbus.service.method(INTERFACE_NAME, in_signature='', out_signature='as')
    def ScanWiFiNetworks(self):
        """Scan for available WiFi networks"""
        try:
            result = subprocess.run(
                ['nmcli', '-t', '-f', 'SSID,SIGNAL,SECURITY', 'dev', 'wifi', 'list'],
                capture_output=True,
                text=True,
                timeout=10
            )
            networks = []
            for line in result.stdout.strip().split('\n'):
                if line:
                    networks.append(line)
            return dbus.Array(networks, signature='s')
        except Exception as e:
            print(f"WiFi scan error: {e}")
            return dbus.Array([], signature='s')
    
    @dbus.service.method(INTERFACE_NAME, in_signature='ss', out_signature='b')
    def ConnectToWiFi(self, ssid, password):
        """Connect to WiFi network"""
        try:
            if password:
                cmd = ['nmcli', 'dev', 'wifi', 'connect', ssid, 'password', password]
            else:
                cmd = ['nmcli', 'dev', 'wifi', 'connect', ssid]
            
            result = subprocess.run(cmd, capture_output=True, timeout=30)
            success = result.returncode == 0
            
            if success:
                self.WiFiConnected(ssid)
                print(f"Connected to WiFi: {ssid}")
            else:
                print(f"Failed to connect to WiFi: {ssid}")
            
            return success
        except Exception as e:
            print(f"WiFi connect error: {e}")
            return False
    
    @dbus.service.method(INTERFACE_NAME, in_signature='', out_signature='')
    def DisconnectWiFi(self):
        """Disconnect from current WiFi"""
        try:
            subprocess.run(['nmcli', 'radio', 'wifi', 'off'], timeout=5)
            subprocess.run(['nmcli', 'radio', 'wifi', 'on'], timeout=5)
            self.WiFiDisconnected()
            print("WiFi disconnected")
        except Exception as e:
            print(f"WiFi disconnect error: {e}")
    
    @dbus.service.method(INTERFACE_NAME, in_signature='', out_signature='s')
    def GetCurrentWiFi(self):
        """Get current WiFi connection"""
        try:
            result = subprocess.run(
                ['nmcli', '-t', '-f', 'NAME', 'connection', 'show', '--active'],
                capture_output=True,
                text=True,
                timeout=5
            )
            lines = result.stdout.strip().split('\n')
            return lines[0] if lines and lines[0] else "Not connected"
        except Exception as e:
            print(f"Get WiFi error: {e}")
            return "Error"
    
    # ========== Bluetooth Methods (FIXED) ==========
    
    @dbus.service.method(INTERFACE_NAME, in_signature='b', out_signature='')
    def SetBluetoothEnabled(self, enabled):
        """Enable or disable Bluetooth"""
        try:
            if not self.bluetooth_adapter:
                print("Bluetooth adapter not available")
                return
            
            props = self._get_adapter_properties()
            if props:
                props.Set(ADAPTER_INTERFACE, "Powered", dbus.Boolean(enabled))
                self.BluetoothStateChanged(enabled)
                print(f"Bluetooth {'enabled' if enabled else 'disabled'}")
        except Exception as e:
            print(f"Bluetooth enable error: {e}")
    
    @dbus.service.method(INTERFACE_NAME, in_signature='', out_signature='as')
    def ScanBluetoothDevices(self):
        """Scan for Bluetooth devices using D-Bus"""
        try:
            if not self.bluetooth_adapter:
                print("Bluetooth adapter not available")
                return dbus.Array([], signature='s')
            
            adapter = self._get_adapter_interface()
            if not adapter:
                return dbus.Array([], signature='s')
            
            # Remove any existing discovery filter
            try:
                adapter.SetDiscoveryFilter({})
            except:
                pass  # Ignore if no filter is set
            
            # Start discovery
            adapter.StartDiscovery()
            print("Bluetooth discovery started")
            
            # Schedule stop after 10 seconds
            GLib.timeout_add_seconds(10, self._stop_bluetooth_scan)
            
            # Schedule device list retrieval after 5 seconds
            GLib.timeout_add_seconds(5, self._emit_discovered_devices)
            
            return dbus.Array([], signature='s')
        except Exception as e:
            print(f"Bluetooth scan error: {e}")
            return dbus.Array([], signature='s')
    
    def _stop_bluetooth_scan(self):
        """Stop Bluetooth discovery"""
        try:
            if self.bluetooth_adapter:
                adapter = self._get_adapter_interface()
                if adapter:
                    adapter.StopDiscovery()
                    print("Bluetooth discovery stopped")
        except Exception as e:
            # Ignore "No discovery started" error
            if "No discovery started" not in str(e):
                print(f"Stop discovery error: {e}")
        return False  # Don't repeat
    
    def _emit_discovered_devices(self):
        """Get and emit discovered Bluetooth devices (mobile phones only)"""
        try:
            if not self.system_bus:
                return False
            
            # Get BlueZ object manager
            manager = dbus.Interface(
                self.system_bus.get_object(BLUEZ_SERVICE, "/"),
                "org.freedesktop.DBus.ObjectManager"
            )
            
            objects = manager.GetManagedObjects()
            devices = []
            
            for path, interfaces in objects.items():
                if DEVICE_INTERFACE in interfaces:
                    device_props = interfaces[DEVICE_INTERFACE]
                    
                    # Filter for mobile phones only
                    # Check device class - phones typically have class 0x5A020C or similar
                    device_class = device_props.get('Class', 0)
                    icon = str(device_props.get('Icon', ''))
                    
                    # Mobile phones have major device class 0x02 (phone)
                    # Or icon contains 'phone'
                    major_class = (device_class >> 8) & 0x1F
                    is_phone = major_class == 0x02 or 'phone' in icon.lower()
                    
                    if not is_phone:
                        continue  # Skip non-phone devices
                    
                    # Extract device information
                    name = str(device_props.get('Name', 'Unknown Device'))
                    address = str(device_props.get('Address', ''))
                    paired = bool(device_props.get('Paired', False))
                    connected = bool(device_props.get('Connected', False))
                    rssi = int(device_props.get('RSSI', 0))
                    
                    # Format: name|address|paired|connected|rssi
                    device_str = f"{name}|{address}|{paired}|{connected}|{rssi}"
                    devices.append(device_str)
                    
                    print(f"Found phone: {name} ({address}) - Class: {hex(device_class)}")
            
            # Emit the discovered devices
            self.BluetoothDevicesChanged(dbus.Array(devices, signature='s'))
            print(f"Emitted {len(devices)} mobile phone devices")
            
        except Exception as e:
            print(f"Error getting Bluetooth devices: {e}")
        
        return False  # Don't repeat

    
    @dbus.service.method(INTERFACE_NAME, in_signature='s', out_signature='b')
    def PairBluetoothDevice(self, address):
        """Pair with Bluetooth device"""
        try:
            if not self.system_bus:
                return False
            
            # Convert address to object path
            device_path = f"/org/bluez/hci0/dev_{address.replace(':', '_')}"
            
            device = self.system_bus.get_object(BLUEZ_SERVICE, device_path)
            device_interface = dbus.Interface(device, DEVICE_INTERFACE)
            
            # Pair the device
            device_interface.Pair()
            
            self.BluetoothDevicePaired(address)
            print(f"Paired with device: {address}")
            return True
            
        except Exception as e:
            print(f"Bluetooth pair error: {e}")
            return False
    
    @dbus.service.method(INTERFACE_NAME, in_signature='s', out_signature='b')
    def ConnectBluetoothDevice(self, address):
        """Connect to paired Bluetooth device"""
        try:
            if not self.system_bus:
                return False
            
            # Convert address to object path
            device_path = f"/org/bluez/hci0/dev_{address.replace(':', '_')}"
            
            device = self.system_bus.get_object(BLUEZ_SERVICE, device_path)
            device_interface = dbus.Interface(device, DEVICE_INTERFACE)
            
            # Connect the device
            device_interface.Connect()
            
            self.BluetoothDeviceConnected(address)
            print(f"Connected to device: {address}")
            return True
            
        except Exception as e:
            print(f"Bluetooth connect error: {e}")
            return False
    
    # ========== Sound Methods ========== (Keep as before)
    
    @dbus.service.method(INTERFACE_NAME, in_signature='i', out_signature='')
    def SetSystemVolume(self, volume):
        """Set system volume (0-100)"""
        try:
            volume = max(0, min(100, volume))
            self.system_volume = volume
            
            # Set ALSA volume
            subprocess.run(
                ['amixer', 'sset', 'Master', f'{volume}%'],
                timeout=2
            )
            
            # Also update MediaPlayer service if running
            try:
                media_bus = dbus.SessionBus()
                media_service = media_bus.get_object(
                    'com.headunit.MediaPlayerService',
                    '/com/headunit/MediaPlayer'
                )
                media_service.SetVolume(volume,
                    dbus_interface='com.headunit.MediaPlayer')
            except:
                pass  # MediaPlayer service might not be running
            
            self.SystemVolumeChanged(volume)
            print(f"System volume set to: {volume}%")
        except Exception as e:
            print(f"Volume set error: {e}")
    
    @dbus.service.method(INTERFACE_NAME, in_signature='', out_signature='i')
    def GetSystemVolume(self):
        """Get current system volume"""
        return self.system_volume
    
    # ========== Clock/Time Methods ========== (Keep as before)
    
    @dbus.service.method(INTERFACE_NAME, in_signature='', out_signature='s')
    def GetCurrentTime(self):
        """Get current system time"""
        return datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    @dbus.service.method(INTERFACE_NAME, in_signature='iiiiii', out_signature='b')
    def SetSystemTime(self, year, month, day, hour, minute, second):
        """Set system time (requires sudo/privileges)"""
        try:
            time_str = f"{year:04d}-{month:02d}-{day:02d} {hour:02d}:{minute:02d}:{second:02d}"
            result = subprocess.run(
                ['sudo', 'date', '-s', time_str],
                capture_output=True,
                timeout=5
            )
            success = result.returncode == 0
            if success:
                self.SystemTimeChanged(time_str)
                print(f"System time set to: {time_str}")
            else:
                print(f"Failed to set time: {result.stderr.decode()}")
            return success
        except Exception as e:
            print(f"Set time error: {e}")
            return False
    
    @dbus.service.method(INTERFACE_NAME, in_signature='s', out_signature='b')
    def SetTimeZone(self, timezone):
        """Set system timezone (e.g., 'Europe/Berlin')"""
        try:
            result = subprocess.run(
                ['sudo', 'timedatectl', 'set-timezone', timezone],
                capture_output=True,
                timeout=5
            )
            success = result.returncode == 0
            if success:
                self.TimeZoneChanged(timezone)
                print(f"Timezone set to: {timezone}")
            return success
        except Exception as e:
            print(f"Set timezone error: {e}")
            return False
    
    @dbus.service.method(INTERFACE_NAME, in_signature='', out_signature='s')
    def GetTimeZone(self):
        """Get current timezone"""
        try:
            result = subprocess.run(
                ['timedatectl', 'show', '--property=Timezone', '--value'],
                capture_output=True,
                text=True,
                timeout=5
            )
            return result.stdout.strip() if result.returncode == 0 else "Unknown"
        except Exception as e:
            print(f"Get timezone error: {e}")
            return "Unknown"
    
    @dbus.service.method(INTERFACE_NAME, in_signature='b', out_signature='')
    def SetNTPEnabled(self, enabled):
        """Enable or disable automatic time synchronization"""
        try:
            state = 'true' if enabled else 'false'
            subprocess.run(
                ['sudo', 'timedatectl', 'set-ntp', state],
                timeout=5
            )
            self.NTPStateChanged(enabled)
            print(f"NTP {'enabled' if enabled else 'disabled'}")
        except Exception as e:
            print(f"NTP set error: {e}")
    
    # ========== Signals ==========
    
    @dbus.service.signal(INTERFACE_NAME, signature='s')
    def WiFiConnected(self, ssid):
        pass
    
    @dbus.service.signal(INTERFACE_NAME, signature='')
    def WiFiDisconnected(self):
        pass
    
    @dbus.service.signal(INTERFACE_NAME, signature='b')
    def BluetoothStateChanged(self, enabled):
        pass
    
    @dbus.service.signal(INTERFACE_NAME, signature='s')
    def BluetoothDevicePaired(self, address):
        pass
    
    @dbus.service.signal(INTERFACE_NAME, signature='s')
    def BluetoothDeviceConnected(self, address):
        pass
    
    @dbus.service.signal(INTERFACE_NAME, signature='as')
    def BluetoothDevicesChanged(self, devices):
        pass
    
    @dbus.service.signal(INTERFACE_NAME, signature='i')
    def SystemVolumeChanged(self, volume):
        pass
    
    @dbus.service.signal(INTERFACE_NAME, signature='s')
    def SystemTimeChanged(self, time):
        pass
    
    @dbus.service.signal(INTERFACE_NAME, signature='s')
    def TimeZoneChanged(self, timezone):
        pass
    
    @dbus.service.signal(INTERFACE_NAME, signature='b')
    def NTPStateChanged(self, enabled):
        pass


def main():
    """Main entry point"""
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    
    session_bus = dbus.SessionBus()
    
    if session_bus.name_has_owner(SERVICE_NAME):
        print(f"Service {SERVICE_NAME} already running")
        sys.exit(1)
    
    bus_name = dbus.service.BusName(SERVICE_NAME, bus=session_bus)
    service = SettingsService(session_bus, OBJECT_PATH)
    
    print(f"Settings service registered: {SERVICE_NAME}")
    print(f"Object path: {OBJECT_PATH}")
    print("Features: WiFi, Bluetooth (D-Bus), Sound, Clock")
    print("Service ready. Press Ctrl+C to exit.")
    
    loop = GLib.MainLoop()
    try:
        loop.run()
    except KeyboardInterrupt:
        print("\nShutting down...")
        loop.quit()


if __name__ == '__main__':
    main()

