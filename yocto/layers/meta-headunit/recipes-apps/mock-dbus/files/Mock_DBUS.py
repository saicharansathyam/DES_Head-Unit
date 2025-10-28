#!/usr/bin/env python3
"""Mock PiRacer D-Bus Service"""

import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib
import time
import threading

IFACE = 'com.piracer.dashboard'
OBJ = '/com/piracer/dashboard'

class MockDashboardService(dbus.service.Object):
    def __init__(self):
        dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
        self.bus = dbus.SessionBus()
        bus_name = dbus.service.BusName(IFACE, bus=self.bus)
        super().__init__(bus_name, OBJ)
        
        self.current_speed = 0.0
        self.target_speed = 0.0
        self.battery_level = 75.0
        self.current_gear = 'P'
        self.current_color = "#007ACC"
        
        print(f"Mock Dashboard Service started")
        threading.Thread(target=self.simulate_data, daemon=True).start()
        
    def simulate_data(self):
        while True:
            if abs(self.current_speed - self.target_speed) > 0.5:
                diff = self.target_speed - self.current_speed
                self.current_speed += diff * 0.1
                GLib.idle_add(self._emit_speed, self.current_speed)
            
            if self.battery_level > 10 and self.current_gear == 'D':
                self.battery_level -= 0.01
                if int(self.battery_level * 10) % 10 == 0:
                    GLib.idle_add(self._emit_battery, self.battery_level)
            
            time.sleep(0.05)
    
    @dbus.service.method(IFACE, out_signature='d')
    def GetSpeed(self):
        return float(self.current_speed)
    
    @dbus.service.method(IFACE, out_signature='d')
    def GetBatteryLevel(self):
        return float(self.battery_level)
    
    @dbus.service.method(IFACE, out_signature='s')
    def GetGear(self):
        return str(self.current_gear)
    
    @dbus.service.method(IFACE, in_signature='s', out_signature='')
    def SetGear(self, gear):
        gear = str(gear).upper()
        if gear not in ('P', 'R', 'N', 'D'):
            return
        
        self.current_gear = gear
        print(f"[Gear] -> {gear}")
        
        if gear in ('P', 'N'):
            self.target_speed = 0
        elif gear == 'R':
            self.target_speed = 30
        elif gear == 'D':
            self.target_speed = 100
        
        GLib.idle_add(self._emit_gear, gear)
    
    @dbus.service.method(IFACE, out_signature='s')
    def GetColor(self):
        return self.current_color

    @dbus.service.method(IFACE, in_signature='s', out_signature='')
    def SetColor(self, color):
        if color and color.startswith('#'):
            self.current_color = color
            print(f"[Color] -> {color}")
            GLib.idle_add(self._emit_color, color)
    
    @dbus.service.signal(IFACE, signature='d')
    def SpeedChanged(self, speed): pass
    
    @dbus.service.signal(IFACE, signature='d')
    def BatteryChanged(self, level): pass
    
    @dbus.service.signal(IFACE, signature='s')
    def GearChanged(self, gear): pass
    
    @dbus.service.signal(IFACE, signature='s')
    def ColorChanged(self, color): pass
    
    def _emit_speed(self, speed):
        self.SpeedChanged(speed)
        return False
    
    def _emit_battery(self, level):
        self.BatteryChanged(level)
        return False
    
    def _emit_gear(self, gear):
        self.GearChanged(gear)
        return False
        
    def _emit_color(self, color):
        self.ColorChanged(color)
        return False

if __name__ == '__main__':
    import signal
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    
    service = MockDashboardService()
    GLib.MainLoop().run()
