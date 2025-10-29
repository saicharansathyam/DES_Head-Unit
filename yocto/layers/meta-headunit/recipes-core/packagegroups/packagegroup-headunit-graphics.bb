SUMMARY = "HeadUnit graphics stack package group"
DESCRIPTION = "Graphics libraries for HeadUnit IVI system with Wayland/Qt support"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit packagegroup

RDEPENDS:${PN} = " \
    mesa \
    libdrm \
    libgbm \
    wayland \
    wayland-protocols \
    libegl \
    libgles2 \
"
