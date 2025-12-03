SUMMARY = "D-Bus Session Bus Service"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://dbus-session.service"

inherit systemd

SYSTEMD_SERVICE:${PN} = "dbus-session.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/dbus-session.service ${D}${systemd_system_unitdir}/
}

FILES:${PN} = "${systemd_system_unitdir}/dbus-session.service"

RDEPENDS:${PN} = "dbus"
