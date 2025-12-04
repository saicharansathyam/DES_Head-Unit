#!/usr/bin/env python3
"""
Unified D-Bus Service for HeadUnit IVI System
Provides all interfaces with mock data, ready for hardware integration

Services:
- com.seame.Dashboard: Speed, battery, gear, theme, color, turn signals
- com.seame.MediaPlayer: Playback control, track info, volume
- com.seame.Settings: System settings (brightness, language)
- com.seame.ThemeColor: Theme and color management
- com.seame.GearSelector: Legacy gear selection interface

Hardware Integration (Next Session):
- CAN Bus: Speed (0x100), Gear (0x102), Turn signals (0x103)
- I2C INA219: Battery voltage monitoring
- Kalman Filter: Speed smoothing
- GamePad: Gear selection, turn signals, media control
- Arduino: Additional sensors and controls

Mode: Set HARDWARE_MODE=1 environment variable to enable hardware
"""

import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib
import sys
import random
import time
import os
import threading
import numpy as np

# ==================== Configuration ====================
HARDWARE_MODE = os.environ.get('HARDWARE_MODE', '0') == '1'

# Hardware imports (only if hardware mode)
if HARDWARE_MODE:
    try:
        import can
        import board
        import busio
        from adafruit_ina219 import INA219
    except ImportError as e:
        print(f"WARNING: Hardware libraries not available: {e}")
        HARDWARE_MODE = False

# Service definitions
DASHBOARD_SERVICE = "com.seame.Dashboard"
DASHBOARD_OBJECT = "/com/seame/Dashboard"

MEDIAPLAYER_SERVICE = "com.seame.MediaPlayer"
MEDIAPLAYER_OBJECT = "/com/seame/MediaPlayer"

SETTINGS_SERVICE = "com.seame.Settings"
SETTINGS_OBJECT = "/com/seame/Settings"

THEME_SERVICE = "com.seame.ThemeColor"
THEME_OBJECT = "/com/seame/ThemeColor"

GEARSELECTOR_SERVICE = "com.seame.GearSelector"
GEARSELECTOR_OBJECT = "/com/seame/GearSelector"

# Hardware constants (for future use)
CAN_SPEED_ID = 0x100
CAN_GEAR_ID = 0x102
CAN_TURN_ID = 0x103
INA219_ADDRESS = 0x40
MIN_VOLTAGE = 11.0
MAX_VOLTAGE = 12.6

# Kalman filter parameters
DT0 = 0.05
PROCESS_VAR = 4.0
MEAS_VAR = 3.0


# ==================== Kalman Filter ====================
class KalmanSpeedFilter:
    """2-state Kalman filter for speed smoothing (velocity, acceleration)"""
    def __init__(self, dt=DT0, process_var=PROCESS_VAR, meas_var=MEAS_VAR):
        self.x = np.zeros((2, 1))  # [velocity, acceleration]
        self.P = np.eye(2) * 100.0
        self.dt = dt

        self.F = np.array([[1, dt], [0, 1]])
        self.H = np.array([[1, 0]])
        self.R = np.array([[meas_var]])
        self.Q = np.array([[dt**4/4, dt**3/2], [dt**3/2, dt**2]]) * process_var

    def update(self, z, dt=None):
        """Update filter with new measurement z"""
        if dt is not None and abs(dt - self.dt) > 1e-3:
            self.dt = dt
            self.F = np.array([[1, dt], [0, 1]])
            self.Q = np.array([[dt**4/4, dt**3/2], [dt**3/2, dt**2]]) * PROCESS_VAR

        # Predict
        self.x = self.F @ self.x
        self.P = self.F @ self.P @ self.F.T + self.Q

        # Update
        y = np.array([[z]]) - self.H @ self.x
        S = self.H @ self.P @ self.H.T + self.R
        K = self.P @ self.H.T @ np.linalg.inv(S)
        self.x = self.x + K @ y
        self.P = (np.eye(2) - K @ self.H) @ self.P

        # Clamp to non-negative
        if self.x[0, 0] < 0.0:
            self.x[0, 0] = 0.0

        return float(self.x[0, 0])


# ==================== Dashboard Service ====================
class DashboardService(dbus.service.Object):
    """
    Dashboard service - instrument cluster data
    
    Hardware Integration Points:
    - Speed: CAN 0x100 (2 bytes, cm/s) + Kalman filter
    - Battery: INA219 I2C sensor (voltage)
    - Gear: CAN 0x102 (1 byte: P/R/N/D/S) or GamePad
    - Turn: CAN 0x103 (1 byte: 0=off,1=left,2=right,3=hazard) or GamePad
    """
    
    def __init__(self, bus, hardware_mode=False):
        bus_name = dbus.service.BusName(DASHBOARD_SERVICE, bus)
        super().__init__(bus_name, DASHBOARD_OBJECT)
        
        self.hardware_mode = hardware_mode
        self.speed = 0.0
        self.battery_voltage = 12.4
        self.battery_percent = 87.5
        self.current_gear = 'P'
        self.theme = "dark"
        self.accent_color = "#00ff00"
        self.turn_signal = "off"
        
        # Hardware integration
        self.can_bus = None
        self.ina219 = None
        self.kalman_filter = None
        self._last_speed_ts = None

        # Start hardware or mock mode
        if hardware_mode:
            self.init_hardware()
        else:
            GLib.timeout_add(100, self._simulate_speed)
            GLib.timeout_add(1000, self._simulate_battery)

        print(f"✓ Dashboard Service: {DASHBOARD_SERVICE}")
        print(f"  Mode: {'HARDWARE' if hardware_mode else 'MOCK'}")
    
    # ==================== Mock Simulation ====================
    def _simulate_speed(self):
        """Mock speed - will be replaced by CAN + Kalman filter"""
        self.speed = max(0, min(220, self.speed + random.uniform(-3, 3)))
        self.SpeedChanged(self.speed)
        return True
    
    def _simulate_battery(self):
        """Mock battery - will be replaced by INA219 sensor"""
        self.battery_voltage = round(11.5 + random.uniform(0, 1.0), 2)
        self.battery_percent = ((self.battery_voltage - MIN_VOLTAGE) / (MAX_VOLTAGE - MIN_VOLTAGE)) * 100
        self.battery_percent = max(0, min(100, self.battery_percent))
        self.BatteryVoltageChanged(self.battery_voltage)
        self.BatteryPercentChanged(self.battery_percent)
        return True
    
    # ==================== Hardware Integration ====================
    def init_hardware(self):
        """Initialize CAN bus, I2C sensors, Kalman filter"""
        print("[Hardware] Initializing...")

        # Initialize Kalman filter
        self.kalman_filter = KalmanSpeedFilter()
        print("  ✓ Kalman filter ready")

        # Initialize CAN bus
        can_iface = os.environ.get("CAN_IFACE", "can0")
        for iface in [can_iface, "can0", "can1"]:
            try:
                self.can_bus = can.interface.Bus(channel=iface, bustype='socketcan')
                print(f"  ✓ CAN connected ({iface})")
                break
            except Exception as e:
                print(f"  ✗ CAN {iface} failed: {e}")

        if not self.can_bus:
            print("  ✗ CAN initialization failed - no valid interface")
            return

        # Initialize INA219 battery sensor
        try:
            i2c_bus = busio.I2C(board.SCL, board.SDA)
            self.ina219 = INA219(i2c_bus, INA219_ADDRESS)
            print("  ✓ INA219 ready (0x40)")
        except Exception as e:
            print(f"  ✗ INA219 init failed: {e}")

        # Start hardware read threads
        threading.Thread(target=self._read_can_loop, daemon=True).start()
        threading.Thread(target=self._poll_battery_loop, daemon=True).start()
        print("[Hardware] All threads started")
    
    def update_speed_from_can(self, speed_cms):
        """Called when CAN 0x100 message received (2 bytes, cm/s)"""
        if abs(self.speed - speed_cms) > 0.1:
            self.speed = speed_cms
            self.SpeedChanged(self.speed)
    
    def update_battery_from_sensor(self, voltage):
        """Called when INA219 reading available"""
        if abs(self.battery_voltage - voltage) > 0.01:
            self.battery_voltage = voltage
            self.battery_percent = ((voltage - MIN_VOLTAGE) / (MAX_VOLTAGE - MIN_VOLTAGE)) * 100
            self.battery_percent = max(0, min(100, self.battery_percent))
            self.BatteryVoltageChanged(self.battery_voltage)
            self.BatteryPercentChanged(self.battery_percent)
    
    def update_gear_from_can(self, gear_char):
        """Called when CAN 0x102 message received (1 byte: P/R/N/D/S)"""
        if gear_char != self.current_gear:
            self.current_gear = gear_char
            self.GearChanged(gear_char)
    
    def update_turn_from_can(self, turn_mode):
        """Called when CAN 0x103 message received (0=off,1=left,2=right,3=hazard)"""
        if turn_mode != self.turn_signal:
            self.turn_signal = turn_mode
            self.TurnSignalChanged(turn_mode)
    
    def send_to_can(self, msg_id, data):
        """Send message to CAN bus (if hardware mode)"""
        if self.can_bus:
            try:
                msg = can.Message(arbitration_id=msg_id, data=data, is_extended_id=False)
                self.can_bus.send(msg)
            except Exception as e:
                print(f"CAN send error: {e}")

    def _read_can_loop(self):
        """Background thread to read CAN messages"""
        print("[CAN] Listening for 0x100 (speed), 0x102 (gear), 0x103 (turn)")
        while True:
            try:
                message = self.can_bus.recv(timeout=1.0)
                now = time.monotonic()
                if message:
                    self._process_can_message(message, now)
            except Exception as e:
                print(f"CAN read error: {e}")
                time.sleep(1)

    def _process_can_message(self, message, now_ts):
        """Process incoming CAN message"""
        try:
            msg_id = message.arbitration_id
            data = message.data

            if msg_id == CAN_SPEED_ID and len(data) >= 2:
                # Speed from Arduino (big-endian, cm/s)
                speed_raw = (data[0] << 8) | data[1]
                meas_cms = float(speed_raw)

                # Calculate dt for Kalman filter
                dt = None
                if self._last_speed_ts is not None:
                    dt = now_ts - self._last_speed_ts
                self._last_speed_ts = now_ts

                # Apply Kalman filtering
                filt_cms = self.kalman_filter.update(meas_cms, dt=dt)

                # Update speed
                if abs(self.speed - filt_cms) > 0.1:
                    self.speed = filt_cms
                    GLib.idle_add(self.SpeedChanged, float(filt_cms))

            elif msg_id == CAN_GEAR_ID and len(data) >= 1:
                # Gear from CAN
                gear_char = chr(data[0]) if data[0] != 0 else 'P'
                if self.current_gear != gear_char:
                    self.current_gear = gear_char
                    GLib.idle_add(self.GearChanged, gear_char)

            elif msg_id == CAN_TURN_ID and len(data) >= 1:
                # Turn signal from CAN
                turn_map = {0: 'off', 1: 'left', 2: 'right', 3: 'hazard'}
                turn_mode = turn_map.get(data[0], 'off')
                if self.turn_signal != turn_mode:
                    self.turn_signal = turn_mode
                    GLib.idle_add(self.TurnSignalChanged, turn_mode)

        except Exception as e:
            print(f"CAN message processing error: {e}")

    def _poll_battery_loop(self):
        """Background thread to poll battery sensor"""
        while True:
            try:
                if self.ina219:
                    bus_voltage = self.ina219.bus_voltage
                    percent = (bus_voltage - MIN_VOLTAGE) / (MAX_VOLTAGE - MIN_VOLTAGE) * 100.0
                    percent = max(0.0, min(percent, 100.0))

                    if abs(self.battery_percent - percent) > 0.1:
                        self.battery_voltage = bus_voltage
                        self.battery_percent = percent
                        GLib.idle_add(self.BatteryVoltageChanged, bus_voltage)
                        GLib.idle_add(self.BatteryPercentChanged, percent)
                        GLib.idle_add(self.BatteryChanged, percent)
            except Exception as e:
                print(f"Battery read error: {e}")

            time.sleep(1)
    
    # ==================== D-Bus Methods ====================
    @dbus.service.method(DASHBOARD_SERVICE, out_signature='d')
    def GetSpeed(self):
        """Get current speed (cm/s)"""
        return float(self.speed)
    
    @dbus.service.method(DASHBOARD_SERVICE, out_signature='d')
    def GetBatteryVoltage(self):
        """Get battery voltage (V)"""
        return float(self.battery_voltage)
    
    @dbus.service.method(DASHBOARD_SERVICE, out_signature='d')
    def GetBatteryPercent(self):
        """Get battery percentage (0-100)"""
        return float(self.battery_percent)
    
    @dbus.service.method(DASHBOARD_SERVICE, out_signature='d')
    def GetBatteryLevel(self):
        """Alias for GetBatteryPercent (legacy compatibility)"""
        return float(self.battery_percent)
    
    @dbus.service.method(DASHBOARD_SERVICE, out_signature='s')
    def GetGear(self):
        """Get current gear (P/R/N/D/S)"""
        return str(self.current_gear)
    
    @dbus.service.method(DASHBOARD_SERVICE, in_signature='s', out_signature='')
    def SetGear(self, gear):
        """Set gear - can be called by UI or GamePad"""
        gear = str(gear).upper()
        if gear not in ('P', 'R', 'N', 'D', 'S'):
            raise dbus.DBusException('Invalid gear (use P/R/N/D/S)')
        
        if gear != self.current_gear:
            self.current_gear = gear
            self.GearChanged(gear)
            print(f"[Dashboard] Gear: {gear}")
            
            # Send to CAN if hardware mode
            if self.hardware_mode:
                self.send_to_can(CAN_GEAR_ID, [ord(gear[0])])
    
    @dbus.service.method(DASHBOARD_SERVICE, out_signature='s')
    def GetTheme(self):
        """Get current theme (dark/light)"""
        return str(self.theme)
    
    @dbus.service.method(DASHBOARD_SERVICE, in_signature='s', out_signature='')
    def SetTheme(self, theme):
        """Set theme (dark/light)"""
        if theme != self.theme:
            self.theme = theme
            self.ThemeChanged(theme)
            print(f"[Dashboard] Theme: {theme}")
    
    @dbus.service.method(DASHBOARD_SERVICE, out_signature='s')
    def GetAccentColor(self):
        """Get accent color (#RRGGBB)"""
        return str(self.accent_color)
    
    @dbus.service.method(DASHBOARD_SERVICE, in_signature='s', out_signature='')
    def SetAccentColor(self, color):
        """Set accent color (#RRGGBB)"""
        if color != self.accent_color:
            self.accent_color = color
            self.AccentColorChanged(color)
            print(f"[Dashboard] Color: {color}")
    
    @dbus.service.method(DASHBOARD_SERVICE, in_signature='s', out_signature='')
    def SetTurnSignal(self, mode):
        """Set turn signal (off/left/right/hazard)"""
        if mode not in ('off', 'left', 'right', 'hazard'):
            raise dbus.DBusException('Invalid turn signal mode')
        
        if mode != self.turn_signal:
            self.turn_signal = mode
            self.TurnSignalChanged(mode)
            print(f"[Dashboard] Turn: {mode}")
            
            # Send to CAN if hardware mode
            if self.hardware_mode:
                turn_map = {'off': 0, 'left': 1, 'right': 2, 'hazard': 3}
                self.send_to_can(CAN_TURN_ID, [turn_map[mode]])
    
    @dbus.service.method(DASHBOARD_SERVICE, out_signature='s')
    def GetTurnSignal(self):
        """Get turn signal state"""
        return str(self.turn_signal)
    
    # ==================== D-Bus Signals ====================
    @dbus.service.signal(DASHBOARD_SERVICE, signature='d')
    def SpeedChanged(self, speed):
        pass
    
    @dbus.service.signal(DASHBOARD_SERVICE, signature='d')
    def BatteryVoltageChanged(self, voltage):
        pass
    
    @dbus.service.signal(DASHBOARD_SERVICE, signature='d')
    def BatteryPercentChanged(self, percent):
        pass
    
    @dbus.service.signal(DASHBOARD_SERVICE, signature='d')
    def BatteryChanged(self, percent):
        """Alias for BatteryPercentChanged (legacy compatibility)"""
        pass
    
    @dbus.service.signal(DASHBOARD_SERVICE, signature='s')
    def GearChanged(self, gear):
        pass
    
    @dbus.service.signal(DASHBOARD_SERVICE, signature='s')
    def ThemeChanged(self, theme):
        pass
    
    @dbus.service.signal(DASHBOARD_SERVICE, signature='s')
    def AccentColorChanged(self, color):
        pass
    
    @dbus.service.signal(DASHBOARD_SERVICE, signature='s')
    def TurnSignalChanged(self, mode):
        pass


# ==================== MediaPlayer Service ====================
class MediaPlayerService(dbus.service.Object):
    """
    MediaPlayer service - playback control
    
    Hardware Integration Points:
    - GamePad buttons: Play/Pause, Next/Prev, Volume
    - Steering wheel controls: (if available via CAN)
    """
    
    def __init__(self, bus):
        bus_name = dbus.service.BusName(MEDIAPLAYER_SERVICE, bus)
        super().__init__(bus_name, MEDIAPLAYER_OBJECT)
        
        self.playing = False
        self.current_track = "No Track"
        self.current_source = "USB"
        self.volume = 50
        self.position = 0
        self.duration = 0
        
        print(f"✓ MediaPlayer Service: {MEDIAPLAYER_SERVICE}")
    
    @dbus.service.method(MEDIAPLAYER_SERVICE, out_signature='')
    def Play(self):
        self.playing = True
        self.PlaybackStateChanged(True)
        self.StateChanged("Playing")
        print("[MediaPlayer] Play")
    
    @dbus.service.method(MEDIAPLAYER_SERVICE, out_signature='')
    def play(self):
        """Lowercase alias for compatibility"""
        self.Play()
    
    @dbus.service.method(MEDIAPLAYER_SERVICE, out_signature='')
    def Pause(self):
        self.playing = False
        self.PlaybackStateChanged(False)
        self.StateChanged("Paused")
        print("[MediaPlayer] Pause")
    
    @dbus.service.method(MEDIAPLAYER_SERVICE, out_signature='')
    def pause(self):
        """Lowercase alias for compatibility"""
        self.Pause()
    
    @dbus.service.method(MEDIAPLAYER_SERVICE, out_signature='')
    def Stop(self):
        self.playing = False
        self.position = 0
        self.PlaybackStateChanged(False)
        self.StateChanged("Stopped")
        print("[MediaPlayer] Stop")
    
    @dbus.service.method(MEDIAPLAYER_SERVICE, out_signature='')
    def stop(self):
        """Lowercase alias for compatibility"""
        self.Stop()
    
    @dbus.service.method(MEDIAPLAYER_SERVICE, out_signature='')
    def Next(self):
        print("[MediaPlayer] Next track")
        self.TrackChanged("Next Track")
    
    @dbus.service.method(MEDIAPLAYER_SERVICE, out_signature='')
    def next(self):
        """Lowercase alias for compatibility"""
        self.Next()
    
    @dbus.service.method(MEDIAPLAYER_SERVICE, out_signature='')
    def Previous(self):
        print("[MediaPlayer] Previous track")
        self.TrackChanged("Previous Track")
    
    @dbus.service.method(MEDIAPLAYER_SERVICE, out_signature='')
    def previous(self):
        """Lowercase alias for compatibility"""
        self.Previous()
    
    @dbus.service.method(MEDIAPLAYER_SERVICE, in_signature='s', out_signature='')
    def SetTrack(self, track):
        self.current_track = track
        self.TrackChanged(track)
        print(f"[MediaPlayer] Track: {track}")
    
    @dbus.service.method(MEDIAPLAYER_SERVICE, out_signature='s')
    def GetTrack(self):
        return self.current_track
    
    @dbus.service.method(MEDIAPLAYER_SERVICE, in_signature='i', out_signature='')
    def SetVolume(self, volume):
        self.volume = max(0, min(100, volume))
        self.VolumeChanged(self.volume)
        print(f"[MediaPlayer] Volume: {self.volume}")
    
    @dbus.service.method(MEDIAPLAYER_SERVICE, out_signature='i')
    def GetVolume(self):
        return self.volume
    
    @dbus.service.method(MEDIAPLAYER_SERVICE, out_signature='b')
    def IsPlaying(self):
        return self.playing
    
    @dbus.service.method(MEDIAPLAYER_SERVICE, out_signature='b')
    def is_playing(self):
        """Lowercase alias for compatibility"""
        return self.playing
    
    @dbus.service.signal(MEDIAPLAYER_SERVICE, signature='b')
    def PlaybackStateChanged(self, playing):
        pass
    
    @dbus.service.signal(MEDIAPLAYER_SERVICE, signature='s')
    def StateChanged(self, state):
        """State: Playing/Paused/Stopped"""
        pass
    
    @dbus.service.signal(MEDIAPLAYER_SERVICE, signature='s')
    def TrackChanged(self, track):
        pass
    
    @dbus.service.signal(MEDIAPLAYER_SERVICE, signature='i')
    def VolumeChanged(self, volume):
        pass


# ==================== Settings Service ====================
class SettingsService(dbus.service.Object):
    """Settings service - system configuration"""
    
    def __init__(self, bus):
        bus_name = dbus.service.BusName(SETTINGS_SERVICE, bus)
        super().__init__(bus_name, SETTINGS_OBJECT)
        
        self.brightness = 80
        self.language = "en_US"
        
        print(f"✓ Settings Service: {SETTINGS_SERVICE}")
    
    @dbus.service.method(SETTINGS_SERVICE, in_signature='i', out_signature='')
    def SetBrightness(self, brightness):
        self.brightness = max(0, min(100, brightness))
        self.BrightnessChanged(self.brightness)
        print(f"[Settings] Brightness: {self.brightness}")
    
    @dbus.service.method(SETTINGS_SERVICE, out_signature='i')
    def GetBrightness(self):
        return self.brightness
    
    @dbus.service.method(SETTINGS_SERVICE, in_signature='s', out_signature='')
    def SetLanguage(self, language):
        self.language = language
        self.LanguageChanged(language)
        print(f"[Settings] Language: {language}")
    
    @dbus.service.method(SETTINGS_SERVICE, out_signature='s')
    def GetLanguage(self):
        return self.language
    
    @dbus.service.signal(SETTINGS_SERVICE, signature='i')
    def BrightnessChanged(self, brightness):
        pass
    
    @dbus.service.signal(SETTINGS_SERVICE, signature='s')
    def LanguageChanged(self, language):
        pass


# ==================== ThemeColor Service ====================
class ThemeColorService(dbus.service.Object):
    """ThemeColor service - theme management"""
    
    def __init__(self, bus):
        bus_name = dbus.service.BusName(THEME_SERVICE, bus)
        super().__init__(bus_name, THEME_OBJECT)
        
        self.theme = "dark"
        self.accent_color = "#00ff00"
        
        print(f"✓ ThemeColor Service: {THEME_SERVICE}")
    
    @dbus.service.method(THEME_SERVICE, in_signature='s', out_signature='')
    def SetTheme(self, theme):
        self.theme = theme
        self.ThemeChanged(theme)
        print(f"[ThemeColor] Theme: {theme}")
    
    @dbus.service.method(THEME_SERVICE, out_signature='s')
    def GetTheme(self):
        return self.theme
    
    @dbus.service.method(THEME_SERVICE, in_signature='s', out_signature='')
    def SetAccentColor(self, color):
        self.accent_color = color
        self.AccentColorChanged(color)
        print(f"[ThemeColor] Color: {color}")
    
    @dbus.service.method(THEME_SERVICE, out_signature='s')
    def GetAccentColor(self):
        return self.accent_color
    
    @dbus.service.signal(THEME_SERVICE, signature='s')
    def ThemeChanged(self, theme):
        pass
    
    @dbus.service.signal(THEME_SERVICE, signature='s')
    def AccentColorChanged(self, color):
        pass


# ==================== GearSelector Service (Legacy) ====================
class GearSelectorService(dbus.service.Object):
    """Legacy GearSelector service for compatibility"""
    
    def __init__(self, bus, dashboard_service):
        bus_name = dbus.service.BusName(GEARSELECTOR_SERVICE, bus)
        super().__init__(bus_name, GEARSELECTOR_OBJECT)
        
        self.dashboard = dashboard_service
        
        print(f"✓ GearSelector Service: {GEARSELECTOR_SERVICE} (legacy)")
    
    @dbus.service.method(GEARSELECTOR_SERVICE, in_signature='s', out_signature='s')
    def select_gear(self, gear):
        """Legacy method - redirects to Dashboard"""
        gear = str(gear).upper()
        if gear not in ('P', 'R', 'N', 'D', 'S'):
            return f"Invalid gear: {gear}"
        
        self.dashboard.SetGear(gear)
        return f"Gear {gear} selected"
    
    @dbus.service.method(GEARSELECTOR_SERVICE, out_signature='s')
    def get_current_gear(self):
        """Legacy method - redirects to Dashboard"""
        return self.dashboard.GetGear()


# ==================== Main ====================
def main():
    """Start all D-Bus services"""
    print("=" * 70)
    print("  Unified D-Bus Service for HeadUnit IVI")
    print("=" * 70)
    
    # Initialize D-Bus
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    
    try:
        bus = dbus.SystemBus()

    except Exception as e:
        print(f"ERROR: Could not connect to D-Bus session bus: {e}")
        print("Make sure dbus-session.service is running!")
        sys.exit(1)
    
    # Create all services
    try:
        dashboard = DashboardService(bus, hardware_mode=HARDWARE_MODE)
        mediaplayer = MediaPlayerService(bus)
        settings = SettingsService(bus)
        themecolor = ThemeColorService(bus)
        gearselector = GearSelectorService(bus, dashboard)
    except Exception as e:
        print(f"ERROR: Failed to create D-Bus services: {e}")
        sys.exit(1)
    
    print("=" * 70)
    print("  All services running. Hardware integration ready for next session.")
    print("  Press Ctrl+C to stop.")
    print("=" * 70)
    
    # Run main loop
    loop = GLib.MainLoop()
    try:
        loop.run()
    except KeyboardInterrupt:
        print("\nShutting down D-Bus services...")
        loop.quit()
        sys.exit(0)


if __name__ == "__main__":
    main()