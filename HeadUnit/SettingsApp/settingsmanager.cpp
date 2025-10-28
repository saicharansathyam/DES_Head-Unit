#include "settingsmanager.h"
#include "wifimanager.h"
#include "bluetoothmanager.h"
#include <QSettings>
#include <QDebug>

SettingsManager::SettingsManager(WiFiManager *wifi, BluetoothManager *bluetooth, QObject *parent)
    : QObject(parent)
    , m_currentContext("wifi")
    , m_systemVolume(50)
    , m_wifiManager(wifi)
    , m_bluetoothManager(bluetooth)
{
    loadSettings();
    qDebug() << "SettingsManager initialized";
}

void SettingsManager::setCurrentContext(const QString &context)
{
    if (m_currentContext != context) {
        m_currentContext = context;
        emit currentContextChanged();
        qDebug() << "Context switched to:" << context;
    }
}

void SettingsManager::setSystemVolume(int volume)
{
    int clampedVolume = qBound(0, volume, 100);
    if (m_systemVolume != clampedVolume) {
        m_systemVolume = clampedVolume;
        emit systemVolumeChanged();
        saveSettings();

        // Update MediaPlayer service volume via DBus
        // This will be handled in the extended Python service
        qDebug() << "System volume set to:" << m_systemVolume;
    }
}

void SettingsManager::switchContext(const QString &context)
{
    if (context == "wifi" || context == "bluetooth" || context == "sound") {
        setCurrentContext(context);
    } else {
        qWarning() << "Invalid context:" << context;
    }
}

void SettingsManager::saveSettings()
{
    QSettings settings("HeadUnit", "Settings");
    settings.setValue("systemVolume", m_systemVolume);
    settings.sync();
}

void SettingsManager::loadSettings()
{
    QSettings settings("HeadUnit", "Settings");
    m_systemVolume = settings.value("systemVolume", 50).toInt();
    emit systemVolumeChanged();
}

