FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://wpa_supplicant-wlan0.conf"

do_install:append() {
    install -d ${D}${sysconfdir}/wpa_supplicant
    install -m 600 ${WORKDIR}/wpa_supplicant-wlan0.conf ${D}${sysconfdir}/wpa_supplicant/
}
