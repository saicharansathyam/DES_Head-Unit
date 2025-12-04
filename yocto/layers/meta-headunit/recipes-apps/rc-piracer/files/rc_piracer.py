#!/usr/bin/env python3
import time
import dbus
import dbus.mainloop.glib
from gi.repository import GLib
from piracer.vehicles import PiRacerStandard
from evdev import InputDevice, categorize, ecodes, list_devices

BUS_NAME   = 'com.piracer.dashboard'
OBJ_PATH   = '/com/piracer/dashboard'
IFACE_NAME = 'com.piracer.dashboard'

# Xbox/PS4 compatible button mappings
BTN_LB = ecodes.BTN_TL      # Left bumper
BTN_RB = ecodes.BTN_TR      # Right bumper

class RCExample:
    def __init__(self):
        self.piracer = PiRacerStandard()

        # Find gamepad device
        devices = [InputDevice(path) for path in list_devices()]
        gamepads = [dev for dev in devices if 'js' in dev.name.lower() or
                    'gamepad' in dev.name.lower() or 'controller' in dev.name.lower() or
                    'xbox' in dev.name.lower() or 'playstation' in dev.name.lower()]

        if not gamepads:
            raise Exception("No gamepad detected")

        self.gamepad = gamepads[0]
        self.gamepad.grab()  # Exclusive access
        print(f"Gamepad detected: {self.gamepad.name}")

        # Axis and button state tracking
        self.axis_values = {
            ecodes.ABS_X: 0,        # Left stick X (steering)
            ecodes.ABS_RZ: 0,       # Right trigger (throttle)
            ecodes.ABS_HAT0X: 0,    # D-pad X
            ecodes.ABS_HAT0Y: 0,    # D-pad Y
        }
        self.button_states = {}
        self.prev_buttons = {}
        self.turn_mode = "off"
        self.current_gear = 'P'

        # FIXED: Remove double smoothing - use raw values directly
        self.current_speed = 0.0    # Direct from D-Bus (Kalman filtered)
        self.current_batt = 0.0     # Direct from D-Bus

        # Throttle limiting
        self.max_throttle = 0.6    # 60% throttle limit

        self._last_print = 0
        self.dashboard = None
        self.dbus_loop = None
        self.setup_dbus()

    def setup_dbus(self):
        dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
        bus = dbus.SessionBus()
        obj = bus.get_object(BUS_NAME, OBJ_PATH, introspect=False)
        self.dashboard = dbus.Interface(obj, IFACE_NAME)

        # Subscribe to asynchronous updates
        bus.add_signal_receiver(self.on_speed,   dbus_interface=IFACE_NAME, signal_name='SpeedChanged')
        bus.add_signal_receiver(self.on_battery, dbus_interface=IFACE_NAME, signal_name='BatteryChanged')
        bus.add_signal_receiver(self.on_gear,    dbus_interface=IFACE_NAME, signal_name='GearChanged')

        # Spin a loop so signals are processed
        self.dbus_loop = GLib.MainLoop()
        import threading
        threading.Thread(target=self.dbus_loop.run, daemon=True).start()

    # --- Signal handlers (FIXED: No smoothing) ---
    def on_speed(self, v):
        self.current_speed = max(0.0, float(v))

    def on_battery(self, p):
        self.current_batt = max(0.0, min(100.0, float(p)))

    def on_gear(self, g):
        self.current_gear = str(g)

    def process_event(self, event):
        """Process a single gamepad event"""
        if event.type == ecodes.EV_ABS:
            if event.code in self.axis_values:
                self.axis_values[event.code] = event.value
        elif event.type == ecodes.EV_KEY:
            self.button_states[event.code] = event.value

    def read_axes(self):
        """Read current axis values and convert to game values"""
        # Steering: left stick X-axis, normalize to -1.0 to 1.0
        # Typical range is -32768 to 32767
        steering_raw = self.axis_values.get(ecodes.ABS_X, 0)
        steering = -steering_raw / 32768.0  # Invert and normalize

        # Throttle: right trigger (RT), normalize to 0.0 to 1.0
        # Typical range is 0 to 255 or 0 to 1023
        throttle_raw = self.axis_values.get(ecodes.ABS_RZ, 0)
        info = self.gamepad.absinfo(ecodes.ABS_RZ)
        throttle = abs(throttle_raw - info.min) / (info.max - info.min)

        # D-pad for gear selection
        hat_x = self.axis_values.get(ecodes.ABS_HAT0X, 0)
        hat_y = self.axis_values.get(ecodes.ABS_HAT0Y, 0)

        gear = None
        if   hat_y == -1: gear = 'D'  # Up
        elif hat_y ==  1: gear = 'R'  # Down
        elif hat_x == -1: gear = 'P'  # Left
        elif hat_x ==  1: gear = 'N'  # Right

        return steering, throttle, gear

    def read_button_edges(self):
        """Detect button press/release edges"""
        edges = {}
        for btn_code, cur_state in self.button_states.items():
            prev_state = self.prev_buttons.get(btn_code, 0)
            if cur_state != prev_state:
                edges[btn_code] = "down" if cur_state else "up"
            self.prev_buttons[btn_code] = cur_state
        return edges

    def set_turn_signal(self, mode):
        if mode == self.turn_mode: return
        self.turn_mode = mode
        try:
            self.dashboard.SetTurnSignal(mode, timeout=0.3)
        except Exception as e:
            print(f"SetTurnSignal failed: {e}")

    def update_turn_from_buttons(self, edges):
        lb_down = edges.get(BTN_LB) == "down"
        rb_down = edges.get(BTN_RB) == "down"
        lb_up   = edges.get(BTN_LB) == "up"
        rb_up   = edges.get(BTN_RB) == "up"

        if lb_down and rb_down:
            self.set_turn_signal("hazard")
            return
        if lb_up:
            self.set_turn_signal("off" if self.turn_mode == "left" else "left")
        if rb_up:
            self.set_turn_signal("off" if self.turn_mode == "right" else "right")

    def apply_gear_logic(self, t):
        if self.current_gear in ('P', 'N'): return 0.0
        if self.current_gear == 'R':
            return -abs(t * self.max_throttle) if abs(t) > 0.1 else 0.0
        if self.current_gear == 'D':
            limited_throttle = t * self.max_throttle
            if t > 0.9 and self.max_throttle < 1.0:
                print(f"DEBUG: Throttle limited - Input: {t:.3f} -> Output: {limited_throttle:.3f} ({self.max_throttle*100:.0f}%)")
            return limited_throttle if limited_throttle > 0.05 else 0.0
        return 0.0

    def run(self):
        print(f"Starting RC with {self.max_throttle*100:.0f}% throttle limit")
        try:
            for event in self.gamepad.read_loop():
                # Process event
                self.process_event(event)

                # Only act on sync events (end of event batch)
                if event.type != ecodes.EV_SYN:
                    continue

                steering, raw_t, gear = self.read_axes()

                # On gear change, tell the dashboard service
                if gear and gear != self.current_gear:
                    self.current_gear = gear
                    self.piracer.set_throttle_percent(0.0)  # jerk guard
                    try:
                        self.dashboard.SetGear(gear, timeout=0.3)
                    except Exception as e:
                        print(f"SetGear failed: {e}")

                throttle = self.apply_gear_logic(raw_t)
                edges = self.read_button_edges()
                if edges:
                    self.update_turn_from_buttons(edges)

                self.piracer.set_steering_percent(steering)
                self.piracer.set_throttle_percent(throttle)

                # print less frequently (every 0.3 s) with better formatting
                if time.time() - self._last_print > 0.3:
                    print(f"[{self.current_gear}] T:{throttle:+.2f} S:{steering:+.2f} | "
                          f"Speed:{self.current_speed:5.1f} cm/s Batt:{self.current_batt:4.1f}% Turn:{self.turn_mode}")
                    self._last_print = time.time()

        except KeyboardInterrupt:
            self.piracer.set_throttle_percent(0.0)
            self.piracer.set_steering_percent(0.0)
            self.set_turn_signal("off")
        finally:
            self.gamepad.ungrab()

if __name__ == "__main__":
    RCExample().run()
