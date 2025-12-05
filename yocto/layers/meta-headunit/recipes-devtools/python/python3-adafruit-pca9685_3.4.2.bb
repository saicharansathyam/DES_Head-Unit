SUMMARY = "Python library for Adafruit PCA9685 PWM driver"
DESCRIPTION = "CircuitPython driver for PCA9685 16-channel, 12-bit PWM LED & Servo driver"
HOMEPAGE = "https://github.com/adafruit/Adafruit_CircuitPython_PCA9685"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=e7eb6b599fb0cfb06485c64cd4242f62"

PYPI_PACKAGE = "adafruit-circuitpython-pca9685"

SRC_URI[sha256sum] = "e02670c8a78f2febde5590e2742e01ed8222494a397ec962f50e27f6a00e23b6"

inherit pypi python_setuptools_build_meta

DEPENDS += "python3-setuptools-scm-native"

RDEPENDS:${PN} = " \
    ${PYTHON_PN}-core \
    adafruit-blinka \
    adafruit-circuitpython-busdevice \
    adafruit-circuitpython-register \
"
