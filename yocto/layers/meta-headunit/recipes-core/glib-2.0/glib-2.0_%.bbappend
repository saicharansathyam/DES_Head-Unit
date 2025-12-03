# Completely disable GIO module cache generation during image build
# This will be done on first boot instead

# Remove the problematic intercept
PACKAGE_WRITE_DEPS:remove = "qemu-native"

# Defer schema compilation to first boot
pkg_postinst_ontarget:${PN} () {
    if test -x ${bindir}/glib-compile-schemas; then
        ${bindir}/glib-compile-schemas ${datadir}/glib-2.0/schemas || true
    fi
    
    if test -x ${libexecdir}/gio-querymodules; then
        ${libexecdir}/gio-querymodules ${libdir}/gio/modules || true
    fi
}

# Don't run anything at build time - use empty function
pkg_postinst:${PN} () {
    true
}