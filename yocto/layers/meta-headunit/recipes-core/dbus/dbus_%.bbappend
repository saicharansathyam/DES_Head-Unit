FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://com.seame.conf"

do_install:append() {
    install -d ${D}${sysconfdir}/dbus-1/system.d
    install -m 0644 ${WORKDIR}/com.seame.conf ${D}${sysconfdir}/dbus-1/system.d/
}

FILES:${PN} += "${sysconfdir}/dbus-1/system.d/com.seame.conf"
