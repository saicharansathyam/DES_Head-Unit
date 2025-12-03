SUMMARY = "Boot Animation Service"
DESCRIPTION = "Displays LEXUS logo video on boot before compositor starts"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://boot-animation.service \
    file://lexus-logo.mp4 \
"

inherit systemd

SYSTEMD_SERVICE:${PN} = "boot-animation.service"
SYSTEMD_AUTO_ENABLE = "enable"

RDEPENDS:${PN} += " \
    gstreamer1.0 \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
"

do_install() {
    # Install video file
    install -d ${D}/usr/share/boot-animation
    install -m 0644 ${WORKDIR}/lexus-logo.mp4 ${D}/usr/share/boot-animation/

    # Install systemd service
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/boot-animation.service ${D}${systemd_system_unitdir}/
}

FILES:${PN} += " \
    /usr/share/boot-animation/lexus-logo.mp4 \
    ${systemd_system_unitdir}/boot-animation.service \
"