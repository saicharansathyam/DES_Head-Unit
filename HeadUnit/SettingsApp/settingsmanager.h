#ifndef SETTINGSMANAGER_H
#define SETTINGSMANAGER_H

#include <QObject>
#include <QString>

class WiFiManager;
class BluetoothManager;

class SettingsManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString currentContext READ currentContext WRITE setCurrentContext NOTIFY currentContextChanged)
    Q_PROPERTY(int systemVolume READ systemVolume WRITE setSystemVolume NOTIFY systemVolumeChanged)

public:
    explicit SettingsManager(WiFiManager *wifi, BluetoothManager *bluetooth, QObject *parent = nullptr);

    QString currentContext() const { return m_currentContext; }
    void setCurrentContext(const QString &context);

    int systemVolume() const { return m_systemVolume; }
    void setSystemVolume(int volume);

    Q_INVOKABLE void switchContext(const QString &context);

signals:
    void currentContextChanged();
    void systemVolumeChanged();

private:
    QString m_currentContext;
    int m_systemVolume;
    WiFiManager *m_wifiManager;
    BluetoothManager *m_bluetoothManager;

    void saveSettings();
    void loadSettings();
};

#endif // SETTINGSMANAGER_H

