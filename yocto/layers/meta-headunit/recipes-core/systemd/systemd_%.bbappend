# Fix udev-hwdb postinstall to defer to first boot
pkg_postinst_ontarget:udev-hwdb () {
    if test -x ${bindir}/udevadm; then
        ${bindir}/udevadm hwdb --update || true
    elif test -x ${bindir}/systemd-hwdb; then
        ${bindir}/systemd-hwdb update || true
    fi
}

# Remove the build-time postinstall
pkg_postinst:udev-hwdb () {
    # Defer to first boot
    true
}

# No wlan0.network or networkd configuration; ConnMan manages WiFi/DHCP exclusively.

