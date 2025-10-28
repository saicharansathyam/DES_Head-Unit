SUMMARY = "Minimal IVI Compositor for Touch Testing"
DESCRIPTION = "Wayland compositor with touch input support"
LICENSE = "CLOSED"

DEPENDS = "qtbase qtdeclarative qtwayland qtwayland-native wayland wayland-native"

SRC_URI = "file://main.cpp \
           file://CMakeLists.txt \
           file://Main.qml \
          "

S = "${WORKDIR}"

inherit qt6-cmake

EXTRA_OECMAKE += " \
    -DQT_QPA_PLATFORM=eglfs \
"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${B}/appIVI_Compositor ${D}${bindir}/
}

FILES:${PN} = "${bindir}/appIVI_Compositor"

RDEPENDS:${PN} += "qtbase qtdeclarative qtwayland wayland"
