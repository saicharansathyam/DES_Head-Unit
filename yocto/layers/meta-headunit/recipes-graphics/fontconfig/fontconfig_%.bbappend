# Disable font cache postinstall for cross-compilation
PACKAGE_WRITE_DEPS:remove = "qemu-native"
FONTCONFIG_CACHE_DIR = "${localstatedir}/cache/fontconfig"

# Remove the problematic postinstall
pkg_postinst:${PN}() {
    # Font cache will be generated on first boot
    exit 0
}
