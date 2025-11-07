#!/usr/bin/env python3
import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

class ThemeColorService(dbus.service.Object):
    def __init__(self):
        DBusGMainLoop(set_as_default=True)
        bus_name = dbus.service.BusName('com.headunit.ThemeService', 
                                       bus=dbus.SessionBus())
        dbus.service.Object.__init__(self, bus_name, '/com/headunit/ThemeService')
        self._color = "#3498db"  # Default blue color
        
    @dbus.service.method('com.headunit.ThemeService', 
                        in_signature='s', out_signature='')
    def SetColor(self, color):
        """Set the theme color and broadcast change"""
        self._color = color
        print(f"Color changed to: {color}")
        self.ColorChanged(color)
        
    @dbus.service.method('com.headunit.ThemeService', 
                        in_signature='', out_signature='s')
    def GetColor(self):
        """Get the current theme color"""
        print(f"GetColor called, returning: {self._color}")
        return self._color
        
    @dbus.service.signal('com.headunit.ThemeService', signature='s')
    def ColorChanged(self, color):
        """Signal emitted when color changes"""
        pass

if __name__ == '__main__':
    print("Starting Theme Color D-Bus Service...")
    service = ThemeColorService()
    loop = GLib.MainLoop()
    print("Service running on: com.headunit.ThemeService")
    print("Object path: /com/headunit/ThemeService")
    try:
        loop.run()
    except KeyboardInterrupt:
        print("\nService stopped")
        loop.quit()
