SUMMARY = "DejaVu fonts - TTF Edition"
DESCRIPTION = "DejaVu fonts with no problematic postinstall"
LICENSE = "BitstreamVera"
LIC_FILES_CHKSUM = "file://LICENSE;md5=449b2c30bfe5fa897fe87b8b70b16cfa"

SRC_URI = "file://dejavu-fonts-ttf-2.37.tar.bz2"

S = "${WORKDIR}/dejavu-fonts-ttf-2.37"

do_install() {
    install -d ${D}${datadir}/fonts/truetype/dejavu
    install -m 0644 ${S}/ttf/*.ttf ${D}${datadir}/fonts/truetype/dejavu/
}

FILES:${PN} = "${datadir}/fonts/truetype/dejavu/*.ttf"

# Skip font cache generation - Qt will handle it
PACKAGE_WRITE_DEPS:remove = "fontconfig-native"
RDEPENDS:${PN} = ""
