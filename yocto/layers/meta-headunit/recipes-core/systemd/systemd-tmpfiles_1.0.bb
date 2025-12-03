SUMMARY = "Tmpfiles configuration for HeadUnit"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://headunit-tmpfiles.conf"

do_install() {
    install -d ${D}${sysconfdir}/tmpfiles.d
    install -m 0644 ${WORKDIR}/headunit-tmpfiles.conf ${D}${sysconfdir}/tmpfiles.d/headunit.conf
}

FILES:${PN} = "${sysconfdir}/tmpfiles.d/headunit.conf"
