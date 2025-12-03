SUMMARY = "Head Unit Core Package Group"
DESCRIPTION = "Essential packages for Head Unit IVI system"
LICENSE = "MIT"

inherit packagegroup

RDEPENDS:${PN} = " \
    packagegroup-headunit-qt6 \
    packagegroup-headunit-apps \
    packagegroup-headunit-system \
"

RDEPENDS:packagegroup-headunit-qt6 = " \
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
    qtwebview \
    qtvirtualkeyboard \
    qtbluetooth \
"

RDEPENDS:packagegroup-headunit-apps = " \
    application-framework-manager \
    ivi-compositor \
    homepage \
    gearselector \
    mediaplayer \
    themecolor \
    settings \
    mock-dbus \
"

RDEPENDS:packagegroup-headunit-system = " \
    dbus \
    dbus-session \
    dbus-glib \
    python3 \
    python3-core \
    python3-dbus \
    python3-pygobject \
    systemd \
    openssh \
    openssh-sshd \
"
