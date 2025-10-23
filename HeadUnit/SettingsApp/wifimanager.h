#ifndef WIFIMANAGER_H
#define WIFIMANAGER_H

#include <QObject>
#include <QDBusInterface>
#include <QDBusConnection>
#include <QVariantMap>

class WiFiManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString currentNetwork READ currentNetwork NOTIFY currentNetworkChanged)
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY isConnectedChanged)
    Q_PROPERTY(QVariantList availableNetworks READ availableNetworks NOTIFY availableNetworksChanged)

public:
    explicit WiFiManager(QObject *parent = nullptr);
    ~WiFiManager();

    QString currentNetwork() const { return m_currentNetwork; }
    bool isConnected() const { return m_isConnected; }
    QVariantList availableNetworks() const { return m_availableNetworks; }

    Q_INVOKABLE void scanNetworks();
    Q_INVOKABLE void connectToNetwork(const QString &ssid, const QString &password);
    Q_INVOKABLE void disconnectNetwork();
    Q_INVOKABLE void refreshStatus();

signals:
    void currentNetworkChanged();
    void isConnectedChanged();
    void availableNetworksChanged();
    void connectionSuccess(const QString &ssid);
    void connectionFailed(const QString &error);
    void scanCompleted();

private slots:
    void handleScanResults();
    void handleConnectionStateChanged();

private:
    QDBusInterface *m_nmInterface;
    QDBusConnection m_systemBus;
    QString m_currentNetwork;
    bool m_isConnected;
    QVariantList m_availableNetworks;

    void initializeNetworkManager();
    void updateConnectionState();
    QVariantList parseAccessPoints();
};

#endif // WIFIMANAGER_H

