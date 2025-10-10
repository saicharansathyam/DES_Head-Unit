SUMMARY = "IVI Compositor - Wayland Compositor for Head Unit"
LICENSE = "CLOSED"

DEPENDS = "qtbase qtdeclarative qtwayland qtwayland-native qtbase-native qtdeclarative-native wayland wayland-native"

SRC_URI = "git:///workspace/HeadUnit;protocol=file;branch=Working-compositor"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git/IVI_Compositor"

inherit cmake pkgconfig

EXTRA_OECMAKE += " \
    -DQT_HOST_PATH=${STAGING_DIR_NATIVE}${prefix} \
    -DQT_HOST_PATH_CMAKE_DIR=${STAGING_DIR_NATIVE}${libdir}/cmake \
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH \
"

FILES:${PN} += "${bindir}/*"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${B}/appIVI_Compositor ${D}${bindir}/
}