SUMMARY = "Media Player Application"
DESCRIPTION = "Advanced media player with USB, YouTube, and D-Bus integration"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

DEPENDS = " \
    qtbase \
    qtdeclarative \
    qtdeclarative-native \
    qtwayland \
    qtmultimedia \
    qtvirtualkeyboard \
"

SRC_URI = " \
    file://main.cpp \
    file://mp_handler.cpp \
    file://mp_handler.h \
    file://CMakeLists.txt \
    file://resources.qrc \
    file://qml/Main.qml \
    file://qml/MediaControls.qml \
    file://qml/MediaDisplay.qml \
    file://qml/ProgressBar.qml \
    file://qml/SourceSelector.qml \
    file://qml/USBPlaylist.qml \
    file://qml/VolumeControl.qml \
    file://qml/YouTubeView.qml \
    file://icons/play.svg \
    file://icons/pause.svg \
    file://icons/stop.svg \
    file://icons/skip-back.svg \
    file://icons/skip-forward.svg \
    file://icons/volume.svg \
    file://mediaplayer.desktop \
    file://mediaplayer.service \
"

S = "${WORKDIR}"

inherit qt6-cmake systemd

SYSTEMD_SERVICE:${PN} = "mediaplayer.service"
SYSTEMD_AUTO_ENABLE = "disable"

EXTRA_OECMAKE += " \
    -DCMAKE_BUILD_TYPE=Release \
"

do_install() {
    # Install binary
    install -d ${D}${bindir}
    install -m 0755 ${B}/MediaPlayer ${D}${bindir}/mediaplayer
    
    # Install systemd service
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/mediaplayer.service ${D}${systemd_system_unitdir}/
    
    # Install app metadata
    install -d ${D}${datadir}/headunit/apps
    install -m 0644 ${WORKDIR}/mediaplayer.desktop ${D}${datadir}/headunit/apps/
}

# AFM compatibility: Create capitalized symlink
do_install:append() {
    ln -sf mediaplayer ${D}${bindir}/MediaPlayer
}

FILES:${PN} = " \
    ${bindir}/mediaplayer \
    ${bindir}/MediaPlayer \
    ${systemd_system_unitdir}/mediaplayer.service \
    ${datadir}/headunit/apps/mediaplayer.desktop \
"

RDEPENDS:${PN} += " \
    qtbase \
    qtdeclarative \
    qtwayland \
    qtwayland-plugins \
    qtmultimedia \
    qtvirtualkeyboard \
"
