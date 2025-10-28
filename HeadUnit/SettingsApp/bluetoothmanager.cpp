#include "bluetoothmanager.h"
#include <QDebug>

BluetoothManager::BluetoothManager(QObject *parent)
    : QObject(parent)
    , m_localDevice(nullptr)
    , m_discoveryAgent(nullptr)
    , m_isEnabled(false)
    , m_isScanning(false)
{
    initializeBluetooth();
}

BluetoothManager::~BluetoothManager()
{
    if (m_discoveryAgent) {
        m_discoveryAgent->stop();
        delete m_discoveryAgent;
    }
    delete m_localDevice;
}

void BluetoothManager::initializeBluetooth()
{
    m_localDevice = new QBluetoothLocalDevice(this);

    if (m_localDevice->isValid()) {
        m_isEnabled = (m_localDevice->hostMode() != QBluetoothLocalDevice::HostPoweredOff);

        connect(m_localDevice, &QBluetoothLocalDevice::pairingFinished,
                this, &BluetoothManager::handlePairingFinished);

        // Initialize discovery agent
        m_discoveryAgent = new QBluetoothDeviceDiscoveryAgent(this);

        connect(m_discoveryAgent, &QBluetoothDeviceDiscoveryAgent::deviceDiscovered,
                this, &BluetoothManager::handleDeviceDiscovered);
        connect(m_discoveryAgent, &QBluetoothDeviceDiscoveryAgent::finished,
                this, &BluetoothManager::handleDiscoveryFinished);
        // FIXED: Use errorOccurred instead of error
        connect(m_discoveryAgent, &QBluetoothDeviceDiscoveryAgent::errorOccurred,
                this, &BluetoothManager::handleDiscoveryError);

        updatePairedDevices();

        qDebug() << "Bluetooth initialized successfully";
    } else {
        qWarning() << "No valid Bluetooth adapter found";
    }

    emit isEnabledChanged();
}


void BluetoothManager::setEnabled(bool enabled)
{
    if (!m_localDevice || !m_localDevice->isValid()) {
        qWarning() << "Bluetooth device not available";
        return;
    }

    if (enabled) {
        m_localDevice->powerOn();
        m_localDevice->setHostMode(QBluetoothLocalDevice::HostDiscoverable);
    } else {
        if (m_isScanning) {
            stopScan();
        }
        m_localDevice->setHostMode(QBluetoothLocalDevice::HostPoweredOff);
    }

    m_isEnabled = enabled;
    emit isEnabledChanged();
    qDebug() << "Bluetooth" << (enabled ? "enabled" : "disabled");
}

void BluetoothManager::startScan()
{
    if (!m_isEnabled) {
        qWarning() << "Bluetooth is not enabled";
        return;
    }

    if (!m_discoveryAgent) {
        qWarning() << "Discovery agent not available";
        return;
    }

    if (m_isScanning) {
        qDebug() << "Already scanning";
        return;
    }

    m_availableDevices.clear();
    emit availableDevicesChanged();

    m_discoveryAgent->start();
    m_isScanning = true;
    emit isScanningChanged();

    qDebug() << "Bluetooth scan started";
}

void BluetoothManager::stopScan()
{
    if (m_discoveryAgent && m_isScanning) {
        m_discoveryAgent->stop();
        m_isScanning = false;
        emit isScanningChanged();
        qDebug() << "Bluetooth scan stopped";
    }
}

void BluetoothManager::pairDevice(const QString &address)
{
    if (!m_localDevice || !m_localDevice->isValid()) {
        emit devicePairingFailed("Bluetooth not available");
        return;
    }

    QBluetoothAddress btAddress(address);
    m_localDevice->requestPairing(btAddress, QBluetoothLocalDevice::Paired);

    qDebug() << "Pairing requested for:" << address;
}

void BluetoothManager::unpairDevice(const QString &address)
{
    if (!m_localDevice || !m_localDevice->isValid()) {
        return;
    }

    QBluetoothAddress btAddress(address);
    m_localDevice->requestPairing(btAddress, QBluetoothLocalDevice::Unpaired);

    qDebug() << "Unpairing requested for:" << address;
}

void BluetoothManager::connectDevice(const QString &address)
{
    // Connection logic - would typically involve Bluetooth profiles
    // For MediaPlayer, this would use Bluetooth Audio profile (A2DP)
    qDebug() << "Connecting to device:" << address;

    m_connectedDevice = address;
    emit connectedDeviceChanged();
}

void BluetoothManager::disconnectDevice(const QString &address)
{
    qDebug() << "Disconnecting from device:" << address;

    m_connectedDevice = "";
    emit connectedDeviceChanged();
}

void BluetoothManager::handleDeviceDiscovered(const QBluetoothDeviceInfo &device)
{
    QVariantMap deviceMap = deviceInfoToMap(device);

    // Check if device already in list
    bool found = false;
    for (const QVariant &var : m_availableDevices) {
        QVariantMap existing = var.toMap();
        if (existing["address"].toString() == deviceMap["address"].toString()) {
            found = true;
            break;
        }
    }

    if (!found) {
        m_availableDevices.append(deviceMap);
        emit availableDevicesChanged();
        qDebug() << "Discovered device:" << device.name() << device.address().toString();
    }
}

void BluetoothManager::handleDiscoveryFinished()
{
    m_isScanning = false;
    emit isScanningChanged();
    emit scanCompleted();
    qDebug() << "Bluetooth scan completed. Found" << m_availableDevices.size() << "devices";
}

void BluetoothManager::handleDiscoveryError(QBluetoothDeviceDiscoveryAgent::Error error)
{
    qWarning() << "Bluetooth discovery error:" << error;
    m_isScanning = false;
    emit isScanningChanged();
}

void BluetoothManager::handlePairingFinished(const QBluetoothAddress &address,
                                             QBluetoothLocalDevice::Pairing pairing)
{
    if (pairing == QBluetoothLocalDevice::Paired) {
        qDebug() << "Device paired successfully:" << address.toString();
        updatePairedDevices();
        emit devicePaired(address.toString());
    } else {
        qWarning() << "Device pairing failed:" << address.toString();
        emit devicePairingFailed("Pairing failed");
    }
}

void BluetoothManager::updatePairedDevices()
{
    m_pairedDevices.clear();

    if (m_localDevice && m_localDevice->isValid()) {
        QList<QBluetoothAddress> pairedAddresses = m_localDevice->connectedDevices();

        for (const QBluetoothAddress &address : pairedAddresses) {
            QVariantMap device;
            device["address"] = address.toString();
            device["name"] = m_localDevice->pairingStatus(address) == QBluetoothLocalDevice::Paired
                                 ? "Paired Device" : "Unknown";
            m_pairedDevices.append(device);
        }
    }

    emit pairedDevicesChanged();
}

QVariantMap BluetoothManager::deviceInfoToMap(const QBluetoothDeviceInfo &device)
{
    QVariantMap map;
    map["name"] = device.name().isEmpty() ? "Unknown Device" : device.name();
    map["address"] = device.address().toString();
    map["rssi"] = device.rssi();
    map["majorDeviceClass"] = device.majorDeviceClass();
    map["minorDeviceClass"] = device.minorDeviceClass();
    return map;
}

