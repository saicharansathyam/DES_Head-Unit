SUMMARY = "HeadUnit Qt6 package group"
DESCRIPTION = "Qt6 framework and modules for HeadUnit IVI applications"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

PACKAGE_ARCH = "${TUNE_PKGARCH}"
inherit packagegroup

RDEPENDS:${PN} = " \
    qtbase \
    qtbase-plugins \
    qtbase-tools \
    qtdeclarative \
    qtdeclarative-plugins \
    qtdeclarative-tools \
    qtdeclarative-qmlplugins \
    qtwayland \
    qtlocation \
    qtpositioning \
    qtwayland-plugins \
    qtmultimedia \
    qtmultimedia-plugins \
    qtmultimedia-qmlplugins \
    qtsvg \
    qtsvg-plugins \
    qtvirtualkeyboard \
    qtvirtualkeyboard-plugins \
    qtvirtualkeyboard-qmlplugins \
"
