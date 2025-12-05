SUMMARY = "Python library for Raspberry Pi GPIO control"
DESCRIPTION = "A module to control Raspberry Pi GPIO channels"
HOMEPAGE = "https://sourceforge.net/projects/raspberry-gpio-python/"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENCE.txt;md5=a2294b0b1daabc30dfb5b3de73b2e00a"

PYPI_PACKAGE = "RPi.GPIO"

SRC_URI[sha256sum] = "cd61c4b03c37b62bba4a5acfea9862749c33c618e0295e7e90aa4713fb373b70"

inherit pypi setuptools3

RDEPENDS:${PN} = "${PYTHON_PN}-core"

COMPATIBLE_MACHINE = "^rpi$"
