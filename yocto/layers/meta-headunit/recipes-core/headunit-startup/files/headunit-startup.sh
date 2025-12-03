#!/bin/bash
# HeadUnit Auto-Startup Script
# Sets up environment and launches compositor + applications

set -e

LOG_FILE="/var/log/headunit-startup.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "======================================"
log "HeadUnit Startup Script"
log "======================================"

# Setup runtime directory
export XDG_RUNTIME_DIR=/run/user/0
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"
log "Created XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"

# Start D-Bus session bus if not running
if [ ! -S "$XDG_RUNTIME_DIR/bus" ]; then
    log "Starting D-Bus session bus..."
    dbus-daemon --session \
        --address=unix:path=$XDG_RUNTIME_DIR/bus \
        --nofork --nopidfile --syslog-only &
    sleep 2
    log "D-Bus session bus started"
else
    log "D-Bus session bus already running"
fi

# Export D-Bus environment
export DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR/bus

# Wait for mock services to be ready
log "Waiting for mock services..."
for i in {1..10}; do
    if systemctl is-active --quiet mock-theme && \
       systemctl is-active --quiet mock-dbus; then
        log "Mock services are ready"
        break
    fi
    sleep 1
done

# Qt/Wayland environment
export QT_QPA_PLATFORM=eglfs
export QT_QPA_EGLFS_PHYSICAL_WIDTH=154
export QT_QPA_EGLFS_PHYSICAL_HEIGHT=85
export QT_QPA_EGLFS_FORCE_888=1
export QT_QPA_EGLFS_SWAPINTERVAL=1
#export QT_QUICK_BACKEND=software
export LC_ALL=C.UTF-8

log "Environment configured"

# Start IVI Compositor
log "Starting IVI Compositor..."
/usr/bin/ivi-compositor > /var/log/ivi-compositor.log 2>&1 &
COMPOSITOR_PID=$!
log "IVI Compositor started (PID: $COMPOSITOR_PID)"

# Wait for Wayland socket
log "Waiting for Wayland socket..."
for i in {1..15}; do
    if [ -S "$XDG_RUNTIME_DIR/wayland-1" ]; then
        log "Wayland socket ready"
        break
    fi
    sleep 1
done

# Check if compositor is still running
if ! kill -0 $COMPOSITOR_PID 2>/dev/null; then
    log "ERROR: Compositor failed to start!"
    exit 1
fi

# Export Wayland environment for applications
export WAYLAND_DISPLAY=wayland-1
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_SHELL_INTEGRATION=ivi-shell
export QT_QUICK_BACKEND=software

# Wait for compositor to be fully ready
sleep 3

# Trigger AFM to launch initial applications
log "Triggering AFM to launch initial applications..."
if systemctl is-active --quiet afm; then
    # Use D-Bus to tell AFM to launch apps
    dbus-send --session --print-reply \
        --dest=com.headunit.AppLifecycle \
        /com/headunit/AppLifecycle \
        com.headunit.AppLifecycle.LaunchInitialApps || log "AFM launch trigger failed"
    log "AFM launch request sent"
else
    log "WARNING: AFM service not running!"
fi

log "======================================"
log "HeadUnit startup complete!"
log "======================================"
log "Compositor PID: $COMPOSITOR_PID"
log "Wayland Display: $WAYLAND_DISPLAY"
log "D-Bus Address: $DBUS_SESSION_BUS_ADDRESS"
log "======================================"

# Keep script running to maintain compositor
wait $COMPOSITOR_PID
