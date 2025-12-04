FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://weston.ini \
            file://weston-service-delay/delay.conf"

do_install:append() {
    # Install weston.ini
    install -d ${D}${sysconfdir}/xdg/weston
    install -m 0644 ${WORKDIR}/weston.ini ${D}${sysconfdir}/xdg/weston/weston.ini
    
    # Install systemd drop-in for startup delay
    install -d ${D}${systemd_system_unitdir}/weston.service.d
    install -m 0644 ${WORKDIR}/weston-service-delay/delay.conf ${D}${systemd_system_unitdir}/weston.service.d/
}

FILES:${PN} += "${sysconfdir}/xdg/weston/weston.ini \
                ${systemd_system_unitdir}/weston.service.d/delay.conf"
