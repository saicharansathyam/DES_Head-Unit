SUMMARY = "Instrument Cluster Application for Head Unit IVI"
DESCRIPTION = "Qt6-based instrument cluster displaying speed, battery, gear, and turn signals via D-Bus - Standalone on DSI display"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

DEPENDS = "qtbase qtdeclarative qtdeclarative-native qtwayland qt5compat"

SRC_URI = " \
    file://main.cpp \
    file://PiRacerBridge.cpp \
    file://PiRacerBridge.h \
    file://main.qml \
    file://qml.qrc \
    file://CMakeLists.txt \
    file://fonts/Orbitron-VariableFont_wght.ttf \
    file://images/background.png \
    file://images/battery_icon.png \
    file://images/needles.png \
    file://images/left_indicator.png \
    file://images/right_indicator.png \
    file://instrument-cluster.service \
"

S = "${WORKDIR}"

inherit qt6-cmake systemd

SYSTEMD_SERVICE:${PN} = "instrument-cluster.service"
SYSTEMD_AUTO_ENABLE = "enable"

EXTRA_OECMAKE += " \
    -DCMAKE_BUILD_TYPE=Release \
"

do_install:append() {
    # Install binary (CMake creates ClusterUI_0820)
    install -d ${D}${bindir}
    install -m 0755 ${B}/ClusterUI_0820 ${D}${bindir}/instrument-cluster
    
    # Install systemd service
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/instrument-cluster.service ${D}${systemd_system_unitdir}/
}

FILES:${PN} += " \
    ${bindir}/instrument-cluster \
    ${systemd_system_unitdir}/instrument-cluster.service \
"

RDEPENDS:${PN} += " \
    qtbase \
    qtdeclarative \
    qtwayland \
    qt5compat \
    qtdeclarative-qmlplugins \
    mock-dbus \
"
