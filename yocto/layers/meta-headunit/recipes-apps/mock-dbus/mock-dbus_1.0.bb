SUMMARY = "Mock PiRacer D-Bus Service"
DESCRIPTION = "Simulates PiRacer dashboard for testing HeadUnit"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

RDEPENDS:${PN} = "python3-core python3-dbus python3-pygobject"

SRC_URI = " \
    file://Mock_DBUS.py \
    file://mock-dbus.service \
"

S = "${WORKDIR}"

inherit systemd

SYSTEMD_SERVICE:${PN} = "mock-dbus.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    # Install Python script
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/Mock_DBUS.py ${D}${bindir}/mock-dbus-service
    
    # Install systemd service
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/mock-dbus.service ${D}${systemd_system_unitdir}/
}

FILES:${PN} = " \
    ${bindir}/mock-dbus-service \
    ${systemd_system_unitdir}/mock-dbus.service \
"
