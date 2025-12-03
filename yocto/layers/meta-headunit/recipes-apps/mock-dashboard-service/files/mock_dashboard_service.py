#!/usr/bin/env python3
"""
Mock D-Bus service for testing ClusterUI on macOS
Simulates PiRacer dashboard data without hardware
"""

import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib
import threading
import time
import math

IFACE = 'com.piracer.dashboard'
OBJ = '/com/piracer/dashboard'

class MockDashboardService(dbus.service.Object):
    def __init__(self):
        dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
        bus = dbus.SessionBus()
        bus_name = dbus.service.BusName(IFACE, bus=bus)
        super().__init__(bus_name, OBJ)
        
        self.current_speed = 0.0
        self.battery_level = 75.0
        self.current_gear = 'P'
        self.turn_mode = 'off'
        
        # Start simulation thread
        threading.Thread(target=self.simulate_data, daemon=True).start()
    
    # D-Bus Methods
    @dbus.service.method(IFACE, out_signature='d')
    def GetSpeed(self):
        return float(self.current_speed)
    
    @dbus.service.method(IFACE, out_signature='d')
    def GetBatteryLevel(self):
        return float(self.battery_level)
    
    @dbus.service.method(IFACE, out_signature='s')
    def GetGear(self):
        return str(self.current_gear)
    
    @dbus.service.method(IFACE, in_signature='s')
    def SetGear(self, gear):
        self.current_gear = str(gear).upper()
        self.GearChanged(self.current_gear)
        print(f"Gear changed to: {self.current_gear}")
    
    @dbus.service.method(IFACE, in_signature='s')
    def SetTurnSignal(self, mode):
        self.turn_mode = mode
        self.TurnSignalChanged(mode)
        print(f"Turn signal: {mode}")
    
    @dbus.service.method(IFACE, out_signature='s')
    def GetTurnSignal(self):
        return str(self.turn_mode)
    
    # D-Bus Signals
    @dbus.service.signal(IFACE, signature='d')
    def SpeedChanged(self, new_speed):
        pass
    
    @dbus.service.signal(IFACE, signature='d')
    def BatteryChanged(self, new_level):
        pass
    
    @dbus.service.signal(IFACE, signature='s')
    def GearChanged(self, new_gear):
        pass
    
    @dbus.service.signal(IFACE, signature='s')
    def TurnSignalChanged(self, mode):
        pass
    
    def simulate_data(self):
        """Simulate realistic vehicle data"""
        t = 0
        while True:
            # Simulate speed: sine wave 0-250 cm/s
            self.current_speed = max(0, 125 + 125 * math.sin(t * 0.1))
            self.SpeedChanged(self.current_speed)
            
            # Simulate battery drain slowly
            self.battery_level = max(10, 100 - (t * 0.01) % 90)
            self.BatteryChanged(self.battery_level)
            
            # Cycle through gears every 10 seconds
            gears = ['P', 'N', 'D', 'R']
            gear_idx = int(t / 10) % len(gears)
            if self.current_gear != gears[gear_idx]:
                self.current_gear = gears[gear_idx]
                self.GearChanged(self.current_gear)
            
            # Cycle turn signals every 5 seconds
            turns = ['off', 'left', 'right', 'hazard']
            turn_idx = int(t / 5) % len(turns)
            if self.turn_mode != turns[turn_idx]:
                self.turn_mode = turns[turn_idx]
                self.TurnSignalChanged(self.turn_mode)
            
            t += 0.1
            time.sleep(0.1)

if __name__ == '__main__':
    print("=" * 60)
    print("Mock Dashboard Service for ClusterUI Testing")
    print("=" * 60)
    print("\nSimulation Parameters:")
    print("  • Speed: 0-250 cm/s (sine wave)")
    print("  • Battery: 100% → 10% (cycling)")
    print("  • Gear: P → N → D → R (10s cycle)")
    print("  • Turn: off → left → right → hazard (5s cycle)")
    print("\nD-Bus Interface:")
    print(f"  • Interface: {IFACE}")
    print(f"  • Object Path: {OBJ}")
    print("\nPress Ctrl+C to stop\n")
    print("=" * 60)
    
    try:
        service = MockDashboardService()
        GLib.MainLoop().run()
    except KeyboardInterrupt:
        print("\n\nStopping mock service...")
