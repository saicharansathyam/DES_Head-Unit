SUMMARY = "Mock Dashboard Service for InstrumentCluster"
DESCRIPTION = "D-Bus service providing mock vehicle data (speed, battery, gear, turn signals)"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://mock_dashboard_service.py \
    file://mock-dashboard.service \
"

S = "${WORKDIR}"

RDEPENDS:${PN} = "python3-dbus python3-pygobject"

do_install() {
    # Install Python service
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/mock_dashboard_service.py ${D}${bindir}/mock-dashboard-service

    # Install systemd service
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/mock-dashboard.service ${D}${systemd_system_unitdir}/
}

inherit systemd

SYSTEMD_SERVICE:${PN} = "mock-dashboard.service"
SYSTEMD_AUTO_ENABLE = "enable"

FILES:${PN} += " \
    ${bindir}/mock-dashboard-service \
    ${systemd_system_unitdir}/mock-dashboard.service \
"