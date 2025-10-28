#!/bin/sh

# Enhanced application launcher - POSIX compatible

if [ $# -lt 1 ]; then
    echo "Usage: $0 <app_name|ivi_id>"
    echo ""
    echo "Available applications:"
    echo "  HomePage       1000"
    echo "  GearSelector   1001"
    echo "  MediaPlayer    1002"
    echo "  ThemeColor     1003"
    echo "  Navigation     1004"
    echo "  Settings       1005"
    exit 1
fi

INPUT="$1"
APP_DIR="./applications"

# Determine IVI-ID and app name
case "$INPUT" in
    HomePage|1000)
        IVI_ID=1000
        APP_NAME="HomePage"
        ;;
    GearSelector|1001)
        IVI_ID=1001
        APP_NAME="GearSelector"
        ;;
    MediaPlayer|1002)
        IVI_ID=1002
        APP_NAME="MediaPlayer"
        ;;
    ThemeColor|1003)
        IVI_ID=1003
        APP_NAME="ThemeColor"
        ;;
    Navigation|1004)
        IVI_ID=1004
        APP_NAME="Navigation"
        ;;
    Settings|1005)
        IVI_ID=1005
        APP_NAME="Settings"
        ;;
    *)
        echo "Error: Unknown application '$INPUT'"
        exit 1
        ;;
esac

APP_PATH="$APP_DIR/$APP_NAME"

if [ ! -f "$APP_PATH" ]; then
    echo "Error: Application binary not found: $APP_PATH"
    exit 1
fi

# Check if lifecycle manager is running
if dbus-send --session --dest=com.headunit.AppLifecycle \
    --print-reply /com/headunit/AppLifecycle \
    org.freedesktop.DBus.Peer.Ping 2>/dev/null; then
    
    echo "Requesting launch via lifecycle manager..."
    dbus-send --session \
        --dest=com.headunit.AppLifecycle \
        --type=method_call \
        /com/headunit/AppLifecycle \
        com.headunit.AppLifecycle.LaunchApp \
        int32:$IVI_ID
else
    # Direct launch
    echo "Launching $APP_NAME directly (IVI-ID: $IVI_ID)..."
    
    XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp}
    QT_WAYLAND_SHELL_INTEGRATION=ivi-shell
    QT_IVI_SURFACE_ID=$IVI_ID
    QT_QPA_PLATFORM=wayland
    WAYLAND_DISPLAY=wayland-1
    export XDG_RUNTIME_DIR QT_WAYLAND_SHELL_INTEGRATION QT_IVI_SURFACE_ID QT_QPA_PLATFORM WAYLAND_DISPLAY
    
    exec "$APP_PATH"
fi

