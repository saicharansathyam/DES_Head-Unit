SUMMARY = "Application Framework Manager"
DESCRIPTION = "Central lifecycle manager for IVI applications via D-Bus"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

DEPENDS = "qtbase qtdeclarative"

SRC_URI = " \
    file://main.cpp \
    file://application_framework_manager.h \
    file://application_framework_manager.cpp \
    file://CMakeLists.txt \
    file://applications.json \
    file://afm.service \
    file://afm-tmpfiles.conf \
"

S = "${WORKDIR}"

inherit qt6-cmake systemd

SYSTEMD_SERVICE:${PN} = "afm.service"
SYSTEMD_AUTO_ENABLE = "enable"

EXTRA_OECMAKE += " \
    -DCMAKE_BUILD_TYPE=Release \
"

do_install:append() {
    # Install systemd service
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/afm.service ${D}${systemd_system_unitdir}/
    
    # Install tmpfiles configuration for log directory
    install -d ${D}${sysconfdir}/tmpfiles.d
    install -m 0644 ${WORKDIR}/afm-tmpfiles.conf ${D}${sysconfdir}/tmpfiles.d/
    
    # Install config
    install -d ${D}${sysconfdir}/headunit
    install -m 0644 ${WORKDIR}/applications.json ${D}${sysconfdir}/headunit/
}

FILES:${PN} += " \
    ${bindir}/headunit-afm \
    ${sysconfdir}/headunit/applications.json \
    ${sysconfdir}/tmpfiles.d/afm-tmpfiles.conf \
    ${systemd_system_unitdir}/afm.service \
"

RDEPENDS:${PN} += "qtbase qtdeclarative dbus"
