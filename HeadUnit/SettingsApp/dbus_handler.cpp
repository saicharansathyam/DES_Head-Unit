#include "dbus_handler.h"
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDebug>

DBusHandler::DBusHandler(QObject *parent)
    : QObject(parent)
    , m_serviceInterface(nullptr)
    , m_serviceConnected(false)
    , m_systemVolume(50)
    , m_currentTime("")
    , m_timezone("Unknown")
{
    setupDBusConnection();
}

DBusHandler::~DBusHandler()
{
    if (m_serviceInterface) {
        delete m_serviceInterface;
    }
}

void DBusHandler::setupDBusConnection()
{
    QDBusConnection sessionBus = QDBusConnection::sessionBus();

    if (!sessionBus.isConnected()) {
        qWarning() << "Cannot connect to D-Bus session bus";
        return;
    }

    m_serviceInterface = new QDBusInterface(
        "com.headunit.SettingsService",
        "/com/headunit/Settings",
        "com.headunit.Settings",
        sessionBus,
        this
        );

    if (m_serviceInterface->isValid()) {
        m_serviceConnected = true;
        emit serviceConnectedChanged();
        qDebug() << "Connected to Settings service";

        // Connect to signals
        sessionBus.connect("com.headunit.SettingsService",
                           "/com/headunit/Settings",
                           "com.headunit.Settings",
                           "WiFiConnected",
                           this, SLOT(handleWiFiConnected(QString)));

        sessionBus.connect("com.headunit.SettingsService",
                           "/com/headunit/Settings",
                           "com.headunit.Settings",
                           "WiFiDisconnected",
                           this, SLOT(handleWiFiDisconnected()));

        sessionBus.connect("com.headunit.SettingsService",
                           "/com/headunit/Settings",
                           "com.headunit.Settings",
                           "BluetoothDevicePaired",
                           this, SLOT(handleBluetoothDevicePaired(QString)));

        sessionBus.connect("com.headunit.SettingsService",
                           "/com/headunit/Settings",
                           "com.headunit.Settings",
                           "BluetoothDeviceConnected",
                           this, SLOT(handleBluetoothDeviceConnected(QString)));

        sessionBus.connect("com.headunit.SettingsService",
                           "/com/headunit/Settings",
                           "com.headunit.Settings",
                           "BluetoothDevicesChanged",
                           this, SLOT(handleBluetoothDevicesChanged(QStringList)));

        sessionBus.connect("com.headunit.SettingsService",
                           "/com/headunit/Settings",
                           "com.headunit.Settings",
                           "SystemVolumeChanged",
                           this, SLOT(handleVolumeChanged(int)));

        sessionBus.connect("com.headunit.SettingsService",
                           "/com/headunit/Settings",
                           "com.headunit.Settings",
                           "SystemTimeChanged",
                           this, SLOT(handleTimeChanged(QString)));

        sessionBus.connect("com.headunit.SettingsService",
                           "/com/headunit/Settings",
                           "com.headunit.Settings",
                           "TimeZoneChanged",
                           this, SLOT(handleTimezoneChanged(QString)));

        // Refresh initial values
        refreshVolume();
        refreshTime();
        refreshTimezone();
    } else {
        qWarning() << "Settings service not available:" << m_serviceInterface->lastError().message();
    }
}

// WiFi Methods
void DBusHandler::scanWiFi()
{
    if (!m_serviceConnected) return;

    QDBusReply<QStringList> reply = m_serviceInterface->call("ScanWiFiNetworks");
    if (reply.isValid()) {
        emit wifiNetworksFound(reply.value());
        qDebug() << "WiFi networks found:" << reply.value().size();
    }
}

bool DBusHandler::connectToWiFi(const QString &ssid, const QString &password)
{
    if (!m_serviceConnected) return false;

    QDBusReply<bool> reply = m_serviceInterface->call("ConnectToWiFi", ssid, password);
    return reply.isValid() && reply.value();
}

void DBusHandler::disconnectWiFi()
{
    if (!m_serviceConnected) return;
    m_serviceInterface->call(QDBus::NoBlock, "DisconnectWiFi");
}

QString DBusHandler::getCurrentWiFi()
{
    if (!m_serviceConnected) return "Not connected";

    QDBusReply<QString> reply = m_serviceInterface->call("GetCurrentWiFi");
    return reply.isValid() ? reply.value() : "Error";
}

// Bluetooth Methods
void DBusHandler::setBluetoothEnabled(bool enabled)
{
    if (!m_serviceConnected) return;
    m_serviceInterface->call(QDBus::NoBlock, "SetBluetoothEnabled", enabled);
    qDebug() << "Bluetooth set to:" << enabled;
}

void DBusHandler::scanBluetooth()
{
    if (!m_serviceConnected) return;

    // Clear existing devices
    m_bluetoothDevices.clear();
    emit bluetoothDevicesChanged();

    m_serviceInterface->call(QDBus::NoBlock, "ScanBluetoothDevices");
    qDebug() << "Bluetooth scan started";
}

bool DBusHandler::pairDevice(const QString &address)
{
    if (!m_serviceConnected) return false;

    QDBusReply<bool> reply = m_serviceInterface->call("PairBluetoothDevice", address);
    bool success = reply.isValid() && reply.value();
    qDebug() << "Pair device" << address << "result:" << success;
    return success;
}

bool DBusHandler::connectDevice(const QString &address)
{
    if (!m_serviceConnected) return false;

    QDBusReply<bool> reply = m_serviceInterface->call("ConnectBluetoothDevice", address);
    bool success = reply.isValid() && reply.value();
    qDebug() << "Connect device" << address << "result:" << success;
    return success;
}

// Sound Methods
void DBusHandler::setSystemVolume(int volume)
{
    if (!m_serviceConnected) return;

    m_systemVolume = qBound(0, volume, 100);
    m_serviceInterface->call(QDBus::NoBlock, "SetSystemVolume", m_systemVolume);
    emit systemVolumeChanged();
}

void DBusHandler::refreshVolume()
{
    if (!m_serviceConnected) return;

    QDBusReply<int> reply = m_serviceInterface->call("GetSystemVolume");
    if (reply.isValid()) {
        m_systemVolume = reply.value();
        emit systemVolumeChanged();
    }
}

// Clock Methods
void DBusHandler::refreshTime()
{
    if (!m_serviceConnected) return;

    QDBusReply<QString> reply = m_serviceInterface->call("GetCurrentTime");
    if (reply.isValid()) {
        m_currentTime = reply.value();
        emit currentTimeChanged();
    }
}

void DBusHandler::refreshTimezone()
{
    if (!m_serviceConnected) return;

    QDBusReply<QString> reply = m_serviceInterface->call("GetTimeZone");
    if (reply.isValid()) {
        m_timezone = reply.value();
        emit timezoneChanged();
    }
}

bool DBusHandler::setSystemTime(int year, int month, int day, int hour, int minute, int second)
{
    if (!m_serviceConnected) return false;

    QDBusReply<bool> reply = m_serviceInterface->call("SetSystemTime",
                                                      year, month, day, hour, minute, second);

    if (reply.isValid() && reply.value()) {
        refreshTime();
        return true;
    }
    return false;
}

bool DBusHandler::setTimezone(const QString &tz)
{
    if (!m_serviceConnected) return false;

    QDBusReply<bool> reply = m_serviceInterface->call("SetTimeZone", tz);
    return reply.isValid() && reply.value();
}

void DBusHandler::setNTPEnabled(bool enabled)
{
    if (!m_serviceConnected) return;
    m_serviceInterface->call(QDBus::NoBlock, "SetNTPEnabled", enabled);
}

// Signal Handlers
void DBusHandler::handleWiFiConnected(const QString &ssid)
{
    emit wifiConnected(ssid);
    qDebug() << "WiFi connected:" << ssid;
}

void DBusHandler::handleWiFiDisconnected()
{
    emit wifiDisconnected();
    qDebug() << "WiFi disconnected";
}

void DBusHandler::handleBluetoothDevicePaired(const QString &address)
{
    emit bluetoothDevicePaired(address);
    qDebug() << "Device paired:" << address;
}

void DBusHandler::handleBluetoothDeviceConnected(const QString &address)
{
    emit bluetoothDeviceConnected(address);
    qDebug() << "Device connected:" << address;
}

void DBusHandler::handleBluetoothDevicesChanged(const QStringList &devices)
{
    m_bluetoothDevices.clear();

    qDebug() << "Received" << devices.size() << "Bluetooth devices";

    // Parse device strings: "name|address|paired|connected|rssi"
    for (const QString &deviceStr : devices) {
        QStringList parts = deviceStr.split('|');
        if (parts.size() >= 5) {
            QVariantMap device;
            device["name"] = parts[0];
            device["address"] = parts[1];
            device["paired"] = (parts[2] == "True" || parts[2] == "true" || parts[2] == "1");
            device["connected"] = (parts[3] == "True" || parts[3] == "true" || parts[3] == "1");
            device["rssi"] = parts[4].toInt();

            m_bluetoothDevices.append(device);
            qDebug() << "Parsed device:" << device["name"] << device["address"];
        }
    }

    emit bluetoothDevicesChanged();
    qDebug() << "Total devices parsed:" << m_bluetoothDevices.size();
}

void DBusHandler::handleVolumeChanged(int volume)
{
    m_systemVolume = volume;
    emit systemVolumeChanged();
}

void DBusHandler::handleTimeChanged(const QString &time)
{
    m_currentTime = time;
    emit currentTimeChanged();
}

void DBusHandler::handleTimezoneChanged(const QString &tz)
{
    m_timezone = tz;
    emit timezoneChanged();
}
