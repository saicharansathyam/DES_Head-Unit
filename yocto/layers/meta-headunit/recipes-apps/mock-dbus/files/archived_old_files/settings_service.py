#!/usr/bin/env python3
"""
Extended Settings Service with WiFi, Bluetooth, and Sound control
Integrates with existing MediaPlayer service
"""

import sys
import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib
import subprocess

SERVICE_NAME = "com.headunit.SettingsService"
OBJECT_PATH = "/com/headunit/Settings"
INTERFACE_NAME = "com.headunit.Settings"

class SettingsService(dbus.service.Object):
    """DBus service for system settings"""
    
    def __init__(self, bus, object_path):
        super().__init__(bus, object_path)
        self.system_volume = 50
        print(f"Settings service started on {OBJECT_PATH}")
    
    # WiFi Methods
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
            return lines[0] if lines else "Not connected"
        except Exception as e:
            print(f"Get WiFi error: {e}")
            return "Error"
    
    # Bluetooth Methods
    @dbus.service.method(INTERFACE_NAME, in_signature='b', out_signature='')
    def SetBluetoothEnabled(self, enabled):
        """Enable or disable Bluetooth"""
        try:
            state = 'on' if enabled else 'off'
            subprocess.run(['rfkill', 'unblock', 'bluetooth'], timeout=5)
            subprocess.run(['bluetoothctl', 'power', state], timeout=5)
            self.BluetoothStateChanged(enabled)
            print(f"Bluetooth {'enabled' if enabled else 'disabled'}")
        except Exception as e:
            print(f"Bluetooth enable error: {e}")
    
    @dbus.service.method(INTERFACE_NAME, in_signature='', out_signature='as')
    def ScanBluetoothDevices(self):
        """Scan for Bluetooth devices"""
        try:
            # Start scan
            subprocess.run(['bluetoothctl', 'scan', 'on'], timeout=2)
            GLib.timeout_add_seconds(5, self._stop_bt_scan)
            return dbus.Array([], signature='s')  # Devices will come via signal
        except Exception as e:
            print(f"Bluetooth scan error: {e}")
            return dbus.Array([], signature='s')
    
    def _stop_bt_scan(self):
        """Stop Bluetooth scan"""
        try:
            subprocess.run(['bluetoothctl', 'scan', 'off'], timeout=2)
        except:
            pass
        return False
    
    @dbus.service.method(INTERFACE_NAME, in_signature='s', out_signature='b')
    def PairBluetoothDevice(self, address):
        """Pair with Bluetooth device"""
        try:
            result = subprocess.run(
                ['bluetoothctl', 'pair', address],
                capture_output=True,
                timeout=30
            )
            success = result.returncode == 0
            if success:
                self.BluetoothDevicePaired(address)
                print(f"Paired with device: {address}")
            return success
        except Exception as e:
            print(f"Bluetooth pair error: {e}")
            return False
    
    @dbus.service.method(INTERFACE_NAME, in_signature='s', out_signature='b')
    def ConnectBluetoothDevice(self, address):
        """Connect to paired Bluetooth device"""
        try:
            result = subprocess.run(
                ['bluetoothctl', 'connect', address],
                capture_output=True,
                timeout=20
            )
            success = result.returncode == 0
            if success:
                self.BluetoothDeviceConnected(address)
                print(f"Connected to device: {address}")
            return success
        except Exception as e:
            print(f"Bluetooth connect error: {e}")
            return False
    
    # Sound Methods
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
    
    # Signals
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
    
    @dbus.service.signal(INTERFACE_NAME, signature='i')
    def SystemVolumeChanged(self, volume):
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
    print("Service ready. Press Ctrl+C to exit.")
    
    loop = GLib.MainLoop()
    try:
        loop.run()
    except KeyboardInterrupt:
        print("\nShutting down...")
        loop.quit()

if __name__ == '__main__':
    main()

