#!/bin/bash

# D-Bus interface helper for HeadUnit

DBUS_DEST="com.headunit.AppLifecycle"
DBUS_PATH="/com/headunit/AppLifecycle"
DBUS_INTERFACE="com.headunit.AppLifecycle"

# Check if service is running
check_service() {
    dbus-send --session --dest=$DBUS_DEST --print-reply $DBUS_PATH \
        org.freedesktop.DBus.Peer.Ping 2>/dev/null
    return $?
}

# Launch application
launch_app() {
    local ivi_id=$1
    dbus-send --session --dest=$DBUS_DEST --type=method_call \
        $DBUS_PATH $DBUS_INTERFACE.LaunchApp int32:$ivi_id
}

# Terminate application
terminate_app() {
    local ivi_id=$1
    dbus-send --session --dest=$DBUS_DEST --type=method_call \
        $DBUS_PATH $DBUS_INTERFACE.TerminateApp int32:$ivi_id
}

# Get application state
get_app_state() {
    local ivi_id=$1
    dbus-send --session --dest=$DBUS_DEST --print-reply \
        --type=method_call $DBUS_PATH $DBUS_INTERFACE.GetAppState int32:$ivi_id
}

# Monitor state changes
monitor_states() {
    echo "Monitoring HeadUnit application state changes..."
    echo "Press Ctrl+C to stop"
    echo ""
    
    dbus-monitor --session \
        "type='signal',interface='$DBUS_INTERFACE',member='StateChanged'"
}

# Main
case "${1:-}" in
    check)
        if check_service; then
            echo "Lifecycle manager is running"
            exit 0
        else
            echo "Lifecycle manager is NOT running"
            exit 1
        fi
        ;;
    launch)
        launch_app "$2"
        ;;
    terminate)
        terminate_app "$2"
        ;;
    state)
        get_app_state "$2"
        ;;
    monitor)
        monitor_states
        ;;
    *)
        echo "Usage: $0 {check|launch|terminate|state|monitor} [ivi_id]"
        exit 1
        ;;
esac
