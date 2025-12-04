# meta-headunit/recipes-apps/mock-dbus/mock-dbus_1.0.bb

SUMMARY = "Unified D-Bus Service for HeadUnit IVI"
DESCRIPTION = "Single D-Bus service providing all interfaces (Dashboard, MediaPlayer, Settings, ThemeColor)"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://unified-dbus-service.py \
    file://unified-dbus.service \
    file://mock-dbus-tmpfiles.conf \
"

S = "${WORKDIR}"

inherit systemd

SYSTEMD_SERVICE:${PN} = "unified-dbus.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    # Install Python script
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/unified-dbus-service.py ${D}${bindir}/
    
    # ============================================
    # CRITICAL FIX: Change SessionBus to SystemBus
    # ============================================
    sed -i 's/bus = dbus.SessionBus()/bus = dbus.SystemBus()/' \
        ${D}${bindir}/unified-dbus-service.py
    
    # Install systemd service
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/unified-dbus.service ${D}${systemd_system_unitdir}/
    
    # Install tmpfiles configuration for /run/user/0
    install -d ${D}${sysconfdir}/tmpfiles.d
    install -m 0644 ${WORKDIR}/mock-dbus-tmpfiles.conf ${D}${sysconfdir}/tmpfiles.d/
}

FILES:${PN} = " \
    ${bindir}/unified-dbus-service.py \
    ${systemd_system_unitdir}/unified-dbus.service \
    ${sysconfdir}/tmpfiles.d/mock-dbus-tmpfiles.conf \
"

RDEPENDS:${PN} += " \
    python3-dbus \
    python3-pygobject \
    python3-numpy \
    python3-can \
    adafruit-blinka \
    adafruit-circuitpython-ina219 \
    dbus \
    can-utils \
"