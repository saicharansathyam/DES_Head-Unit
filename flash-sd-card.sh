#!/bin/bash
# SD Card Flashing Script for HeadUnit Image
# Usage: sudo ./flash-sd-card.sh

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Project paths
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
IMAGE_DIR="${PROJECT_DIR}/yocto/build/tmp/deploy/images/raspberrypi4-64"
ROOTFS_IMAGE="${IMAGE_DIR}/headunit-image-raspberrypi4-64.rootfs.tar.bz2"
OVERLAYS_DIR="${IMAGE_DIR}/bootfiles/overlays"
SPI_OVERLAY_DIR="${PROJECT_DIR}/yocto/build/tmp/work/raspberrypi4_64-poky-linux/rpi-bootfiles/20250430/raspberrypi-firmware-bc7f439/boot/overlays"

# SD Card partitions
SD_DEVICE="/dev/sda"
BOOT_PARTITION="${SD_DEVICE}1"
ROOT_PARTITION="${SD_DEVICE}2"

# Mount points
BOOT_MOUNT="/media/${SUDO_USER}/boot2"
ROOT_MOUNT="/mnt"

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}HeadUnit SD Card Flashing Script${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Please run as root (use sudo)${NC}"
    exit 1
fi

# Check if image exists
if [ ! -f "${ROOTFS_IMAGE}" ]; then
    echo -e "${RED}Error: Image not found at ${ROOTFS_IMAGE}${NC}"
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
echo -e "${GREEN}[1/5] Unmounting partitions...${NC}"
umount ${BOOT_PARTITION} 2>/dev/null || true
umount ${ROOT_PARTITION} 2>/dev/null || true
umount ${BOOT_MOUNT} 2>/dev/null || true
umount ${ROOT_MOUNT} 2>/dev/null || true

echo -e "${GREEN}[2/5] Extracting rootfs to ${ROOT_PARTITION}...${NC}"
mount ${ROOT_PARTITION} ${ROOT_MOUNT}
tar -xjpf "${ROOTFS_IMAGE}" -C ${ROOT_MOUNT}
echo "Rootfs extracted successfully"
umount ${ROOT_MOUNT}

echo -e "${GREEN}[3/5] Mounting boot partition...${NC}"
mkdir -p ${BOOT_MOUNT}
mount ${BOOT_PARTITION} ${BOOT_MOUNT}

echo -e "${GREEN}[4/5] Copying boot files...${NC}"
# Copy bootloader files (bootcode.bin, start*.elf, fixup*.dat, config.txt, cmdline.txt)
for file in ${IMAGE_DIR}/bootfiles/*; do
    if [ -f "$file" ]; then
        cp -v "$file" ${BOOT_MOUNT}/
    fi
done
echo "  ✓ Bootloader files copied"

# Copy kernel image
if [ -f "${IMAGE_DIR}/Image" ]; then
    cp -v "${IMAGE_DIR}/Image" "${BOOT_MOUNT}/kernel8.img"
    echo "  ✓ Kernel copied as kernel8.img"
else
    echo -e "${RED}  ✗ Error: Kernel Image not found${NC}"
    umount ${BOOT_MOUNT}
    exit 1
fi

# Copy device tree files for Raspberry Pi 4
echo "  Copying device tree files..."
cp -v "${IMAGE_DIR}"/bcm2711-rpi-*.dtb ${BOOT_MOUNT}/ 2>/dev/null || echo -e "${YELLOW}  ⚠ Warning: Device tree files not found${NC}"

echo -e "${GREEN}[5/5] Copying device tree overlays...${NC}"
mkdir -p ${BOOT_MOUNT}/overlays

# Copy all standard overlays from bootfiles
if [ -d "${IMAGE_DIR}/bootfiles/overlays" ]; then
    echo "  Copying standard overlays..."
    cp -v "${IMAGE_DIR}/bootfiles/overlays"/*.dtbo ${BOOT_MOUNT}/overlays/ 2>/dev/null || true
    echo "  ✓ Standard overlays copied"
fi

# Copy custom CAN overlays
if [ -f "${OVERLAYS_DIR}/mcp251xfd-spi0-0.dtbo" ]; then
    cp "${OVERLAYS_DIR}/mcp251xfd-spi0-0.dtbo" "${BOOT_MOUNT}/overlays/"
    echo "  ✓ mcp251xfd-spi0-0.dtbo copied"
else
    echo -e "${YELLOW}  ⚠ Warning: mcp251xfd-spi0-0.dtbo not found${NC}"
fi

if [ -f "${OVERLAYS_DIR}/mcp251xfd-spi1-0.dtbo" ]; then
    cp "${OVERLAYS_DIR}/mcp251xfd-spi1-0.dtbo" "${BOOT_MOUNT}/overlays/"
    echo "  ✓ mcp251xfd-spi1-0.dtbo copied"
else
    echo -e "${YELLOW}  ⚠ Warning: mcp251xfd-spi1-0.dtbo not found${NC}"
fi

# Copy spi1-3cs overlay
if [ -f "${SPI_OVERLAY_DIR}/spi1-3cs.dtbo" ]; then
    cp "${SPI_OVERLAY_DIR}/spi1-3cs.dtbo" "${BOOT_MOUNT}/overlays/"
    echo "  ✓ spi1-3cs.dtbo copied"
else
    echo -e "${YELLOW}  ⚠ Warning: spi1-3cs.dtbo not found${NC}"
fi

echo ""
echo -e "${GREEN}[6/6] Verifying boot files...${NC}"
echo "Boot partition contents:"
ls -lh ${BOOT_MOUNT}/ | head -10
echo ""
echo "Overlays (CAN specific):"
ls -lh ${BOOT_MOUNT}/overlays/ | grep -E "(mcp251xfd|spi1-3cs)" || echo -e "${YELLOW}No CAN overlays found${NC}"

echo ""
echo -e "${GREEN}Syncing filesystems...${NC}"
sync

echo -e "${GREEN}Unmounting boot partition...${NC}"
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
echo "  • AFM managing gearselector, mediaplayer, themecolor"
echo ""
