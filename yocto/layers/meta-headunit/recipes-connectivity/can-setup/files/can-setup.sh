#!/bin/sh
# CAN interface setup for MCP2515
# This script initializes both can0 and can1 interfaces at boot

# Configure can0 interface (500kbps to match Arduino)
if [ -d /sys/class/net/can0 ]; then
    echo "Setting up can0 interface..."
    ip link set can0 type can bitrate 500000
    ip link set can0 up
    echo "✓ can0 is up at 500kbps"
else
    echo "⚠ can0 interface not found"
fi

# Configure can1 interface (500kbps to match Arduino)
if [ -d /sys/class/net/can1 ]; then
    echo "Setting up can1 interface..."
    ip link set can1 type can bitrate 500000
    ip link set can1 up
    echo "✓ can1 is up at 500kbps"
else
    echo "⚠ can1 interface not found"
fi

# Check if at least one interface is available
if [ ! -d /sys/class/net/can0 ] && [ ! -d /sys/class/net/can1 ]; then
    echo "ERROR: No CAN interface found!"
    echo "Make sure MCP2515 device tree overlay is enabled in config.txt"
    exit 1
fi

echo "CAN setup complete"
