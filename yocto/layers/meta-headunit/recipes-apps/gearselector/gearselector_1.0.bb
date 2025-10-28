SUMMARY = "Minimal GearSelector Touch Test"
DESCRIPTION = "Touch input test application"
LICENSE = "CLOSED"

DEPENDS = "qtbase qtdeclarative qtdeclarative-native"
RDEPENDS:${PN} += "qtbase qtdeclarative qtwayland qtwayland-plugins"

SRC_URI = "file://main.cpp \
           file://CMakeLists.txt \
           file://Main_Test.qml \
          "

S = "${WORKDIR}"

inherit qt6-cmake

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${B}/GearSelector ${D}${bindir}/
}

FILES:${PN} = "${bindir}/GearSelector"
