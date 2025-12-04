# meta-headunit/recipes-connectivity/can-setup/can-setup_1.0.bb

SUMMARY = "CAN Interface Setup Service"
DESCRIPTION = "Initializes can0 and can1 interfaces for MCP2515 at boot"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://can-setup.sh \
    file://can-setup.service \
"

S = "${WORKDIR}"

inherit systemd

SYSTEMD_SERVICE:${PN} = "can-setup.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    # Install shell script
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/can-setup.sh ${D}${bindir}/

    # Install systemd service
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/can-setup.service ${D}${systemd_system_unitdir}/
}

FILES:${PN} = " \
    ${bindir}/can-setup.sh \
    ${systemd_system_unitdir}/can-setup.service \
"

RDEPENDS:${PN} += " \
    iproute2 \
    can-utils \
"
