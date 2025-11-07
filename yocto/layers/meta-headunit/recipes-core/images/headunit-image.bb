require recipes-core/images/core-image-base.bb

SUMMARY = "HeadUnit Custom Linux Image"
DESCRIPTION = "Modular IVI system with optimized dependencies"
LICENSE = "MIT"

IMAGE_INSTALL:append = " \
    packagegroup-headunit-core \
    packagegroup-headunit-fonts \
    packagegroup-headunit-input \
    packagegroup-headunit-graphics \
    headunit-startup \
"

# Development features
IMAGE_FEATURES += "ssh-server-openssh"
EXTRA_IMAGE_FEATURES += "debug-tweaks tools-debug"

# Qt optimizations
PACKAGECONFIG:append:pn-qtbase = " fontconfig dbus accessibility"
PACKAGECONFIG:append:pn-qtmultimedia = " gstreamer"

# Image size optimization
IMAGE_FSTYPES = "tar.bz2 ext4 wic.bz2"
IMAGE_ROOTFS_EXTRA_SPACE = "524288"