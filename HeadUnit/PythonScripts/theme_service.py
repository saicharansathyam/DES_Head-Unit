#!/usr/bin/env python3

import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib
import json
import os
from pathlib import Path

class ThemeColorService(dbus.service.Object):
    def __init__(self):
        DBusGMainLoop(set_as_default=True)
        bus_name = dbus.service.BusName('com.piracer.dashboard',
                                       bus=dbus.SessionBus())
        dbus.service.Object.__init__(self, bus_name, '/com/piracer/dashboard')
        
        # Setup config directory
        self.config_dir = Path.home() / '.config' / 'headunit'
        self.config_file = self.config_dir / 'theme_color.json'
        self.config_dir.mkdir(parents=True, exist_ok=True)
        
        # Load saved color or use default
        self._color = self.load_color()
        print(f"Initialized with color: {self._color}")
    
    def load_color(self):
        """Load saved color from config file"""
        if self.config_file.exists():
            try:
                with open(self.config_file, 'r') as f:
                    data = json.load(f)
                    color = data.get('color', '#3b82f6')
                    print(f"Loaded saved color: {color}")
                    return color
            except Exception as e:
                print(f"Error loading color: {e}")
                return '#3b82f6'
        return '#3b82f6'  # Default blue
    
    def save_color(self):
        """Save color to config file"""
        try:
            data = {'color': self._color}
            with open(self.config_file, 'w') as f:
                json.dump(data, f)
            print(f"Color saved to {self.config_file}")
        except Exception as e:
            print(f"Error saving color: {e}")
    
    @dbus.service.method('com.piracer.dashboard',
                        in_signature='s', out_signature='')
    def SetColor(self, color):
        """Set the theme color and broadcast change"""
        self._color = color
        print(f"Color changed to: {color}")
        self.save_color()  # Persist to disk
        self.ColorChanged(color)  # Broadcast to all apps
    
    @dbus.service.method('com.piracer.dashboard',
                        in_signature='', out_signature='s')
    def GetColor(self):
        """Get the current theme color"""
        return self._color
    
    @dbus.service.signal('com.piracer.dashboard', signature='s')
    def ColorChanged(self, color):
        """Signal emitted when color changes"""
        pass

if __name__ == '__main__':
    print("=" * 50)
    print("Starting Theme Color DBus Service...")
    print("Service: com.piracer.dashboard")
    print("Object: /com/piracer/dashboard")
    print("=" * 50)
    
    service = ThemeColorService()
    loop = GLib.MainLoop()
    
    print(f"Initial color: {service._color}")
    print("Service is ready!")
    
    try:
        loop.run()
    except KeyboardInterrupt:
        print("\nService stopped")
        loop.quit()

