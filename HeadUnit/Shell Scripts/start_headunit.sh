#!/bin/sh

# HeadUnit Startup Script - POSIX shell compatible

set -e

COMPOSITOR_BIN="./headUnit"
LIFECYCLE_SCRIPT="./app_lifecycle_manager.sh"
APP_DIR="./applications"
LOG_DIR="./logs"

# Colors (use printf instead of echo -e)
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    printf "${GREEN}[HEADUNIT]${NC} %s\n" "$1"
}

log_warn() {
    printf "${YELLOW}[HEADUNIT]${NC} %s\n" "$1"
}

log_error() {
    printf "${RED}[HEADUNIT]${NC} %s\n" "$1"
}

mkdir -p "$LOG_DIR"

cleanup() {
    log_info "Shutting down HeadUnit system..."
    
    # Kill all child processes
    if [ -n "$COMPOSITOR_PID" ]; then
        kill "$COMPOSITOR_PID" 2>/dev/null || true
    fi
    
    if [ -n "$LIFECYCLE_PID" ]; then
        kill "$LIFECYCLE_PID" 2>/dev/null || true
    fi
    
    # Clean up sockets
    rm -f "${XDG_RUNTIME_DIR:-/tmp}"/wayland-1* 2>/dev/null || true
    rm -f /tmp/headunit_app_states.json 2>/dev/null || true
    
    log_info "Shutdown complete"
    exit 0
}

trap cleanup INT TERM EXIT

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
XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp}
WAYLAND_DISPLAY=wayland-1
export XDG_RUNTIME_DIR WAYLAND_DISPLAY

mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

rm -f "$XDG_RUNTIME_DIR"/wayland-1*

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
"$COMPOSITOR_BIN" > "$LOG_DIR/compositor.log" 2>&1 &
COMPOSITOR_PID=$!

log_info "Compositor PID: $COMPOSITOR_PID"

# Wait for Wayland socket
log_info "Waiting for Wayland socket..."
MAX_WAIT=20
WAIT_COUNT=0

while [ ! -S "$XDG_RUNTIME_DIR/wayland-1" ]; do
    sleep 1
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
sh "$LIFECYCLE_SCRIPT" > "$LOG_DIR/lifecycle.log" 2>&1 &
LIFECYCLE_PID=$!

log_info "Lifecycle manager PID: $LIFECYCLE_PID"
sleep 2

# Launch initial applications - SILENCED
log_info "Launching initial applications..."

launch_silent() {
    app_name=$1
    log_info "  -> Launching $app_name..."
    sh ./launch_app.sh "$app_name" >/dev/null 2>&1 &
    sleep 1
}

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
log_info "Press Ctrl+C to stop"
log_info "========================================="

wait $COMPOSITOR_PID

