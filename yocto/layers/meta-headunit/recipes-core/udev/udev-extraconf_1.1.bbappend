FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://99-drm-permissions.rules"

do_install:append() {
    install -d ${D}${sysconfdir}/udev/rules.d
    install -m 0644 ${WORKDIR}/99-drm-permissions.rules ${D}${sysconfdir}/udev/rules.d/
}
