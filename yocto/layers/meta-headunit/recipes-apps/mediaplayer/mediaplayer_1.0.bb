SUMMARY = "MediaPlayer Qt6 Application"
LICENSE = "CLOSED"

DEPENDS = "qtbase qtdeclarative qtmultimedia qtbase-native qtdeclarative-native"

SRC_URI = "git:///workspace/HeadUnit;protocol=file;branch=Working-compositor"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git/MediaPlayer"

inherit cmake

EXTRA_OECMAKE += " \
    -DQT_HOST_PATH=${STAGING_DIR_NATIVE}${prefix} \
    -DQT_HOST_PATH_CMAKE_DIR=${STAGING_DIR_NATIVE}${libdir}/cmake \
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH \
"

FILES:${PN} += "${bindir}/*"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${B}/MediaPlayer ${D}${bindir}/
}