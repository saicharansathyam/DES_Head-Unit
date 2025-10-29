SUMMARY = "Mock D-Bus Services"
DESCRIPTION = "Mock D-Bus services for testing HeadUnit IVI system (Dashboard, MediaPlayer, Settings, Theme)"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

RDEPENDS:${PN} = " \
    python3-core \
    python3-dbus \
    python3-pygobject \
    python3-modules \
"

SRC_URI = " \
    file://Mock_DBUS.py \
    file://mediaplayer_service.py \
    file://settings_service.py \
    file://theme_service.py \
    file://Dashboard_Service_HeadUnit_IC.py \
    file://mock-dbus.service \
    file://mock-mediaplayer.service \
    file://mock-settings.service \
    file://mock-theme.service \
    file://dbus_service.py \
    file://mock-dbus-tmpfiles.conf \
"

S = "${WORKDIR}"

inherit systemd

SYSTEMD_SERVICE:${PN} = " \
    mock-dbus.service \
    mock-mediaplayer.service \
    mock-settings.service \
    mock-theme.service \
"

SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    # Install Python scripts
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/Mock_DBUS.py ${D}${bindir}/mock-dbus-service
    install -m 0755 ${WORKDIR}/mediaplayer_service.py ${D}${bindir}/mock-mediaplayer-service
    install -m 0755 ${WORKDIR}/settings_service.py ${D}${bindir}/mock-settings-service
    install -m 0755 ${WORKDIR}/theme_service.py ${D}${bindir}/mock-theme-service
    install -m 0755 ${WORKDIR}/Dashboard_Service_HeadUnit_IC.py ${D}${bindir}/mock-dashboard-service
    
    # Install shared D-Bus module if it exists
    if [ -f ${WORKDIR}/dbus_service.py ]; then
        install -d ${D}${libdir}/python3/site-packages/headunit
        install -m 0644 ${WORKDIR}/dbus_service.py ${D}${libdir}/python3/site-packages/headunit/
        touch ${D}${libdir}/python3/site-packages/headunit/__init__.py
    fi
    
    # Install systemd services
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/mock-dbus.service ${D}${systemd_system_unitdir}/
    install -m 0644 ${WORKDIR}/mock-mediaplayer.service ${D}${systemd_system_unitdir}/
    install -m 0644 ${WORKDIR}/mock-settings.service ${D}${systemd_system_unitdir}/
    install -m 0644 ${WORKDIR}/mock-theme.service ${D}${systemd_system_unitdir}/
    
    # Install tmpfiles configuration for log directory
    install -d ${D}${sysconfdir}/tmpfiles.d
    install -m 0644 ${WORKDIR}/mock-dbus-tmpfiles.conf ${D}${sysconfdir}/tmpfiles.d/
}

FILES:${PN} = " \
    ${bindir}/mock-dbus-service \
    ${bindir}/mock-mediaplayer-service \
    ${bindir}/mock-settings-service \
    ${bindir}/mock-theme-service \
    ${bindir}/mock-dashboard-service \
    ${libdir}/python3/site-packages/headunit/* \
    ${systemd_system_unitdir}/mock-dbus.service \
    ${systemd_system_unitdir}/mock-mediaplayer.service \
    ${systemd_system_unitdir}/mock-settings.service \
    ${systemd_system_unitdir}/mock-theme.service \
    ${sysconfdir}/tmpfiles.d/mock-dbus-tmpfiles.conf \
"

# Ensure services start after D-Bus
pkg_postinst:${PN}() {
    if [ -z "$D" ]; then
        systemctl daemon-reload
        systemctl enable mock-dbus.service
        systemctl enable mock-mediaplayer.service
        systemctl enable mock-settings.service
        systemctl enable mock-theme.service
    fi
}
