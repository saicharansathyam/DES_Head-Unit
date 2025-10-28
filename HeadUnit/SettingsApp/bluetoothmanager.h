#ifndef BLUETOOTHMANAGER_H
#define BLUETOOTHMANAGER_H

#include <QObject>
#include <QBluetoothDeviceDiscoveryAgent>
#include <QBluetoothLocalDevice>
#include <QBluetoothDeviceInfo>
#include <QVariantList>

class BluetoothManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isEnabled READ isEnabled NOTIFY isEnabledChanged)
    Q_PROPERTY(bool isScanning READ isScanning NOTIFY isScanningChanged)
    Q_PROPERTY(QVariantList pairedDevices READ pairedDevices NOTIFY pairedDevicesChanged)
    Q_PROPERTY(QVariantList availableDevices READ availableDevices NOTIFY availableDevicesChanged)
    Q_PROPERTY(QString connectedDevice READ connectedDevice NOTIFY connectedDeviceChanged)

public:
    explicit BluetoothManager(QObject *parent = nullptr);
    ~BluetoothManager();

    bool isEnabled() const { return m_isEnabled; }
    bool isScanning() const { return m_isScanning; }
    QVariantList pairedDevices() const { return m_pairedDevices; }
    QVariantList availableDevices() const { return m_availableDevices; }
    QString connectedDevice() const { return m_connectedDevice; }

    Q_INVOKABLE void setEnabled(bool enabled);
    Q_INVOKABLE void startScan();
    Q_INVOKABLE void stopScan();
    Q_INVOKABLE void pairDevice(const QString &address);
    Q_INVOKABLE void unpairDevice(const QString &address);
    Q_INVOKABLE void connectDevice(const QString &address);
    Q_INVOKABLE void disconnectDevice(const QString &address);

signals:
    void isEnabledChanged();
    void isScanningChanged();
    void pairedDevicesChanged();
    void availableDevicesChanged();
    void connectedDeviceChanged();
    void devicePaired(const QString &name);
    void devicePairingFailed(const QString &error);
    void scanCompleted();

private slots:
    void handleDeviceDiscovered(const QBluetoothDeviceInfo &device);
    void handleDiscoveryFinished();
    void handleDiscoveryError(QBluetoothDeviceDiscoveryAgent::Error error);
    void handlePairingFinished(const QBluetoothAddress &address,
                               QBluetoothLocalDevice::Pairing pairing);

private:
    QBluetoothLocalDevice *m_localDevice;
    QBluetoothDeviceDiscoveryAgent *m_discoveryAgent;
    bool m_isEnabled;
    bool m_isScanning;
    QVariantList m_pairedDevices;
    QVariantList m_availableDevices;
    QString m_connectedDevice;

    void initializeBluetooth();
    void updatePairedDevices();
    QVariantMap deviceInfoToMap(const QBluetoothDeviceInfo &device);
};

#endif // BLUETOOTHMANAGER_H

