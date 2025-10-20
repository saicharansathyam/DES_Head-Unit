#!/bin/bash

# HeadUnit Startup Script with Lifecycle Manager

set -e

COMPOSITOR_BIN="./headUnit"
LIFECYCLE_SCRIPT="./app_lifecycle_manager.sh"
APP_DIR="./applications"
LOG_DIR="./logs"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[HEADUNIT]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[HEADUNIT]${NC} $1"
}

log_error() {
    echo -e "${RED}[HEADUNIT]${NC} $1"
}

mkdir -p "$LOG_DIR"

cleanup() {
    log_info "Shutting down HeadUnit system..."
    
    pkill -P $$ 2>/dev/null || true
    
    [ ! -z "$LIFECYCLE_PID" ] && kill $LIFECYCLE_PID 2>/dev/null || true
    [ ! -z "$COMPOSITOR_PID" ] && kill $COMPOSITOR_PID 2>/dev/null || true
    
    rm -f ${XDG_RUNTIME_DIR:-/tmp}/wayland-1* 2>/dev/null || true
    rm -f /tmp/headunit_app_states.json 2>/dev/null || true
    
    log_info "Shutdown complete"
    exit 0
}

trap cleanup SIGINT SIGTERM EXIT

# Check binaries
if [ ! -f "$COMPOSITOR_BIN" ]; then
    log_error "Compositor not found: $COMPOSITOR_BIN"
    exit 1
fi

if [ ! -f "$LIFECYCLE_SCRIPT" ]; then
    log_error "Lifecycle manager not found: $LIFECYCLE_SCRIPT"
    exit 1
fi

# Setup environment
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp}
export WAYLAND_DISPLAY=wayland-1

mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

rm -f $XDG_RUNTIME_DIR/wayland-1*

log_info "XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"

# Detect platform
if [ -n "$DISPLAY" ]; then
    COMPOSITOR_PLATFORM="xcb"
    log_info "Using X11 platform"
else
    COMPOSITOR_PLATFORM="eglfs"
    log_info "Using direct framebuffer"
fi

# Start compositor
log_info "Starting compositor..."
QT_QPA_PLATFORM=$COMPOSITOR_PLATFORM \
XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR \
$COMPOSITOR_BIN > "$LOG_DIR/compositor.log" 2>&1 &
COMPOSITOR_PID=$!

log_info "Compositor PID: $COMPOSITOR_PID"

# Wait for Wayland socket
log_info "Waiting for Wayland socket..."
MAX_WAIT=20
WAIT_COUNT=0

while [ ! -S "$XDG_RUNTIME_DIR/wayland-1" ]; do
    sleep 0.5
    WAIT_COUNT=$((WAIT_COUNT + 1))
    
    if [ $WAIT_COUNT -gt $MAX_WAIT ]; then
        log_error "Timeout waiting for Wayland socket"
        cat "$LOG_DIR/compositor.log"
        exit 1
    fi
    
    if ! kill -0 $COMPOSITOR_PID 2>/dev/null; then
        log_error "Compositor crashed"
        cat "$LOG_DIR/compositor.log"
        exit 1
    fi
done

log_info "Wayland socket ready"
sleep 2

# Start lifecycle manager
log_info "Starting lifecycle manager..."
bash "$LIFECYCLE_SCRIPT" > "$LOG_DIR/lifecycle.log" 2>&1 &
LIFECYCLE_PID=$!

log_info "Lifecycle manager PID: $LIFECYCLE_PID"
sleep 2

# Launch initial applications - SILENCED
log_info "Launching initial applications..."

# Silent launch function
launch_silent() {
    local app_name=$1
    log_info "  → Launching $app_name..."
    ./launch_app.sh "$app_name" >/dev/null 2>&1 &
    sleep 0.5
}

# Launch apps silently
launch_silent HomePage
launch_silent GearSelector

log_info ""
log_info "========================================="
log_info "  HeadUnit System Running"
log_info "========================================="
log_info "Compositor PID:  $COMPOSITOR_PID"
log_info "Lifecycle PID:   $LIFECYCLE_PID"
log_info "Platform:        $COMPOSITOR_PLATFORM"
log_info "Logs:            $LOG_DIR/"
log_info ""
log_info "Launch apps with:"
log_info "  ./launch_app.sh <AppName>"
log_info ""
log_info "View logs with:"
log_info "  ./view_logs.sh tail <AppName>"
log_info ""
log_info "Monitor D-Bus:"
log_info "  ./dbus_interface.sh monitor"
log_info ""
log_info "Press Ctrl+C to stop"
log_info "========================================="

wait $COMPOSITOR_PID

