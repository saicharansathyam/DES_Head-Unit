SUMMARY = "HeadUnit IVI System Image"
DESCRIPTION = "Custom Linux image for automotive IVI system with Qt6 and Wayland"

IMAGE_FEATURES += "splash"

LICENSE = "MIT"

inherit core-image

# CRITICAL FIX: Remove glib-networking to prevent GIO module cache intercept
# This package triggers the update_gio_module_cache hook that fails in Docker
PACKAGE_EXCLUDE += "glib-networking"

IMAGE_INSTALL:append = " \
    packagegroup-core-boot \
    qtbase \
    qtdeclarative \
    qtwayland \
    qtwayland-plugins \
    qtvirtualkeyboard \
    qtbase-plugins \
    wayland \
    application-framework-manager \
    weston \
    weston-init \
    weston-examples \
    ivi-compositor \
    mock-dbus \
    gearselector \
    mediaplayer \
    themecolor \
    instrument-cluster \
    can-setup \
    rc-piracer \
    headunit-startup \
    python3 \
    python3-dbus \
    python3-pygobject \
    python3-numpy \
    python3-can \
    python3-pyserial \
    python3-smbus \
    python3-piracer-py \
    python3-evdev \
    can-utils \
    kernel-module-can \
    kernel-module-can-dev \
    kernel-module-can-raw \
    kernel-module-mcp251x \
    kernel-module-mcp251xfd \
    adafruit-blinka \
    adafruit-platformdetect \
    adafruit-pureio \
    adafruit-circuitpython-busdevice \
    adafruit-circuitpython-register \
    adafruit-circuitpython-ina219 \
    libgpiod \
    i2c-tools \
    systemd \
    dbus \
    bluez5 \
    pulseaudio \
    alsa-utils \
    kernel-modules \
    sudo \
    nano \
    linux-firmware \
    connman \
    connman-client \
    connman-provision \
    openssh \
    openssh-sshd \
    openssh-scp \
    openssh-ssh \
    fontconfig \
    systemd-autologin \
    systemd-tmpfiles \
    packagegroup-headunit-fonts \
    packagegroup-headunit-qt6 \
    udev-extraconf \
    dbus-session \
    boot-animation \
    gstreamer1.0 \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
"

IMAGE_LINGUAS = "en-us"

# Enable WIC image generation for proper SD card flashing
IMAGE_FSTYPES += "wic.bz2 wic.bmap"

# Remove overlays directory before WIC image creation to prevent copy errors
do_image_wic[prefuncs] += "remove_overlays_dir"

python remove_overlays_dir() {
    import os
    import shutil

    deploy_dir = d.getVar('DEPLOY_DIR_IMAGE')
    overlays_dir = os.path.join(deploy_dir, 'bootfiles', 'overlays')

    if os.path.exists(overlays_dir):
        bb.note(f"Removing {overlays_dir} to prevent WIC copy issues")
        shutil.rmtree(overlays_dir)
}

DISTRO_FEATURES:append = " systemd wayland wifi bluetooth alsa pulseaudio touchscreen dbus opengl ivi-shell"
DISTRO_FEATURES_BACKFILL_CONSIDERED = "sysvinit"
VIRTUAL-RUNTIME_init_manager = "systemd"
VIRTUAL-RUNTIME_initscripts = ""

PACKAGECONFIG:append:pn-qtbase = " eglfs gbm kms fontconfig dbus"
PACKAGECONFIG:append:pn-systemd = " networkd resolved"

IMAGE_ROOTFS_EXTRA_SPACE = "2048"

# Set default systemd target to graphical (ensures compositor starts)
SYSTEMD_DEFAULT_TARGET = "graphical.target"

# Disable getty on tty1 to prevent terminal flash during boot
SYSTEMD_MASK:${PN} = "getty@tty1.service"


