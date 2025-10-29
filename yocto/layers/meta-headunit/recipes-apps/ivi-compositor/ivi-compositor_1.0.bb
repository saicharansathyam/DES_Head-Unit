SUMMARY = "IVI Compositor"
DESCRIPTION = "Wayland compositor for HeadUnit IVI system with D-Bus integration"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# Build dependencies
DEPENDS = " \
    qtbase \
    qtdeclarative \
    qtdeclarative-native \
    qtwayland \
    qtwayland-native \
    wayland \
    wayland-native \
"

# Source files - Include ALL necessary files
SRC_URI = " \
    file://main.cpp \
    file://dbus_manager.h \
    file://dbus_manager.cpp \
    file://CMakeLists.txt \
    file://qml.qrc \
    file://qml/Main.qml \
    file://qml/SurfaceManager.qml \
    file://qml/AppSwitcher.qml \
    file://qml/LeftPanel.qml \
    file://qml/RightPanel.qml \
    file://compositor.service \
    file://ivi-compositor-tmpfiles.conf \
"

S = "${WORKDIR}"

inherit qt6-cmake systemd

SYSTEMD_SERVICE:${PN} = "compositor.service"
SYSTEMD_AUTO_ENABLE = "enable"

# CMake configuration
EXTRA_OECMAKE += " \
    -DCMAKE_BUILD_TYPE=Release \
    -DQT_QPA_PLATFORM=eglfs \
"

do_install() {
    # Install binary
    install -d ${D}${bindir}
    install -m 0755 ${B}/headUnit ${D}${bindir}/ivi-compositor
    
    # Install systemd service
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/compositor.service ${D}${systemd_system_unitdir}/
    
    # Install tmpfiles configuration for log directory
    install -d ${D}${sysconfdir}/tmpfiles.d
    install -m 0644 ${WORKDIR}/ivi-compositor-tmpfiles.conf ${D}${sysconfdir}/tmpfiles.d/
    
    # Install application metadata
    install -d ${D}${datadir}/headunit/apps
    cat > ${D}${datadir}/headunit/apps/compositor.desktop << EOF
[Desktop Entry]
Name=IVI Compositor
Type=Application
Exec=/usr/bin/ivi-compositor
Categories=System;
EOF
}

FILES:${PN} = " \
    ${bindir}/ivi-compositor \
    ${systemd_system_unitdir}/compositor.service \
    ${sysconfdir}/tmpfiles.d/ivi-compositor-tmpfiles.conf \
    ${datadir}/headunit/apps/compositor.desktop \
"


# Runtime dependencies
RDEPENDS:${PN} += " \
    qtbase \
    qtdeclarative \
    qtwayland \
    qtwayland-plugins \
    wayland \
    mesa \
    libdrm \
"

# Ensure compositor starts before applications
SYSTEMD_SERVICE:${PN} = "compositor.service"

# Security and permissions
USERADD_PACKAGES = "${PN}"
GROUPADD_PARAM:${PN} = "-r wayland"

# Ensure proper Qt and Wayland configuration
PACKAGECONFIG:append:pn-qtbase = " eglfs kms gbm wayland"
PACKAGECONFIG:append:pn-qtwayland = " wayland-compositor"
