import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib

# Define MediaPlayer Service
class MediaPlayer(dbus.service.Object):
    def __init__(self, bus_name, object_path):
        dbus.service.Object.__init__(self, bus_name, object_path)
        self.playing = False
        print("[MediaPlayer] Service created.")

    @dbus.service.method('com.example.MediaPlayer', in_signature='', out_signature='s')
    def play(self):
        print("[MediaPlayer] Play method called.")
        self.playing = True
        return "Playing"

    @dbus.service.method('com.example.MediaPlayer', in_signature='', out_signature='s')
    def pause(self):
        print("[MediaPlayer] Pause method called.")
        self.playing = False
        return "Paused"

    @dbus.service.method('com.example.MediaPlayer', in_signature='', out_signature='s')
    def stop(self):
        print("[MediaPlayer] Stop method called.")
        self.playing = False
        return "Stopped"

    @dbus.service.method('com.example.MediaPlayer', in_signature='', out_signature='b')
    def is_playing(self):
        print("[MediaPlayer] Is playing method called.")
        return self.playing


# Define GearSelector Service
class GearSelector(dbus.service.Object):
    def __init__(self, bus_name, object_path):
        dbus.service.Object.__init__(self, bus_name, object_path)
        self.current_gear = "P"  # Default gear (Park)
        print("[GearSelector] Service created. Current gear:", self.current_gear)

    @dbus.service.method('com.example.GearSelector', in_signature='s', out_signature='s')
    def select_gear(self, gear):
        print(f"[GearSelector] select_gear method called with gear: {gear}")
        
        # Validate the gear selection
        valid_gears = ['P', 'R', 'N', 'D', 'S']
        if gear not in valid_gears:
            return f"Invalid gear selection: {gear}. Valid options are P, R, N, D, S."
        
        self.current_gear = gear
        print(f"[GearSelector] Gear changed to: {self.current_gear}")
        return f"Gear {self.current_gear} selected."

    @dbus.service.method('com.example.GearSelector', in_signature='', out_signature='s')
    def get_current_gear(self):
        print("[GearSelector] get_current_gear method called.")
        return self.current_gear

# Main Program
def main():
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)

    bus = dbus.SessionBus()
    
    # MediaPlayer service
    media_player_name = dbus.service.BusName('com.example.MediaPlayer', bus)
    media_player = MediaPlayer(media_player_name, '/com/example/MediaPlayer')

    # GearSelector service
    gear_selector_name = dbus.service.BusName('com.example.GearSelector', bus)
    gear_selector = GearSelector(gear_selector_name, '/com/example/GearSelector')

    # Run the main loop
    loop = GLib.MainLoop()
    try:
        print("[Main] Starting the D-Bus loop...")
        loop.run()
    except KeyboardInterrupt:
        print("[Main] Shutting down services...")
        loop.quit()

if __name__ == '__main__':
    main()

