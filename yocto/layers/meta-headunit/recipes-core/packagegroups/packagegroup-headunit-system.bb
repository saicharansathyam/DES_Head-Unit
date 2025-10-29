SUMMARY = "HeadUnit system utilities package group"
DESCRIPTION = "Core system utilities for HeadUnit IVI system"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit packagegroup

RDEPENDS:${PN} = " \
    systemd \
    dbus \
    udev \
    util-linux \
    coreutils \
    busybox \
    procps \
    net-tools \
    iproute2 \
    tzdata \
"
