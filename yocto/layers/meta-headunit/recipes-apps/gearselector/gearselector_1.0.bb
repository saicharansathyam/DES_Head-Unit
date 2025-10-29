SUMMARY = "GearSelector Application"
DESCRIPTION = "Vehicle gear selection interface with D-Bus integration"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# Build dependencies
DEPENDS = " \
    qtbase \
    qtdeclarative \
    qtdeclarative-native \
"

# Source files - Include ALL files your app needs
SRC_URI = " \
    file://main.cpp \
    file://gs_handler.cpp \
    file://gs_handler.h \
    file://CMakeLists.txt \
    file://Main.qml \
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
    install -m 0755 ${B}/GearSelector ${D}${bindir}/
    
    # Install application metadata (optional but recommended)
    install -d ${D}${datadir}/headunit/apps
    echo '[Desktop Entry]' > ${D}${datadir}/headunit/apps/gearselector.desktop
    echo 'Name=Gear Selector' >> ${D}${datadir}/headunit/apps/gearselector.desktop
    echo 'IviID=1001' >> ${D}${datadir}/headunit/apps/gearselector.desktop
    echo 'Role=GearSelector' >> ${D}${datadir}/headunit/apps/gearselector.desktop
    echo 'BinaryPath=/usr/bin/GearSelector' >> ${D}${datadir}/headunit/apps/gearselector.desktop
    echo 'Icon=gear-selector' >> ${D}${datadir}/headunit/apps/gearselector.desktop
    echo 'Categories=Vehicle;' >> ${D}${datadir}/headunit/apps/gearselector.desktop
}

FILES:${PN} = " \
    ${bindir}/GearSelector \
    ${datadir}/headunit/apps/gearselector.desktop \
"

# Runtime dependencies
RDEPENDS:${PN} += " \
    qtbase \
    qtdeclarative \
    qtwayland \
    qtwayland-plugins \
"

# Ensure Wayland protocol support
PACKAGECONFIG:append:pn-qtbase = " wayland"
