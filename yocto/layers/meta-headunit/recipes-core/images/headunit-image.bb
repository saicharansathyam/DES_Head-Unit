# --- meta-headunit: headunit-image.bb ---

SUMMARY = "Head Unit Custom Image for Raspberry Pi 4"
LICENSE = "MIT"

inherit core-image

IMAGE_FEATURES += " ssh-server-openssh splash"

IMAGE_INSTALL:append = " \
    packagegroup-core-boot \
    qtbase \
    qtdeclarative \
    qtwayland \
    qtmultimedia \
    qtbase-plugins \
    gearselector \
    mediaplayer \
    ivi-compositor \
    themecolor \
"

# ===== Wi-Fi autoconnect configuration =====
# Regulatory domain for Wi-Fi
WIFI_COUNTRY ?= "DE"
# SSID and PSK (override in local.conf if desired)
WIFI_SSID    ?= "SEA:ME WiFi Access"
WIFI_PSK     ?= "1fy0u534m3"

# Avoid regdb package conflict and install required bits
IMAGE_INSTALL:remove = " wireless-regdb "
IMAGE_INSTALL:append = " wpa-supplicant iw linux-firmware wireless-regdb-static "

# Ensure systemd includes networkd and resolved
PACKAGECONFIG:append:pn-systemd = " networkd resolved"

# Rootfs tweaks to enable Wi-Fi + DHCP at first boot
ROOTFS_POSTPROCESS_COMMAND += "headunit_wifi_autosetup;"

python headunit_wifi_autosetup () {
    import os
    dget = d.getVar
    root    = dget('IMAGE_ROOTFS')
    ssid    = dget('WIFI_SSID') or ''
    psk     = dget('WIFI_PSK') or ''
    country = dget('WIFI_COUNTRY') or '00'

    # systemd-networkd: DHCP on wlan0
    netdir = os.path.join(root, 'etc', 'systemd', 'network')
    os.makedirs(netdir, exist_ok=True)
    with open(os.path.join(netdir, 'wlan0.network'), 'w') as f:
        f.write("[Match]\nName=wlan0\n\n[Network]\nDHCP=yes\n")

    # wpa_supplicant config for wlan0 (used by wpa_supplicant@wlan0.service)
    wpadir = os.path.join(root, 'etc', 'wpa_supplicant')
    os.makedirs(wpadir, exist_ok=True)
    wpa_cfg = os.path.join(wpadir, 'wpa_supplicant-wlan0.conf')
    with open(wpa_cfg, 'w') as f:
        f.write("ctrl_interface=/var/run/wpa_supplicant\n")
        f.write("update_config=1\n")
        f.write("country=%s\n\n" % country)
        f.write("network={\n")
        f.write('    ssid="%s"\n' % ssid)
        f.write('    psk="%s"\n' % psk)
        f.write("    key_mgmt=WPA-PSK\n")
        f.write("    scan_ssid=1\n")
        f.write("    freq_list=2412 2437 2462\n")
        f.write("}\n")
    os.chmod(wpa_cfg, 0o600)

    # Enable services
    wants = os.path.join(root, 'etc', 'systemd', 'system', 'multi-user.target.wants')
    os.makedirs(wants, exist_ok=True)
    def link(unit):
        src = '../../lib/systemd/system/' + unit
        dst = os.path.join(wants, unit)
        try:
            if os.path.islink(dst) or os.path.exists(dst):
                os.remove(dst)
        except FileNotFoundError:
            pass
        os.symlink(src, dst)

    link('systemd-networkd.service')
    link('systemd-resolved.service')
    link('wpa_supplicant@wlan0.service')

    # resolv.conf -> systemd-resolved stub
    etc = os.path.join(root, 'etc')
    resolv = os.path.join(etc, 'resolv.conf')
    try:
        if os.path.islink(resolv) or os.path.exists(resolv):
            os.remove(resolv)
    except FileNotFoundError:
        pass
    os.symlink('/run/systemd/resolve/stub-resolv.conf', resolv)

    # Persistent regulatory domain for cfg80211
    moddir = os.path.join(root, 'etc', 'modprobe.d')
    os.makedirs(moddir, exist_ok=True)
    with open(os.path.join(moddir, 'cfg80211.conf'), 'w') as f:
        f.write("options cfg80211 ieee80211_regdom=%s\n" % country)
}

# Set root filesystem size
IMAGE_ROOTFS_EXTRA_SPACE = "2048"

# Enable WiFi and SSH
SYSTEMD_AUTO_ENABLE = "enable"
