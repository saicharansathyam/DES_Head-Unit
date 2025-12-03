FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://wayland-sockets.conf"

do_install:append() {
    # Install tmpfiles.d configuration for Wayland socket symlinks
    install -d ${D}${sysconfdir}/tmpfiles.d
    install -m 0644 ${WORKDIR}/wayland-sockets.conf ${D}${sysconfdir}/tmpfiles.d/
}

FILES:${PN} += "${sysconfdir}/tmpfiles.d/wayland-sockets.conf"
