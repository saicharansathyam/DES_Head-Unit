SUMMARY = "GearSelector Application"
DESCRIPTION = "Vehicle gear selection interface with D-Bus integration"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

DEPENDS = " \
    qtbase \
    qtdeclarative \
    qtdeclarative-native \
"

SRC_URI = " \
    file://main.cpp \
    file://gs_handler.cpp \
    file://gs_handler.h \
    file://CMakeLists.txt \
    file://Main.qml \
    file://gearselector.service \
"

S = "${WORKDIR}"

inherit qt6-cmake systemd

SYSTEMD_SERVICE:${PN} = "gearselector.service"
SYSTEMD_AUTO_ENABLE = "enable"

EXTRA_OECMAKE += " \
    -DCMAKE_BUILD_TYPE=Release \
    -DQT_QPA_PLATFORM=wayland \
"

do_install() {
    # Install binary
    install -d ${D}${bindir}
    install -m 0755 ${B}/GearSelector ${D}${bindir}/gearselector
    
    # Install systemd service
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/gearselector.service ${D}${systemd_system_unitdir}/
    
    # Install application metadata
    install -d ${D}${datadir}/headunit/apps
    cat > ${D}${datadir}/headunit/apps/gearselector.desktop << EOF
[Desktop Entry]
Name=Gear Selector
IviID=1001
Role=GearSelector
BinaryPath=/usr/bin/gearselector
Icon=gear-selector
Categories=Vehicle;
EOF
}

FILES:${PN} = " \
    ${bindir}/gearselector \
    ${systemd_system_unitdir}/gearselector.service \
    ${datadir}/headunit/apps/gearselector.desktop \
"

RDEPENDS:${PN} += " \
    qtbase \
    qtdeclarative \
    qtwayland \
    qtwayland-plugins \
"

PACKAGECONFIG:append:pn-qtbase = " wayland"
# AFM compatibility: Create capitalized symlink
do_install:append() {
    ln -sf gearselector ${D}${bindir}/GearSelector
}

FILES:${PN} += "${bindir}/GearSelector"
