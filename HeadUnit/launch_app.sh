#!/bin/bash

# Enhanced application launcher for HeadUnit

if [ $# -lt 1 ]; then
    echo "Usage: $0 <app_name|ivi_id>"
    echo ""
    echo "Available applications:"
    echo "  HomePage       1000"
    echo "  GearSelector   1001"
    echo "  MediaPlayer    1002"
    echo "  ThemeColor     1003"
    echo "  Navigation     1004"
    echo "  YouTube        1005"
    echo ""
    echo "Examples:"
    echo "  $0 HomePage"
    echo "  $0 1000"
    echo "  $0 MediaPlayer"
    exit 1
fi

# Application mapping
declare -A APP_IDS
APP_IDS[HomePage]=1000
APP_IDS[GearSelector]=1001
APP_IDS[MediaPlayer]=1002
APP_IDS[ThemeColor]=1003
APP_IDS[Navigation]=1004
APP_IDS[YouTube]=1005

# Reverse mapping
declare -A APP_NAMES
APP_NAMES[1000]="HomePage"
APP_NAMES[1001]="GearSelector"
APP_NAMES[1002]="MediaPlayer"
APP_NAMES[1003]="ThemeColor"
APP_NAMES[1004]="Navigation"
APP_NAMES[1005]="YouTube"

INPUT="$1"
APP_DIR="./applications"

# Determine IVI-ID and app name
if [[ "$INPUT" =~ ^[0-9]+$ ]]; then
    IVI_ID="$INPUT"
    APP_NAME="${APP_NAMES[$IVI_ID]}"
else
    APP_NAME="$INPUT"
    IVI_ID="${APP_IDS[$APP_NAME]}"
fi

if [ -z "$IVI_ID" ] || [ -z "$APP_NAME" ]; then
    echo "Error: Unknown application '$INPUT'"
    exit 1
fi

APP_PATH="$APP_DIR/$APP_NAME"

if [ ! -f "$APP_PATH" ]; then
    echo "Error: Application binary not found: $APP_PATH"
    exit 1
fi

# Use D-Bus if lifecycle manager is running
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
    
    export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp}
    export QT_WAYLAND_SHELL_INTEGRATION=ivi-shell
    export QT_IVI_SURFACE_ID=$IVI_ID
    export QT_QPA_PLATFORM=wayland
    export WAYLAND_DISPLAY=wayland-1
    
    exec "$APP_PATH"
fi

