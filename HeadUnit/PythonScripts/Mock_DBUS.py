#!/usr/bin/env python3
"""
Mock PiRacer dashboard service for testing HeadUnit on Ubuntu laptop
No hardware dependencies - generates fake data for testing
"""

import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib
import random
import math
import time
import threading

IFACE = 'com.piracer.dashboard'
OBJ = '/com/piracer/dashboard'

class MockDashboardService(dbus.service.Object):
    def __init__(self):
        dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
        self.bus = dbus.SessionBus()
        bus_name = dbus.service.BusName(
            IFACE, bus=self.bus,
            allow_replacement=True, replace_existing=True, do_not_queue=True
        )
        super().__init__(bus_name, OBJ)
        
        # State
        self.current_speed = 0.0
        self.target_speed = 0.0
        self.battery_level = 75.0
        self.current_gear = 'P'
        self.turn_mode = 'off'
        self.headunit_connected = False
        self.current_color = "#007ACC"  # default theme color
        
        print(f"✓ Mock Dashboard Service started at {IFACE}")
        print("  - No hardware required")
        print("  - Generating simulated data")
        print("  - Press 'h' for help\n")
        
        # Start simulation threads
        threading.Thread(target=self.simulate_data, daemon=True).start()
        threading.Thread(target=self.user_input_handler, daemon=True).start()
        threading.Thread(target=self.monitor_headunit, daemon=True).start()
        
    def simulate_data(self):
        """Simulate speed and battery changes"""
        while True:
            # Smooth speed changes towards target
            if abs(self.current_speed - self.target_speed) > 0.5:
                diff = self.target_speed - self.current_speed
                self.current_speed += diff * 0.1  # Smooth transition
                GLib.idle_add(self._emit_speed, self.current_speed)
            
            # Slowly drain battery (simulate usage)
            if self.battery_level > 10 and self.current_gear == 'D':
                self.battery_level -= 0.01
                if int(self.battery_level * 10) % 10 == 0:  # Update every 1%
                    GLib.idle_add(self._emit_battery, self.battery_level)
            
            time.sleep(0.05)
    
    def user_input_handler(self):
        """Handle keyboard input for testing"""
        import sys, tty, termios
        
        def getch():
            fd = sys.stdin.fileno()
            old_settings = termios.tcgetattr(fd)
            try:
                tty.setraw(sys.stdin.fileno())
                ch = sys.stdin.read(1)
            finally:
                termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
            return ch
        
        print("Controls:")
        print("  p/r/n/d - Change gear")
        print("  ←/→    - Turn signals")
        print("  h      - Hazard lights")
        print("  +/-    - Adjust speed")
        print("  b      - Toggle battery (75%/25%)")
        print("  q      - Quit\n")
        
        while True:
            try:
                key = getch().lower()
                
                if key == 'q':
                    print("\nShutting down...")
                    GLib.idle_add(lambda: GLib.MainLoop().quit())
                    break
                elif key in 'prnd':
                    self.SetGear(key.upper())
                elif key == '\x1b':  # ESC sequence for arrow keys
                    next1 = getch()
                    next2 = getch()
                    if next1 == '[':
                        if next2 == 'D':  # Left arrow
                            self.SetTurnSignal('left' if self.turn_mode != 'left' else 'off')
                        elif next2 == 'C':  # Right arrow
                            self.SetTurnSignal('right' if self.turn_mode != 'right' else 'off')
                elif key == 'h':
                    self.SetTurnSignal('hazard' if self.turn_mode != 'hazard' else 'off')
                elif key == '+' and self.current_gear == 'D':
                    self.target_speed = min(300, self.target_speed + 20)
                    print(f"Speed target: {self.target_speed:.0f} cm/s")
                elif key == '-':
                    self.target_speed = max(0, self.target_speed - 20)
                    print(f"Speed target: {self.target_speed:.0f} cm/s")
                elif key == 'b':
                    self.battery_level = 25.0 if self.battery_level > 50 else 75.0
                    GLib.idle_add(self._emit_battery, self.battery_level)
            except Exception as e:
                print(f"Input error: {e}")
                break
    
    def monitor_headunit(self):
        """Check for HeadUnit services"""
        while True:
            try:
                # Check if GearSelector or MediaPlayer services exist
                gear_exists = self.bus.name_has_owner('com.example.GearSelector')
                media_exists = self.bus.name_has_owner('com.example.MediaPlayer')
                
                connected = gear_exists or media_exists
                if connected != self.headunit_connected:
                    self.headunit_connected = connected
                    status = "connected" if connected else "disconnected"
                    print(f"[HeadUnit] {status}")
                    GLib.idle_add(lambda: self.HeadUnitConnected(connected))
            except:
                pass
            time.sleep(2)
    
    # ========== D-Bus Methods ==========
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
            raise dbus.DBusException('Invalid gear (use P/R/N/D)')
        
        old_gear = self.current_gear
        self.current_gear = gear
        print(f"[Gear] {old_gear} → {gear}")
        
        # Adjust speed based on gear
        if gear == 'P' or gear == 'N':
            self.target_speed = 0
        elif gear == 'R':
            self.target_speed = 30  # Slow reverse
        elif gear == 'D':
            self.target_speed = 100  # Normal forward
        
        GLib.idle_add(self._emit_gear, gear)
    
    @dbus.service.method(IFACE, in_signature='s', out_signature='')
    def SetTurnSignal(self, mode):
        if mode not in ('off', 'left', 'right', 'hazard'):
            raise dbus.DBusException('Invalid turn signal mode')
        
        if mode != self.turn_mode:
            self.turn_mode = mode
            print(f"[Turn] → {mode}")
            GLib.idle_add(lambda: self.TurnSignalChanged(mode))
    
    @dbus.service.method(IFACE, out_signature='s')
    def GetTurnSignal(self):
        return str(self.turn_mode)
    
    @dbus.service.method(IFACE, out_signature='b')
    def IsHeadUnitConnected(self):
        return self.headunit_connected
    
    @dbus.service.method(IFACE, in_signature='s', out_signature='')
    def SendMediaCommand(self, command):
        print(f"[Media] Command received: {command}")
        # In mock mode, just log the command
        return
        
    dbus.service.method(IFACE, out_signature='s')
    def GetColor(self):
        """Get the current theme color."""
        return self.current_color

    @dbus.service.method(IFACE, in_signature='s', out_signature='')
    def SetColor(self, color):
        """Set the theme color, expects hex string (#RRGGBB)."""
        # Minimal validation (can be extended)
        if not isinstance(color, str) or not color.startswith('#') or len(color) not in (7, 9):
            raise dbus.DBusException('Invalid color format, expected "#RRGGBB"')
        
        old_color = self.current_color
        if color != old_color:
            self.current_color = color
            print(f"[ThemeColor] {old_color} → {color}")
            GLib.idle_add(self._emit_color, color)
    
    # ========== D-Bus Signals ==========
    @dbus.service.signal(IFACE, signature='d')
    def SpeedChanged(self, speed): pass
    
    @dbus.service.signal(IFACE, signature='d')
    def BatteryChanged(self, level): pass
    
    @dbus.service.signal(IFACE, signature='s')
    def GearChanged(self, gear): pass
    
    @dbus.service.signal(IFACE, signature='s')
    def TurnSignalChanged(self, mode): pass
    
    @dbus.service.signal(IFACE, signature='b')
    def HeadUnitConnected(self, connected): pass
    
    @dbus.service.signal(IFACE, signature='s')
    def ColorChanged(self, color): pass
    
    # ========== Emit Helpers ==========
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
    signal.signal(signal.SIGINT, signal.SIG_DFL)  # Allow Ctrl+C
    
    try:
        service = MockDashboardService()
        print("Mock service running. Press Ctrl+C to exit.")
        GLib.MainLoop().run()
    except KeyboardInterrupt:
        print("\nShutdown complete.")
