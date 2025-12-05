#!/usr/bin/env python3
import time
import dbus
import dbus.mainloop.glib
from gi.repository import GLib
import logging
import threading

from gamepads import ShanWanGamepad

try:
    from vehicles import PiRacerStandard
except ImportError:
    class PiRacerStandard:
        """Fallback stub when the hardware vehicles module is unavailable."""
        def __init__(self):
            self._warned = False
            logging.warning("vehicles module not found; PiRacer controls are disabled.")

        def _log_disabled(self, action: str, value: float) -> None:
            if not self._warned:
                logging.warning("Ignoring %s=%.2f because no vehicles backend is available.", action, value)
                self._warned = True

        def set_throttle_percent(self, value: float) -> None:
            self._log_disabled("throttle", value)

        def set_steering_percent(self, value: float) -> None:
            self._log_disabled("steering", value)


BUS_NAME   = 'com.seame.Dashboard'
OBJ_PATH   = '/com/seame/Dashboard'
IFACE_NAME = 'com.seame.Dashboard'

# Control settings
THROTTLE_MAX = 0.6


class RCController:
    def __init__(self):
        self.car = PiRacerStandard()
        self.drive_mode = "parking"  # parking, neutral, drive, reverse

        # D-Bus setup
        self.dashboard = None
        self.dbus_loop = None
        self.current_speed = 0.0
        self.current_batt = 0.0
        self.current_gear = 'P'
        self.turn_mode = "off"

        # Button state tracking for edge detection
        self.prev_l1 = False
        self.prev_r1 = False
        
        # Keep last known steering value
        self.last_steering = 0.0

        self.setup_dbus()
        self.gamepad = self._initialise_gamepad()

        self._last_print = 0

    def setup_dbus(self):
        dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
        bus = dbus.SystemBus()
        try:
            obj = bus.get_object(BUS_NAME, OBJ_PATH, introspect=False)
            self.dashboard = dbus.Interface(obj, IFACE_NAME)

            # Subscribe to signals
            bus.add_signal_receiver(self.on_speed,   dbus_interface=IFACE_NAME, signal_name='SpeedChanged')
            bus.add_signal_receiver(self.on_battery, dbus_interface=IFACE_NAME, signal_name='BatteryChanged')
            bus.add_signal_receiver(self.on_gear,    dbus_interface=IFACE_NAME, signal_name='GearChanged')

            # Start GLib loop in thread
            self.dbus_loop = GLib.MainLoop()
            threading.Thread(target=self.dbus_loop.run, daemon=True).start()
        except Exception as e:
            logging.warning(f"D-Bus dashboard not available: {e}")

    def on_speed(self, v):
        self.current_speed = max(0.0, float(v))

    def on_battery(self, p):
        self.current_batt = max(0.0, min(100.0, float(p)))

    def on_gear(self, g):
        """Handle gear changes from D-Bus (e.g., from Instrument Cluster UI)"""
        self.current_gear = str(g)
        # Update internal drive_mode to match external gear change
        gear_to_mode = {"P": "parking", "N": "neutral", "D": "drive", "R": "reverse"}
        self.drive_mode = gear_to_mode.get(self.current_gear, "parking")

    def _initialise_gamepad(self) -> ShanWanGamepad:
        """Block until gamepad is available."""
        while True:
            try:
                gamepad = ShanWanGamepad()
                print("Gamepad initialized")
                return gamepad
            except FileNotFoundError:
                print("Waiting for gamepad (/dev/input/js0)")
                time.sleep(2.0)
            except Exception as exc:
                logging.warning(f"Failed to initialize gamepad: {exc}")
                time.sleep(2.0)

    def set_turn_signal(self, mode):
        if mode == self.turn_mode:
            return
        self.turn_mode = mode
        if self.dashboard:
            try:
                self.dashboard.SetTurnSignal(mode, timeout=0.3)
                print(f"Turn signal set to: {mode}")
            except Exception as e:
                logging.warning(f"SetTurnSignal failed: {e}")

    def update_gear(self, new_gear):
        if new_gear != self.current_gear:
            self.current_gear = new_gear
            self.car.set_throttle_percent(0.0)  # Safety: stop when changing gear
            if self.dashboard:
                try:
                    self.dashboard.SetGear(new_gear, timeout=0.3)
                except Exception as e:
                    logging.warning(f"SetGear failed: {e}")

    def run(self):
        print(f"Starting RC with {THROTTLE_MAX*100:.0f}% throttle limit")

        try:
            while True:
                try:
                    pad_state = self.gamepad.read_data()
                except Exception as exc:
                    logging.warning(f"Gamepad read failed ({exc}); retrying")
                    time.sleep(1.0)
                    self.gamepad = self._initialise_gamepad()
                    continue

                # 1. Steering control (left analog stick X-axis)
                # Keep the last value if no new value is provided
                if pad_state.analog_stick_left.x is not None:
                    self.last_steering = pad_state.analog_stick_left.x
                
                # Always apply the current steering value
                self.car.set_steering_percent(self.last_steering)

                # 2. Gear selection via buttons (only update when button is pressed)
                gear_changed = False
                if pad_state.button_x:      # X = Parking
                    if self.drive_mode != "parking":
                        self.drive_mode = "parking"
                        gear_changed = True
                elif pad_state.button_a:    # A = Drive
                    if self.drive_mode != "drive":
                        self.drive_mode = "drive"
                        gear_changed = True
                elif pad_state.button_y:    # Y = Reverse
                    if self.drive_mode != "reverse":
                        self.drive_mode = "reverse"
                        gear_changed = True
                elif pad_state.button_b:    # B = Neutral
                    if self.drive_mode != "neutral":
                        self.drive_mode = "neutral"
                        gear_changed = True

                # Only update gear on D-Bus if button was pressed and gear changed
                if gear_changed:
                    gear_map = {"parking": "P", "neutral": "N", "drive": "D", "reverse": "R"}
                    new_gear = gear_map.get(self.drive_mode, "P")
                    self.update_gear(new_gear)

                # 3. Turn signals (L1/R1 bumpers) - detect button press edges
                l1_pressed = pad_state.button_l1 == 1 if pad_state.button_l1 is not None else False
                r1_pressed = pad_state.button_r1 == 1 if pad_state.button_r1 is not None else False
                
                # Detect rising edge (button just pressed)
                l1_edge = l1_pressed and not self.prev_l1
                r1_edge = r1_pressed and not self.prev_r1
                
                if l1_edge and r1_pressed:
                    # Both pressed = hazard
                    self.set_turn_signal("hazard")
                elif r1_edge and l1_pressed:
                    # Both pressed = hazard
                    self.set_turn_signal("hazard")
                elif l1_edge:
                    # L1 pressed alone = toggle left
                    new_mode = "off" if self.turn_mode == "left" else "left"
                    self.set_turn_signal(new_mode)
                elif r1_edge:
                    # R1 pressed alone = toggle right
                    new_mode = "off" if self.turn_mode == "right" else "right"
                    self.set_turn_signal(new_mode)
                
                # Update previous button states
                self.prev_l1 = l1_pressed
                self.prev_r1 = r1_pressed

                # 4. Throttle control (right analog stick Y-axis)
                throttle_input = pad_state.analog_stick_right.y or 0.0

                if throttle_input < 0.0:
                    throttle_intensity = throttle_input * THROTTLE_MAX
                    stick_direction = "backward"
                elif throttle_input > 0.0:
                    throttle_intensity = throttle_input * THROTTLE_MAX
                    stick_direction = "forward"
                else:
                    throttle_intensity = 0.0
                    stick_direction = "neutral"

                # 5. Apply throttle based on gear and stick direction
                if self.drive_mode == "drive":
                    if stick_direction == "forward":
                        self.car.set_throttle_percent(throttle_intensity)
                    else:
                        self.car.set_throttle_percent(0.0)
                elif self.drive_mode == "reverse":
                    if stick_direction == "backward":
                        self.car.set_throttle_percent(-throttle_intensity)
                    else:
                        self.car.set_throttle_percent(0.0)
                elif self.drive_mode in ("neutral", "parking"):
                    self.car.set_throttle_percent(0.0)
                    if self.drive_mode == "parking":
                        self.car.set_steering_percent(0.0)

                # Print status every 0.3s
                if time.time() - self._last_print > 0.3:
                    print(f"[{self.current_gear}] T:{throttle_intensity:+.2f} S:{self.last_steering:+.2f} | "
                          f"Speed:{self.current_speed:5.1f} cm/s Batt:{self.current_batt:4.1f}% Turn:{self.turn_mode}")
                    self._last_print = time.time()

        except KeyboardInterrupt:
            print("\nProgram stopped by user")
        finally:
            print("Safe stop and reset")
            self.car.set_throttle_percent(0.0)
            self.car.set_steering_percent(0.0)
            self.set_turn_signal("off")


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(levelname)s:%(message)s")
    RCController().run()
