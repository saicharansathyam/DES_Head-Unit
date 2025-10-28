require recipes-core/images/core-image-base.bb

SUMMARY = "HeadUnit Custom Linux Image - Complete"
DESCRIPTION = "Full-featured IVI system with fonts, touch, and D-Bus mock service"
LICENSE = "MIT"

# ====================================
# Qt6 packages
# ====================================
IMAGE_INSTALL:append = " \
    qtbase \
    qtbase-plugins \
    qtbase-tools \
    qtdeclarative \
    qtdeclarative-plugins \
    qtdeclarative-tools \
    qtwayland \
    qtwayland-plugins \
    qtmultimedia \
    qtmultimedia-plugins \
    qtsvg \
"

# ====================================
# HeadUnit applications
# ====================================
IMAGE_INSTALL:append = " \
    ivi-compositor \
    gearselector \
    mediaplayer \
    themecolor \
    mock-dbus \
"

# ====================================
# Fonts (CRITICAL for text rendering)
# ====================================
IMAGE_INSTALL:append = " \
    fontconfig \
    fontconfig-utils \
    liberation-fonts \
    ttf-dejavu-common \
    ttf-dejavu-sans \
    ttf-dejavu-sans-mono \
    ttf-dejavu-serif \
"

# ====================================
# Touch input support
# ====================================
IMAGE_INSTALL:append = " \
    libinput \
    libinput-bin \
    evtest \
    tslib \
    tslib-calibrate \
    tslib-tests \
"

# ====================================
# Python for Mock D-Bus Service
# ====================================
IMAGE_INSTALL:append = " \
    python3 \
    python3-core \
    python3-dbus \
    python3-pygobject \
"

# ====================================
# D-Bus and system services
# ====================================
IMAGE_INSTALL:append = " \
    dbus \
    dbus-glib \
"

# ====================================
# System utilities
# ====================================
IMAGE_INSTALL:append = " \
    openssh \
    openssh-sshd \
    openssh-sftp-server \
    util-linux \
    procps \
    nano \
    vim \
"

# ====================================
# Graphics and DRM
# ====================================
IMAGE_INSTALL:append = " \
    mesa \
    mesa-megadriver \
    libdrm \
    libdrm-tests \
"

# Enable features
IMAGE_FEATURES += "ssh-server-openssh"
EXTRA_IMAGE_FEATURES += "debug-tweaks"

# Ensure Qt fontconfig support
PACKAGECONFIG:append:pn-qtbase = " fontconfig"

# Touch screen support
DISTRO_FEATURES:append = " touchscreen"
