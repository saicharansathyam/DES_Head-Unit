#!/bin/bash
# WIC-based SD Card Flashing Script for HeadUnit Image
# Usage: sudo ./flash-wic.sh

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Project paths
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
IMAGE_DIR="${PROJECT_DIR}/yocto/build/tmp/deploy/images/raspberrypi4-64"
WIC_IMAGE="${IMAGE_DIR}/headunit-image-raspberrypi4-64.rootfs.wic.bz2"
CAN_OVERLAYS_DIR="${IMAGE_DIR}/can-overlays"
SPI_OVERLAY_DIR="${PROJECT_DIR}/yocto/build/tmp/work/raspberrypi4_64-poky-linux/rpi-bootfiles/20250430/raspberrypi-firmware-bc7f439/boot/overlays"

# SD Card device
SD_DEVICE="/dev/sda"

# Mount point for manual overlay copy
BOOT_MOUNT="/media/${SUDO_USER}/boot"

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}HeadUnit WIC Image Flash Script${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Please run as root (use sudo)${NC}"
    exit 1
fi

# Check if WIC image exists
if [ ! -f "${WIC_IMAGE}" ]; then
    echo -e "${RED}Error: WIC image not found at ${WIC_IMAGE}${NC}"
    echo "Please build the image first with: bitbake headunit-image"
    exit 1
fi

# Check if SD card is present
if [ ! -b "${SD_DEVICE}" ]; then
    echo -e "${RED}Error: SD card not found at ${SD_DEVICE}${NC}"
    echo "Please insert SD card and check device with: lsblk"
    exit 1
fi

# Show SD card info
echo -e "${YELLOW}SD Card Device: ${SD_DEVICE}${NC}"
lsblk ${SD_DEVICE}
echo ""

# Confirm before proceeding
read -p "This will ERASE all data on ${SD_DEVICE}. Continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}Aborted by user.${NC}"
    exit 0
fi

echo ""
echo -e "${GREEN}[1/3] Unmounting any existing partitions...${NC}"
umount ${SD_DEVICE}* 2>/dev/null || true

echo -e "${GREEN}[2/3] Flashing WIC image to SD card...${NC}"
echo "This may take several minutes..."
dd if="${WIC_IMAGE}" | bzip2 -dc | dd of=${SD_DEVICE} bs=4M status=progress conv=fsync
sync

echo ""
echo -e "${GREEN}[3/3] Copying CAN device tree overlays...${NC}"
# Wait for partitions to be recognized
sleep 2
partprobe ${SD_DEVICE} 2>/dev/null || true
sleep 1

# Mount boot partition
mkdir -p ${BOOT_MOUNT}
mount ${SD_DEVICE}1 ${BOOT_MOUNT} 2>/dev/null || mount ${SD_DEVICE}p1 ${BOOT_MOUNT}

# Ensure overlays directory exists
mkdir -p ${BOOT_MOUNT}/overlays

# Copy CAN overlays
if [ -f "${CAN_OVERLAYS_DIR}/mcp251xfd-spi0-0.dtbo" ]; then
    cp -v "${CAN_OVERLAYS_DIR}/mcp251xfd-spi0-0.dtbo" "${BOOT_MOUNT}/overlays/"
    echo "  ✓ mcp251xfd-spi0-0.dtbo copied"
else
    echo -e "${YELLOW}  ⚠ Warning: mcp251xfd-spi0-0.dtbo not found${NC}"
fi

if [ -f "${CAN_OVERLAYS_DIR}/mcp251xfd-spi1-0.dtbo" ]; then
    cp -v "${CAN_OVERLAYS_DIR}/mcp251xfd-spi1-0.dtbo" "${BOOT_MOUNT}/overlays/"
    echo "  ✓ mcp251xfd-spi1-0.dtbo copied"
else
    echo -e "${YELLOW}  ⚠ Warning: mcp251xfd-spi1-0.dtbo not found${NC}"
fi

# Copy spi1-3cs overlay
if [ -f "${SPI_OVERLAY_DIR}/spi1-3cs.dtbo" ]; then
    cp -v "${SPI_OVERLAY_DIR}/spi1-3cs.dtbo" "${BOOT_MOUNT}/overlays/"
    echo "  ✓ spi1-3cs.dtbo copied"
else
    echo -e "${YELLOW}  ⚠ Warning: spi1-3cs.dtbo not found${NC}"
fi

echo ""
echo "Verifying overlays:"
ls -lh ${BOOT_MOUNT}/overlays/ | grep -E "(mcp251xfd|spi1-3cs)" || echo -e "${YELLOW}No CAN overlays found${NC}"

echo ""
echo -e "${GREEN}Syncing filesystems...${NC}"
sync

echo -e "${GREEN}Unmounting...${NC}"
umount ${BOOT_MOUNT}

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}✓ SD Card flashing completed!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo "You can now:"
echo "  1. Safely remove the SD card"
echo "  2. Insert it into the Raspberry Pi"
echo "  3. Boot and enjoy!"
echo ""
echo -e "${YELLOW}Expected features:${NC}"
echo "  • CAN0 and CAN1 interfaces working"
echo "  • rc-piracer service enabled (gamepad control)"
echo "  • Boot animation on startup"
echo "  • Dual display support (1024x600 on both HDMI ports)"
echo ""
