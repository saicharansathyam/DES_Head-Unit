# meta-headunit/recipes-apps/rc-piracer/rc-piracer_1.0.bb

SUMMARY = "PiRacer Remote Controller Service (GamePad)"
DESCRIPTION = "Python service that reads gamepad input and controls PiRacer via D-Bus"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://rc_piracer.py \
    file://rc-piracer.service \
"

S = "${WORKDIR}"

inherit systemd

SYSTEMD_SERVICE:${PN} = "rc-piracer.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    # Install Python script
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/rc_piracer.py ${D}${bindir}/

    # Change SessionBus to SystemBus for hardware mode
    sed -i 's/bus = dbus.SessionBus()/bus = dbus.SystemBus()/' \
        ${D}${bindir}/rc_piracer.py

    # Install systemd service
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/rc-piracer.service ${D}${systemd_system_unitdir}/
}

FILES:${PN} = " \
    ${bindir}/rc_piracer.py \
    ${systemd_system_unitdir}/rc-piracer.service \
"

RDEPENDS:${PN} += " \
    python3-dbus \
    python3-pygobject \
    python3-evdev \
    python3-piracer-py \
    mock-dbus \
"
