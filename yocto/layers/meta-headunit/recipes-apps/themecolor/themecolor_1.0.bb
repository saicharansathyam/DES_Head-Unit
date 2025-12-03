SUMMARY = "ThemeColor Application"
DESCRIPTION = "Theme and color customization interface for HeadUnit IVI"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

DEPENDS = " \
    qtbase \
    qtdeclarative \
    qtdeclarative-native \
"

SRC_URI = " \
    file://main.cpp \
    file://ThemeColorClient.h \
    file://ThemeColorClient.cpp \
    file://CMakeLists.txt \
    file://qml.qrc \
    file://Main.qml \
    file://ColorWheel.qml \
    file://PreviewButton.qml \
    file://ColorUtils.qml \
    file://ColorUtils.js \
    file://qmldir \
    file://themecolor.service \
"

S = "${WORKDIR}"

inherit qt6-cmake systemd

SYSTEMD_SERVICE:${PN} = "themecolor.service"
SYSTEMD_AUTO_ENABLE = "enable"

EXTRA_OECMAKE += " \
    -DCMAKE_BUILD_TYPE=Release \
    -DQT_QPA_PLATFORM=wayland \
"

do_install() {
    # Install binary
    install -d ${D}${bindir}
    install -m 0755 ${B}/ThemeColor ${D}${bindir}/themecolor
    
    # Install systemd service
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/themecolor.service ${D}${systemd_system_unitdir}/
    
    # Install QML module files if they exist
    if [ -f ${WORKDIR}/qmldir ]; then
        install -d ${D}${libdir}/qt6/qml/ThemeColor
        install -m 0644 ${WORKDIR}/qmldir ${D}${libdir}/qt6/qml/ThemeColor/
    fi
    
    # Install application metadata
    install -d ${D}${datadir}/headunit/apps
    cat > ${D}${datadir}/headunit/apps/themecolor.desktop << EOF2
[Desktop Entry]
Name=Theme & Colors
IviID=1003
Role=ThemeColor
BinaryPath=/usr/bin/themecolor
Icon=preferences-desktop-theme
Categories=Settings;Customization;
EOF2
}

# AFM compatibility: Create capitalized symlink
do_install:append() {
    ln -sf themecolor ${D}${bindir}/ThemeColor
}

FILES:${PN} = " \
    ${bindir}/themecolor \
    ${bindir}/ThemeColor \
    ${systemd_system_unitdir}/themecolor.service \
    ${libdir}/qt6/qml/ThemeColor/* \
    ${datadir}/headunit/apps/themecolor.desktop \
"

RDEPENDS:${PN} += " \
    qtbase \
    qtdeclarative \
    qtwayland \
    qtwayland-plugins \
"

PACKAGECONFIG:append:pn-qtbase = " wayland dbus"
