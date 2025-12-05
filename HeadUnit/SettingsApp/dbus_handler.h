#ifndef DBUSHANDLER_H
#define DBUSHANDLER_H

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QtDBus/QDBusConnection>
#include <QtDBus/QDBusInterface>
#include <QtDBus/QDBusReply>

class DBusHandler : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool serviceConnected READ serviceConnected NOTIFY serviceConnectedChanged)
    Q_PROPERTY(int systemVolume READ systemVolume WRITE setSystemVolume NOTIFY systemVolumeChanged)
    Q_PROPERTY(QString currentTime READ currentTime NOTIFY currentTimeChanged)
    Q_PROPERTY(QString timezone READ timezone NOTIFY timezoneChanged)
    Q_PROPERTY(QVariantList bluetoothDevices READ bluetoothDevices NOTIFY bluetoothDevicesChanged)

public:
    explicit DBusHandler(QObject *parent = nullptr);
    ~DBusHandler();

    bool serviceConnected() const { return m_serviceConnected; }
    int systemVolume() const { return m_systemVolume; }
    QString currentTime() const { return m_currentTime; }
    QString timezone() const { return m_timezone; }
    QVariantList bluetoothDevices() const { return m_bluetoothDevices; }

    // WiFi methods
    Q_INVOKABLE void scanWiFi();
    Q_INVOKABLE bool connectToWiFi(const QString &ssid, const QString &password);
    Q_INVOKABLE void disconnectWiFi();
    Q_INVOKABLE QString getCurrentWiFi();

    // Bluetooth methods
    Q_INVOKABLE void setBluetoothEnabled(bool enabled);
    Q_INVOKABLE void scanBluetooth();
    Q_INVOKABLE bool pairDevice(const QString &address);
    Q_INVOKABLE bool connectDevice(const QString &address);

    // Sound methods
    void setSystemVolume(int volume);
    Q_INVOKABLE void refreshVolume();

    // Clock methods
    Q_INVOKABLE void refreshTime();
    Q_INVOKABLE void refreshTimezone();
    Q_INVOKABLE bool setSystemTime(int year, int month, int day, int hour, int minute, int second);
    Q_INVOKABLE bool setTimezone(const QString &tz);
    Q_INVOKABLE void setNTPEnabled(bool enabled);

signals:
    void serviceConnectedChanged();
    void systemVolumeChanged();
    void currentTimeChanged();
    void timezoneChanged();
    void bluetoothDevicesChanged();

    void wifiNetworksFound(const QStringList &networks);
    void wifiConnected(const QString &ssid);
    void wifiDisconnected();

    void bluetoothDevicePaired(const QString &address);
    void bluetoothDeviceConnected(const QString &address);

private slots:
    void handleWiFiConnected(const QString &ssid);
    void handleWiFiDisconnected();
    void handleBluetoothDevicePaired(const QString &address);
    void handleBluetoothDeviceConnected(const QString &address);
    void handleBluetoothDevicesChanged(const QStringList &devices);
    void handleVolumeChanged(int volume);
    void handleTimeChanged(const QString &time);
    void handleTimezoneChanged(const QString &tz);

private:
    QDBusInterface *m_serviceInterface;
    bool m_serviceConnected;
    int m_systemVolume;
    QString m_currentTime;
    QString m_timezone;
    QVariantList m_bluetoothDevices;

    void setupDBusConnection();
};

#endif // DBUSHANDLER_H
