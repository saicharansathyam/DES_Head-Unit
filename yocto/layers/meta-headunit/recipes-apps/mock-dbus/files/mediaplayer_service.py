#!/usr/bin/env python3
"""
MediaPlayer DBus Service with USB Monitoring
Handles media playback and USB device detection for HeadUnit MediaPlayer
"""

import sys
import os
import threading
from pathlib import Path
from gi.repository import GLib
import dbus
import dbus.service
import dbus.mainloop.glib

# Try to import VLC for media playback
try:
    import vlc
    HAS_VLC = True
except ImportError:
    HAS_VLC = False
    print("Warning: python-vlc not installed. Install with: pip install python-vlc")

# Try to import pyudev for USB monitoring
try:
    import pyudev
    HAS_PYUDEV = True
except ImportError:
    HAS_PYUDEV = False
    print("Warning: pyudev not installed. Install with: pip install pyudev")

SERVICE_NAME = "com.headunit.MediaPlayerService"
OBJECT_PATH = "/com/headunit/MediaPlayer"
INTERFACE_NAME = "com.headunit.MediaPlayer"

# Media file extensions
MEDIA_EXTENSIONS = {
    '.mp3', '.mp4', '.avi', '.mkv', '.mov', '.wav',
    '.flac', '.m4a', '.webm', '.ogg', '.aac', '.wma',
    '.MP3', '.MP4', '.AVI', '.MKV', '.MOV', '.WAV',
    '.FLAC', '.M4A', '.WEBM', '.OGG', '.AAC', '.WMA'
}


class USBMonitor:
    """Monitor USB device insertion and removal"""
    
    def __init__(self, callback_inserted, callback_removed):
        self.callback_inserted = callback_inserted
        self.callback_removed = callback_removed
        self.context = None
        self.monitor = None
        self.observer = None
        
        if HAS_PYUDEV:
            self._start_monitoring()
        else:
            print("USB monitoring disabled - pyudev not available")
    
    def _start_monitoring(self):
        """Start USB device monitoring"""
        try:
            self.context = pyudev.Context()
            self.monitor = pyudev.Monitor.from_netlink(self.context)
            self.monitor.filter_by(subsystem='block', device_type='partition')
            
            self.observer = pyudev.MonitorObserver(
                self.monitor,
                callback=self._device_event
            )
            self.observer.start()
            print("USB monitoring started")
        except Exception as e:
            print(f"Failed to start USB monitoring: {e}")
    
    def _device_event(self, action, device):
        """Handle USB device events"""
        try:
            # Check if it's a removable device
            if device.get('ID_BUS') == 'usb' or 'usb' in device.device_path.lower():
                mount_point = self._get_mount_point(device)
                
                if action == 'add' and mount_point:
                    print(f"USB device added: {mount_point}")
                    GLib.idle_add(self.callback_inserted, mount_point)
                elif action == 'remove':
                    print(f"USB device removed: {device.device_node}")
                    if mount_point:
                        GLib.idle_add(self.callback_removed, mount_point)
        except Exception as e:
            print(f"Error handling USB event: {e}")
    
    def _get_mount_point(self, device):
        """Get mount point for a device"""
        # Check common mount locations
        device_node = device.device_node
        
        # Read /proc/mounts to find mount point
        try:
            with open('/proc/mounts', 'r') as f:
                for line in f:
                    parts = line.split()
                    if len(parts) >= 2 and parts[0] == device_node:
                        return parts[1]
        except:
            pass
        
        return None
    
    def get_mounted_usb_devices(self):
        """Get list of currently mounted USB devices"""
        devices = []
        
        # Check common USB mount locations
        common_paths = [
            '/media',
            '/mnt',
            '/run/media'
        ]
        
        for base_path in common_paths:
            if os.path.exists(base_path):
                try:
                    for entry in os.listdir(base_path):
                        full_path = os.path.join(base_path, entry)
                        if os.path.ismount(full_path):
                            # Check if it's a removable device
                            if self._is_usb_device(full_path):
                                devices.append(full_path)
                        elif os.path.isdir(full_path):
                            # Check subdirectories (e.g., /media/username/device)
                            for sub_entry in os.listdir(full_path):
                                sub_path = os.path.join(full_path, sub_entry)
                                if os.path.ismount(sub_path) and self._is_usb_device(sub_path):
                                    devices.append(sub_path)
                except PermissionError:
                    continue
        
        return devices
    
    def _is_usb_device(self, mount_point):
        """Check if a mount point is a USB device"""
        # This is a simple heuristic - can be improved
        try:
            # Check if device has read/write access
            test_file = os.path.join(mount_point, '.usb_test')
            if os.access(mount_point, os.W_OK):
                return True
        except:
            pass
        return True  # Assume it's USB if mounted in common locations


class MediaPlayerService(dbus.service.Object):
    """DBus service for media playback with USB support"""
    
    def __init__(self, bus, object_path):
        super().__init__(bus, object_path)
        
        self.source = ""
        self.source_type = "usb"
        self.state = "Stopped"
        self.volume = 50
        self.position = 0
        self.duration = 0
        
        # USB properties
        self.usb_devices = []
        self.current_device = ""
        self.media_files = []
        self.media_file_paths = []
        
        # Initialize VLC player
        if HAS_VLC:
            self.instance = vlc.Instance('--no-xlib')
            self.player = self.instance.media_player_new()
            self.player.audio_set_volume(self.volume)
        else:
            self.instance = None
            self.player = None
        
        # Initialize USB monitor
        self.usb_monitor = USBMonitor(
            callback_inserted=self._on_usb_inserted,
            callback_removed=self._on_usb_removed
        )
        
        # Position update timer
        GLib.timeout_add(500, self._update_position)
        
        # Initial USB scan
        GLib.timeout_add(1000, self._initial_usb_scan)
        
        print(f"MediaPlayer service started on {OBJECT_PATH}")
    
    def _initial_usb_scan(self):
        """Perform initial scan for USB devices"""
        self._scan_usb_devices()
        return False  # Don't repeat
    
    def _scan_usb_devices(self):
        """Scan for USB devices"""
        devices = self.usb_monitor.get_mounted_usb_devices()
        if devices != self.usb_devices:
            self.usb_devices = devices
            self.UsbDevicesChanged(dbus.Array(self.usb_devices, signature='s'))
            print(f"Found USB devices: {self.usb_devices}")
            
            # Auto-select first device
            if self.usb_devices and not self.current_device:
                self._select_device(self.usb_devices[0])
    
    def _on_usb_inserted(self, device_path):
        """Handle USB device insertion"""
        if device_path not in self.usb_devices:
            self.usb_devices.append(device_path)
            self.UsbDevicesChanged(dbus.Array(self.usb_devices, signature='s'))
            self.UsbDeviceInserted(device_path)
            
            # Auto-select if no device selected
            if not self.current_device:
                self._select_device(device_path)
    
    def _on_usb_removed(self, device_path):
        """Handle USB device removal"""
        if device_path in self.usb_devices:
            self.usb_devices.remove(device_path)
            self.UsbDevicesChanged(dbus.Array(self.usb_devices, signature='s'))
            self.UsbDeviceRemoved(device_path)
            
            # Clear if current device was removed
            if device_path == self.current_device:
                self.current_device = ""
                self.media_files = []
                self.media_file_paths = []
                self.CurrentDeviceChanged("")
                self.MediaFilesChanged(dbus.Array([], signature='s'))
    
    def _select_device(self, device_path):
        """Select a USB device and scan for media"""
        self.current_device = device_path
        self.CurrentDeviceChanged(device_path)
        self._scan_media_files(device_path)
    
    def _scan_media_files(self, device_path):
        """Scan device for media files"""
        self.media_files = []
        self.media_file_paths = []
        
        if not os.path.exists(device_path):
            self.MediaFilesChanged(dbus.Array([], signature='s'))
            return
        
        print(f"Scanning for media in: {device_path}")
        
        try:
            # Walk through device directory
            for root, dirs, files in os.walk(device_path):
                for file in files:
                    if any(file.endswith(ext) for ext in MEDIA_EXTENSIONS):
                        file_path = os.path.join(root, file)
                        self.media_files.append(file)
                        self.media_file_paths.append(file_path)
                        
                        # Limit to 1000 files
                        if len(self.media_files) >= 1000:
                            break
                if len(self.media_files) >= 1000:
                    break
        except Exception as e:
            print(f"Error scanning media files: {e}")
        
        self.MediaFilesChanged(dbus.Array(self.media_files, signature='s'))
        print(f"Found {len(self.media_files)} media files")
    
    @dbus.service.method(INTERFACE_NAME, in_signature='', out_signature='as')
    def GetUsbDevices(self):
        """Get list of USB devices"""
        return dbus.Array(self.usb_devices, signature='s')
    
    @dbus.service.method(INTERFACE_NAME, in_signature='', out_signature='s')
    def GetCurrentDevice(self):
        """Get current USB device"""
        return self.current_device
    
    @dbus.service.method(INTERFACE_NAME, in_signature='', out_signature='as')
    def GetMediaFiles(self):
        """Get list of media files"""
        return dbus.Array(self.media_files, signature='s')
    
    @dbus.service.method(INTERFACE_NAME, in_signature='s', out_signature='')
    def SelectUsbDevice(self, device_path):
        """Select USB device"""
        if device_path in self.usb_devices:
            self._select_device(device_path)
            print(f"Selected USB device: {device_path}")
    
    @dbus.service.method(INTERFACE_NAME, in_signature='i', out_signature='')
    def SelectMediaFile(self, index):
        """Select media file by index"""
        if 0 <= index < len(self.media_file_paths):
            file_path = self.media_file_paths[index]
            self.SetSource(file_path, "usb")
            print(f"Selected media file: {self.media_files[index]}")
    
    @dbus.service.method(INTERFACE_NAME, in_signature='', out_signature='')
    def RefreshUsbDevices(self):
        """Refresh USB device list"""
        self._scan_usb_devices()
        print("Refreshed USB devices")
    
    @dbus.service.method(INTERFACE_NAME, in_signature='ss', out_signature='')
    def SetSource(self, source, source_type):
        """Set media source"""
        self.source = str(source)
        self.source_type = str(source_type)
        print(f"Source set to: {self.source} (type: {self.source_type})")
        
        if self.player and source_type == "usb":
            try:
                media = self.instance.media_new(self.source)
                self.player.set_media(media)
                self.duration = 0
                self.position = 0
                self.DurationChanged(dbus.Int64(self.duration))
                self.PositionChanged(dbus.Int64(self.position))
            except Exception as e:
                print(f"Error loading media: {e}")
    
    @dbus.service.method(INTERFACE_NAME, in_signature='', out_signature='')
    def Play(self):
        """Start playback"""
        if self.player and self.source_type == "usb":
            self.player.play()
            self.state = "Playing"
            self.PlaybackStateChanged(self.state)
            print("Playback started")
    
    @dbus.service.method(INTERFACE_NAME, in_signature='', out_signature='')
    def Pause(self):
        """Pause playback"""
        if self.player:
            self.player.pause()
            self.state = "Paused"
            self.PlaybackStateChanged(self.state)
            print("Playback paused")
    
    @dbus.service.method(INTERFACE_NAME, in_signature='', out_signature='')
    def Stop(self):
        """Stop playback"""
        if self.player:
            self.player.stop()
            self.state = "Stopped"
            self.position = 0
            self.PlaybackStateChanged(self.state)
            self.PositionChanged(dbus.Int64(self.position))
            print("Playback stopped")
    
    @dbus.service.method(INTERFACE_NAME, in_signature='x', out_signature='')
    def Seek(self, position):
        """Seek to position"""
        if self.player and self.player.is_playing():
            self.player.set_time(int(position))
            self.position = position
            self.PositionChanged(dbus.Int64(self.position))
            print(f"Seeked to: {position}ms")
    
    @dbus.service.method(INTERFACE_NAME, in_signature='i', out_signature='')
    def SetVolume(self, volume):
        """Set volume"""
        self.volume = max(0, min(100, volume))
        if self.player:
            self.player.audio_set_volume(self.volume)
        print(f"Volume: {self.volume}")
    
    @dbus.service.method(INTERFACE_NAME, in_signature='', out_signature='')
    def Next(self):
        """Next track"""
        print("Next track")
    
    @dbus.service.method(INTERFACE_NAME, in_signature='', out_signature='')
    def Previous(self):
        """Previous track"""
        print("Previous track")
    
    @dbus.service.method(INTERFACE_NAME, in_signature='', out_signature='x')
    def GetPosition(self):
        """Get position"""
        if self.player and self.player.is_playing():
            self.position = self.player.get_time()
        return dbus.Int64(self.position)
    
    @dbus.service.method(INTERFACE_NAME, in_signature='', out_signature='x')
    def GetDuration(self):
        """Get duration"""
        if self.player:
            dur = self.player.get_length()
            if dur > 0:
                self.duration = dur
        return dbus.Int64(self.duration)
    
    # Signals
    @dbus.service.signal(INTERFACE_NAME, signature='s')
    def PlaybackStateChanged(self, state):
        pass
    
    @dbus.service.signal(INTERFACE_NAME, signature='x')
    def PositionChanged(self, position):
        pass
    
    @dbus.service.signal(INTERFACE_NAME, signature='x')
    def DurationChanged(self, duration):
        pass
    
    @dbus.service.signal(INTERFACE_NAME, signature='as')
    def UsbDevicesChanged(self, devices):
        pass
    
    @dbus.service.signal(INTERFACE_NAME, signature='as')
    def MediaFilesChanged(self, files):
        pass
    
    @dbus.service.signal(INTERFACE_NAME, signature='s')
    def CurrentDeviceChanged(self, device):
        pass
    
    @dbus.service.signal(INTERFACE_NAME, signature='s')
    def UsbDeviceInserted(self, device_path):
        pass
    
    @dbus.service.signal(INTERFACE_NAME, signature='s')
    def UsbDeviceRemoved(self, device_path):
        pass
    
    def _update_position(self):
        """Update position periodically"""
        if self.player and self.player.is_playing():
            new_pos = self.player.get_time()
            if new_pos != self.position:
                self.position = new_pos
                self.PositionChanged(dbus.Int64(self.position))
            
            new_dur = self.player.get_length()
            if new_dur > 0 and new_dur != self.duration:
                self.duration = new_dur
                self.DurationChanged(dbus.Int64(self.duration))
        
        return True


def main():
    """Main entry point"""
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    
    session_bus = dbus.SessionBus()
    
    if session_bus.name_has_owner(SERVICE_NAME):
        print(f"Service {SERVICE_NAME} already running")
        sys.exit(1)
    
    bus_name = dbus.service.BusName(SERVICE_NAME, bus=session_bus)
    service = MediaPlayerService(session_bus, OBJECT_PATH)
    
    print(f"MediaPlayer service registered: {SERVICE_NAME}")
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

