SUMMARY = "HeadUnit Auto-Startup Service"
DESCRIPTION = "Automatically starts compositor and applications on boot"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://headunit-startup.sh \
    file://headunit-startup.service \
"

S = "${WORKDIR}"

inherit systemd

SYSTEMD_SERVICE:${PN} = "headunit-startup.service"
SYSTEMD_AUTO_ENABLE = "disable"

do_install() {
    # Install startup script
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/headunit-startup.sh ${D}${bindir}/
    
    # Install systemd service
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/headunit-startup.service ${D}${systemd_system_unitdir}/
}

FILES:${PN} = " \
    ${bindir}/headunit-startup.sh \
    ${systemd_system_unitdir}/headunit-startup.service \
"

RDEPENDS:${PN} += "bash systemd dbus"
