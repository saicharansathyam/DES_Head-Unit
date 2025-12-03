SUMMARY = "Provision ConnMan with pre-defined Wi-Fi credentials"
DESCRIPTION = "Installs a provisioning file in /var/lib/connman so that ConnMan automatically connects to the configured Wi-Fi network on first boot."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit allarch systemd

SRC_URI = "file://force-connman.service"

SYSTEMD_SERVICE:${PN} = "force-connman.service"
SYSTEMD_AUTO_ENABLE = "enable"

CONNMANC_WIFI_CONFIG_NAME ?= "sea-me-wifi"
CONNMANC_WIFI_SSID ?= "SEA:ME WiFi Access"
CONNMANC_WIFI_PASSPHRASE ?= "1fy0u534m3"
CONNMANC_WIFI_SECURITY ?= "psk"
CONNMANC_WIFI_AUTOCONNECT ?= "true"
CONNMANC_WIFI_HIDDEN ?= "false"
CONNMANC_WIFI_DEVICE ?= "wlan0"
CONNMANC_WIFI_IPV4 ?= "dhcp"
CONNMANC_WIFI_IPV6 ?= "auto"
CONNMANC_WIFI_EXTRA ?= ""

do_install[dirs] = "${D}/var/lib/connman"

python do_install () {
    import os
    import shutil
    dvar = d.getVar
    
    # Install WiFi config
    ssid = (dvar('CONNMANC_WIFI_SSID') or '').strip()
    passwd = (dvar('CONNMANC_WIFI_PASSPHRASE') or '').strip()
    if not ssid or not passwd:
        bb.warn('CONNMANC_WIFI_SSID / CONNMANC_WIFI_PASSPHRASE not set; skipping Wi-Fi provisioning file')
    else:
        config_dir = os.path.join(dvar('D'), 'var', 'lib', 'connman')
        bb.utils.mkdirhier(config_dir)
        config_name = (dvar('CONNMANC_WIFI_CONFIG_NAME') or 'sea-me-wifi').strip()
        config_path = os.path.join(config_dir, "%s.config" % config_name)
        contents = """[service_{name}]
Type = wifi
Name = {ssid}
Security = {security}
Passphrase = {passphrase}
Favorite = true
AutoConnect = {autoconnect}
Hidden = {hidden}
DeviceName = {device}
IPv4 = {ipv4}
IPv6 = {ipv6}
""".format(
            name=config_name,
            ssid=ssid,
            security=dvar('CONNMANC_WIFI_SECURITY') or 'psk',
            passphrase=passwd,
            autoconnect=dvar('CONNMANC_WIFI_AUTOCONNECT') or 'true',
            hidden=dvar('CONNMANC_WIFI_HIDDEN') or 'false',
            device=dvar('CONNMANC_WIFI_DEVICE') or 'wlan0',
            ipv4=dvar('CONNMANC_WIFI_IPV4') or 'dhcp',
            ipv6=dvar('CONNMANC_WIFI_IPV6') or 'auto',
        )
        extra = (dvar('CONNMANC_WIFI_EXTRA') or '').strip()
        if extra:
            contents = contents + extra + "\n"
        with open(config_path, 'w', encoding='utf-8') as config_file:
            config_file.write(contents)
        os.chmod(config_path, 0o600)
    
    # Install systemd service
    systemd_dir = os.path.join(dvar('D'), dvar('systemd_system_unitdir').lstrip('/'))
    bb.utils.mkdirhier(systemd_dir)
    service_src = os.path.join(dvar('WORKDIR'), 'force-connman.service')
    service_dst = os.path.join(systemd_dir, 'force-connman.service')
    shutil.copy2(service_src, service_dst)
    os.chmod(service_dst, 0o644)
}

FILES:${PN} += "/var/lib/connman/*.config ${systemd_system_unitdir}/force-connman.service"

RDEPENDS:${PN} = "connman systemd"
ALLOW_EMPTY:${PN} = "1"
