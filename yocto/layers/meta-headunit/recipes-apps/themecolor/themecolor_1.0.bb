SUMMARY = "ThemeColor Application"
DESCRIPTION = "Theme and color customization interface for HeadUnit IVI"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# Build dependencies
DEPENDS = " \
    qtbase \
    qtdeclarative \
    qtdeclarative-native \
"

# Source files - Include ALL files
SRC_URI = " \
    file://main.cpp \
    file://ThemeColorClient.h \
    file://ThemeColorClient.cpp \
    file://CMakeLists.txt \
    file://Main.qml \
    file://ColorWheel.qml \
    file://PreviewButton.qml \
    file://ColorUtils.qml \
    file://ColorUtils.js \
    file://qmldir \
"

S = "${WORKDIR}"

inherit qt6-cmake

# CMake configuration
EXTRA_OECMAKE += " \
    -DCMAKE_BUILD_TYPE=Release \
    -DQT_QPA_PLATFORM=wayland \
"

do_install() {
    # Install binary
    install -d ${D}${bindir}
    install -m 0755 ${B}/appThemeColor ${D}${bindir}/ThemeColor
    
    # Install QML module files if they exist
    if [ -f ${B}/qmldir ]; then
        install -d ${D}${libdir}/qt6/qml/ThemeColor
        install -m 0644 ${B}/qmldir ${D}${libdir}/qt6/qml/ThemeColor/
    fi
    
    # Install application metadata
    install -d ${D}${datadir}/headunit/apps
    cat > ${D}${datadir}/headunit/apps/themecolor.desktop << EOF
[Desktop Entry]
Name=Theme & Colors
IviID=1003
Role=ThemeColor
BinaryPath=/usr/bin/ThemeColor
Icon=preferences-desktop-theme
Categories=Settings;Customization;
EOF
}

FILES:${PN} = " \
    ${bindir}/ThemeColor \
    ${libdir}/qt6/qml/ThemeColor/* \
    ${datadir}/headunit/apps/themecolor.desktop \
"

# Runtime dependencies
RDEPENDS:${PN} += " \
    qtbase \
    qtdeclarative \
    qtwayland \
    qtwayland-plugins \
"

# Ensure proper Qt configuration
PACKAGECONFIG:append:pn-qtbase = " wayland dbus"
