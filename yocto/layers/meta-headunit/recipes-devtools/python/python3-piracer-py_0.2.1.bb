# Recipe for piracer-py - PiRacer Python library

SUMMARY = "Python library for PiRacer"
HOMEPAGE = "https://github.com/SEA-ME/piracer_py"
LICENSE = "GPL-3.0-only"
LIC_FILES_CHKSUM = "file://LICENSE;md5=6decff0ca0b506b9b7a5f54ac3d286f8"

# Using GitHub tarball instead of PyPI
SRC_URI = "git://github.com/SEA-ME/piracer_py.git;protocol=https;branch=master"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"

inherit setuptools3

RDEPENDS:${PN} += " \
    adafruit-blinka \
    adafruit-circuitpython-ina219 \
    python3-smbus \
"

BBCLASSEXTEND = "native nativesdk"
