#!/bin/bash

# HeadUnit Application Lifecycle Manager
# Manages application states and launches apps via D-Bus

set -e

# Configuration
APP_DIR="./applications"
LOG_DIR="./logs"
STATE_FILE="/tmp/headunit_app_states.json"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Application definitions
declare -A APPS
APPS[1000]="HomePage"
APPS[1001]="GearSelector"
APPS[1002]="MediaPlayer"
APPS[1003]="ThemeColor"
APPS[1004]="Navigation"
APPS[1005]="YouTube"

# Application states
declare -A APP_STATES
declare -A APP_PIDS

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [LIFECYCLE] [INFO] $1"
    echo -e "${GREEN}${msg}${NC}"
    echo "$msg" >> "$LOG_DIR/lifecycle.log"
}

log_warn() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [LIFECYCLE] [WARN] $1"
    echo -e "${YELLOW}${msg}${NC}"
    echo "$msg" >> "$LOG_DIR/lifecycle.log"
}

log_error() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [LIFECYCLE] [ERROR] $1"
    echo -e "${RED}${msg}${NC}"
    echo "$msg" >> "$LOG_DIR/lifecycle.log"
}

# Initialize D-Bus service
init_dbus_service() {
    log_info "Initializing D-Bus service..."
    
    # Register D-Bus service
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

# Launch application with separate log file
launch_app() {
    local ivi_id=$1
    local app_name="${APPS[$ivi_id]}"
    
    if [ -z "$app_name" ]; then
        log_error "Unknown IVI-ID: $ivi_id"
        return 1
    fi
    
    # Check if already running
    if [ "${APP_STATES[$ivi_id]}" == "running" ]; then
        log_warn "$app_name already running"
        return 0
    fi
    
    local app_path="$APP_DIR/$app_name"
    
    if [ ! -f "$app_path" ]; then
        log_error "Application not found: $app_path"
        APP_STATES[$ivi_id]="not_found"
        return 1
    fi
    
    # Create application-specific log file
    local app_log="$LOG_DIR/${app_name}.log"
    local app_err_log="$LOG_DIR/${app_name}.err.log"
    
    log_info "Launching $app_name (IVI-ID: $ivi_id)..."
    log_info "  Binary: $app_path"
    log_info "  Log: $app_log"
    log_info "  Error log: $app_err_log"
    
    # Set environment and launch with logging
    (
        QT_WAYLAND_SHELL_INTEGRATION=ivi-shell \
        QT_IVI_SURFACE_ID=$ivi_id \
        QT_QPA_PLATFORM=wayland \
        WAYLAND_DISPLAY=wayland-1 \
        XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp} \
        $app_path > "$app_log" 2> "$app_err_log"
    ) &
    
    local pid=$!
    APP_PIDS[$ivi_id]=$pid
    APP_STATES[$ivi_id]="launching"
    
    log_info "$app_name launched with PID: $pid"
    
    # Add header to log file
    echo "========================================" >> "$app_log"
    echo "Application: $app_name" >> "$app_log"
    echo "IVI-ID: $ivi_id" >> "$app_log"
    echo "PID: $pid" >> "$app_log"
    echo "Started: $(date '+%Y-%m-%d %H:%M:%S')" >> "$app_log"
    echo "========================================" >> "$app_log"
    
    # Verify launch after delay
    sleep 1
    if kill -0 $pid 2>/dev/null; then
        APP_STATES[$ivi_id]="running"
        log_info "$app_name running successfully"
    else
        APP_STATES[$ivi_id]="crashed"
        log_error "$app_name failed to start"
        log_error "Check logs: $app_log and $app_err_log"
    fi
    
    save_state
    return 0
}

# Terminate application
terminate_app() {
    local ivi_id=$1
    local app_name="${APPS[$ivi_id]}"
    local pid="${APP_PIDS[$ivi_id]}"
    
    if [ -z "$pid" ]; then
        log_warn "$app_name not running"
        return 1
    fi
    
    log_info "Terminating $app_name (PID: $pid)..."
    
    # Add termination notice to log
    local app_log="$LOG_DIR/${app_name}.log"
    echo "========================================" >> "$app_log"
    echo "Terminated: $(date '+%Y-%m-%d %H:%M:%S')" >> "$app_log"
    echo "========================================" >> "$app_log"
    
    kill $pid 2>/dev/null || true
    sleep 1
    
    if kill -0 $pid 2>/dev/null; then
        log_warn "$app_name didn't terminate, forcing..."
        kill -9 $pid 2>/dev/null || true
    fi
    
    APP_STATES[$ivi_id]="stopped"
    unset APP_PIDS[$ivi_id]
    
    log_info "$app_name terminated"
    save_state
}

# Handle app connected event from compositor
handle_app_connected() {
    local ivi_id=$1
    local app_name="${APPS[$ivi_id]}"
    
    log_info "App connected: $app_name (IVI-ID: $ivi_id)"
    APP_STATES[$ivi_id]="running"
    save_state
    
    # Send notification
    notify_state_change $ivi_id "connected"
}

# Handle app disconnected event from compositor
handle_app_disconnected() {
    local ivi_id=$1
    local app_name="${APPS[$ivi_id]}"
    
    log_warn "App disconnected: $app_name (IVI-ID: $ivi_id)"
    
    local pid="${APP_PIDS[$ivi_id]}"
    if [ -n "$pid" ]; then
        if ! kill -0 $pid 2>/dev/null; then
            APP_STATES[$ivi_id]="crashed"
            log_error "$app_name crashed"
            
            # Log crash to app log file
            local app_log="$LOG_DIR/${app_name}.log"
            echo "========================================" >> "$app_log"
            echo "CRASHED: $(date '+%Y-%m-%d %H:%M:%S')" >> "$app_log"
            echo "========================================" >> "$app_log"
        else
            APP_STATES[$ivi_id]="stopped"
        fi
        unset APP_PIDS[$ivi_id]
    fi
    
    save_state
    notify_state_change $ivi_id "disconnected"
}

# Save state to file
save_state() {
    local json="{"
    local first=true
    
    for ivi_id in "${!APP_STATES[@]}"; do
        if [ "$first" = true ]; then
            first=false
        else
            json+=","
        fi
        json+="\"$ivi_id\":\"${APP_STATES[$ivi_id]}\""
    done
    
    json+="}"
    echo "$json" > "$STATE_FILE"
}

# Load state from file
load_state() {
    if [ -f "$STATE_FILE" ]; then
        log_info "Loading previous state..."
        while IFS=: read -r key value; do
            key=$(echo "$key" | tr -d '"{, ')
            value=$(echo "$value" | tr -d '"}')
            if [ -n "$key" ]; then
                APP_STATES[$key]="$value"
            fi
        done < "$STATE_FILE"
    fi
}

# Send D-Bus notification
notify_state_change() {
    local ivi_id=$1
    local event=$2
    
    dbus-send --session \
        --type=signal \
        /com/headunit/AppLifecycle \
        com.headunit.AppLifecycle.StateChanged \
        int32:$ivi_id \
        string:"$event" 2>/dev/null || true
}

# Monitor application processes
monitor_apps() {
    while true; do
        for ivi_id in "${!APP_PIDS[@]}"; do
            local pid="${APP_PIDS[$ivi_id]}"
            local app_name="${APPS[$ivi_id]}"
            
            if ! kill -0 $pid 2>/dev/null; then
                log_warn "$app_name process died (PID: $pid)"
                APP_STATES[$ivi_id]="crashed"
                unset APP_PIDS[$ivi_id]
                save_state
                notify_state_change $ivi_id "crashed"
                
                # Log to app log file
                local app_log="$LOG_DIR/${app_name}.log"
                echo "========================================" >> "$app_log"
                echo "Process died: $(date '+%Y-%m-%d %H:%M:%S')" >> "$app_log"
                echo "PID: $pid" >> "$app_log"
                echo "========================================" >> "$app_log"
            fi
        done
        
        sleep 5
    done
}

# Get application state
get_app_state() {
    local ivi_id=$1
    echo "${APP_STATES[$ivi_id]:-stopped}"
}

# List all applications
list_apps() {
    log_info "=== Application States ==="
    for ivi_id in $(echo "${!APPS[@]}" | tr ' ' '\n' | sort -n); do
        local app_name="${APPS[$ivi_id]}"
        local state="${APP_STATES[$ivi_id]:-stopped}"
        local pid="${APP_PIDS[$ivi_id]:-N/A}"
        local log_file="$LOG_DIR/${app_name}.log"
        
        printf "  %-15s (ID: %4d) - State: %-10s PID: %-6s Log: %s\n" \
            "$app_name" "$ivi_id" "$state" "$pid" "$log_file"
    done
    log_info "=========================="
}

# D-Bus listener
dbus_listener() {
    log_info "Starting D-Bus listener..."
    
    dbus-monitor --session \
        "type='method_call',interface='com.headunit.AppLifecycle'" 2>/dev/null | \
    while read -r line; do
        if [[ "$line" =~ LaunchApp ]]; then
            read -r next_line
            if [[ "$next_line" =~ int32\ ([0-9]+) ]]; then
                ivi_id="${BASH_REMATCH[1]}"
                launch_app $ivi_id &
            fi
        elif [[ "$line" =~ AppConnected ]]; then
            read -r next_line
            if [[ "$next_line" =~ int32\ ([0-9]+) ]]; then
                ivi_id="${BASH_REMATCH[1]}"
                handle_app_connected $ivi_id
            fi
        elif [[ "$line" =~ AppDisconnected ]]; then
            read -r next_line
            if [[ "$next_line" =~ int32\ ([0-9]+) ]]; then
                ivi_id="${BASH_REMATCH[1]}"
                handle_app_disconnected $ivi_id
            fi
        fi
    done
}

# Main function
main() {
    log_info "HeadUnit Application Lifecycle Manager"
    log_info "======================================"
    log_info "Log directory: $LOG_DIR"
    
    # Initialize D-Bus
    init_dbus_service
    
    # Load previous state
    load_state
    
    # Start monitoring
    monitor_apps &
    MONITOR_PID=$!
    
    # Start D-Bus listener
    dbus_listener &
    DBUS_PID=$!
    
    # List applications
    list_apps
    
    log_info "Lifecycle manager ready"
    
    # Wait for signals
    trap "kill $MONITOR_PID $DBUS_PID 2>/dev/null; exit" SIGINT SIGTERM
    wait
}

# Handle command line arguments
case "${1:-}" in
    launch)
        shift
        launch_app "$@"
        ;;
    terminate)
        shift
        terminate_app "$@"
        ;;
    status)
        load_state
        list_apps
        ;;
    *)
        main
        ;;
esac
