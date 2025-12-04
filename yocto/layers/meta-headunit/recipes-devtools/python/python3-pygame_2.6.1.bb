# Recipe for pygame - Python game development library

SUMMARY = "Python Game Development"
HOMEPAGE = "https://www.pygame.org"
LICENSE = "LGPL-2.1-only"
LIC_FILES_CHKSUM = "file://docs/LGPL.txt;md5=7fbc338309ac38fefcd64b04bb903e34"

SRC_URI = "git://github.com/pygame/pygame.git;protocol=https;branch=main"
SRCREV = "85fda3f719d437cf27106afae8c890e6b88ba5f5"

S = "${WORKDIR}/git"

inherit setuptools3

DEPENDS += " \
    python3-cython-native \
    libsdl2 \
    libsdl2-image \
    libsdl2-mixer \
    libsdl2-ttf \
    freetype \
    jpeg \
    libpng \
"

RDEPENDS:${PN} += " \
    libsdl2 \
    libsdl2-image \
    libsdl2-mixer \
    libsdl2-ttf \
"

BBCLASSEXTEND = "native nativesdk"
