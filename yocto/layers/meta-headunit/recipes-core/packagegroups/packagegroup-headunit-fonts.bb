SUMMARY = "HeadUnit fonts package group"
DESCRIPTION = "Font packages for HeadUnit IVI system"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit packagegroup

# Use custom dejavu fonts without problematic postinstall
RDEPENDS:${PN} = " \
    fontconfig \
    dejavu-fonts \
"
