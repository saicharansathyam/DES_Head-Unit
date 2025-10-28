SUMMARY = "Media Player Application"
DESCRIPTION = "Media player UI for the head unit"
LICENSE = "CLOSED"

# Qt6 dependencies:
# - qtbase (includes Qt6::DBus when built with dbus PACKAGECONFIG)
# - qtdeclarative (Qt Quick/QML for target)
# - qtdeclarative-native (Qt6QuickTools for build host)
# - qtwayland (Wayland protocol support)
# - qtmultimedia (Media playback)
DEPENDS = "qtbase qtdeclarative qtdeclarative-native qtwayland qtmultimedia"

SRC_URI = "file://main.cpp \
           file://mp_handler.cpp \
           file://mp_handler.h \
           file://CMakeLists.txt \
           file://Main.qml \
           file://Main_Test.qml \
          "

S = "${WORKDIR}"

inherit qt6-cmake

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${B}/MediaPlayer ${D}${bindir}/
}

FILES:${PN} = "${bindir}/MediaPlayer"

# Runtime dependencies
RDEPENDS:${PN} += "qtbase qtdeclarative qtwayland qtmultimedia"
