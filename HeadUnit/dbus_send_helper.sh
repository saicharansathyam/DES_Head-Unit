#!/bin/bash

# Helper script to send D-Bus commands from compositor

METHOD=$1
PARAM=$2

if [ -z "$METHOD" ] || [ -z "$PARAM" ]; then
    exit 1
fi

case "$METHOD" in
    LaunchApp)
        dbus-send --session \
            --dest=com.headunit.AppLifecycle \
            --type=method_call \
            /com/headunit/AppLifecycle \
            com.headunit.AppLifecycle.LaunchApp \
            int32:$PARAM 2>/dev/null &
        ;;
    AppConnected)
        dbus-send --session \
            --dest=com.headunit.AppLifecycle \
            --type=method_call \
            /com/headunit/AppLifecycle \
            com.headunit.AppLifecycle.AppConnected \
            int32:$PARAM 2>/dev/null &
        ;;
    AppDisconnected)
        dbus-send --session \
            --dest=com.headunit.AppLifecycle \
            --type=method_call \
            /com/headunit/AppLifecycle \
            com.headunit.AppLifecycle.AppDisconnected \
            int32:$PARAM 2>/dev/null &
        ;;
esac
