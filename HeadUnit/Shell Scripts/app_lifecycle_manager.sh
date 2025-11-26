#!/bin/sh

# HeadUnit Application Lifecycle Manager - POSIX shell compatible

set -e

APP_DIR="./applications"
LOG_DIR="./logs"
STATE_FILE="/tmp/headunit_app_states.json"

mkdir -p "$LOG_DIR"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    msg="[$(date '+%Y-%m-%d %H:%M:%S')] [LIFECYCLE] [INFO] $1"
    printf "${GREEN}%s${NC}\n" "$msg"
    printf "%s\n" "$msg" >> "$LOG_DIR/lifecycle.log"
}

log_warn() {
    msg="[$(date '+%Y-%m-%d %H:%M:%S')] [LIFECYCLE] [WARN] $1"
    printf "${YELLOW}%s${NC}\n" "$msg"
    printf "%s\n" "$msg" >> "$LOG_DIR/lifecycle.log"
}

log_error() {
    msg="[$(date '+%Y-%m-%d %H:%M:%S')] [LIFECYCLE] [ERROR] $1"
    printf "${RED}%s${NC}\n" "$msg"
    printf "%s\n" "$msg" >> "$LOG_DIR/lifecycle.log"
}

# Get app name by IVI ID
get_app_name() {
    case "$1" in
        1000) echo "HomePage" ;;
        1001) echo "GearSelector" ;;
        1002) echo "MediaPlayer" ;;
        1003) echo "ThemeColor" ;;
        1004) echo "Navigation" ;;
        1005) echo "Settings" ;;
        *) echo "Unknown" ;;
    esac
}

# Initialize D-Bus service
init_dbus_service() {
    log_info "Initializing D-Bus service..."
    
    dbus-send --session \
        --dest=org.freedesktop.DBus \
        --type=method_call \
        --print-reply \
        /org/freedesktop/DBus \
        org.freedesktop.DBus.RequestName \
        string:"com.headunit.AppLifecycle" \
        uint32:4 2>/dev/null || true
    
    log_info "D-Bus service registered: com.headunit.AppLifecycle"
}

# Launch application
launch_app() {
    ivi_id=$1
    app_name=$(get_app_name "$ivi_id")
    
    if [ "$app_name" = "Unknown" ]; then
        log_error "Unknown IVI-ID: $ivi_id"
        return 1
    fi
    
    app_path="$APP_DIR/$app_name"
    
    if [ ! -f "$app_path" ]; then
        log_error "Application not found: $app_path"
        return 1
    fi
    
    app_log="$LOG_DIR/${app_name}.log"
    app_err_log="$LOG_DIR/${app_name}.err.log"
    
    log_info "Launching $app_name (IVI-ID: $ivi_id)..."
    log_info "  Binary: $app_path"
    log_info "  Log: $app_log"
    
    # Launch with environment
    (
        QT_WAYLAND_SHELL_INTEGRATION=ivi-shell
        QT_IVI_SURFACE_ID=$ivi_id
        QT_QPA_PLATFORM=wayland
        WAYLAND_DISPLAY=wayland-1
        XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp}
        export QT_WAYLAND_SHELL_INTEGRATION QT_IVI_SURFACE_ID QT_QPA_PLATFORM WAYLAND_DISPLAY XDG_RUNTIME_DIR
        
        "$app_path" > "$app_log" 2> "$app_err_log"
    ) &
    
    pid=$!
    
    printf "========================================\n" >> "$app_log"
    printf "Application: %s\n" "$app_name" >> "$app_log"
    printf "IVI-ID: %s\n" "$ivi_id" >> "$app_log"
    printf "PID: %s\n" "$pid" >> "$app_log"
    printf "Started: %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" >> "$app_log"
    printf "========================================\n" >> "$app_log"
    
    log_info "$app_name launched with PID: $pid"
    
    sleep 1
    if kill -0 $pid 2>/dev/null; then
        log_info "$app_name running successfully"
    else
        log_error "$app_name failed to start"
    fi
    
    return 0
}

# D-Bus listener (simplified)
dbus_listener() {
    log_info "Starting D-Bus listener..."
    
    dbus-monitor --session \
        "type='method_call',interface='com.headunit.AppLifecycle'" 2>/dev/null | \
    while read -r line; do
        case "$line" in
            *LaunchApp*)
                read -r next_line
                ivi_id=$(echo "$next_line" | sed -n 's/.*int32 \([0-9]*\).*/\1/p')
                if [ -n "$ivi_id" ]; then
                    launch_app "$ivi_id" &
                fi
                ;;
        esac
    done
}

# Main
log_info "HeadUnit Application Lifecycle Manager"
log_info "======================================"
log_info "Log directory: $LOG_DIR"

init_dbus_service

dbus_listener &
DBUS_PID=$!

log_info "Lifecycle manager ready (PID: $$)"
log_info "D-Bus listener PID: $DBUS_PID"

trap "kill $DBUS_PID 2>/dev/null; exit" INT TERM
wait

