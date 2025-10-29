require recipes-core/images/core-image-base.bb

SUMMARY = "HeadUnit Custom Linux Image"
DESCRIPTION = "Modular IVI system with optimized dependencies"
LICENSE = "MIT"

IMAGE_INSTALL:append = " \
    packagegroup-headunit-core \
    packagegroup-headunit-fonts \
    packagegroup-headunit-input \
    packagegroup-headunit-graphics \
"

# Development features
IMAGE_FEATURES += "ssh-server-openssh"
EXTRA_IMAGE_FEATURES += "debug-tweaks tools-debug"

# Enable systemd
DISTRO_FEATURES:append = " systemd"
VIRTUAL-RUNTIME_init_manager = "systemd"
VIRTUAL-RUNTIME_initscripts = ""

# Touch screen support
DISTRO_FEATURES:append = " touchscreen opengl wayland"

# Qt optimizations
PACKAGECONFIG:append:pn-qtbase = " fontconfig dbus accessibility"
PACKAGECONFIG:append:pn-qtmultimedia = " gstreamer"

# Image size optimization
IMAGE_FSTYPES = "tar.bz2 ext4 wic.bz2"
IMAGE_ROOTFS_EXTRA_SPACE = "524288"