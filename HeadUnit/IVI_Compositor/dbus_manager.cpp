// dbus_manager.cpp
#include "dbus_manager.h"
#include <QDBusReply>
#include <QDBusError>

DBusManager::DBusManager(QObject *parent)
    : QObject(parent)
    , m_sessionBus(QDBusConnection::sessionBus())
    , m_afmInterface(nullptr)
    , m_wmInterface(nullptr)
    , m_settingsInterface(nullptr)
    , m_afmConnected(false)
    , m_systemVolume(50)
{
    setupAFMConnection();
    setupWindowManagerConnection();
    setupSettingsConnection();
}

DBusManager::~DBusManager()
{
    delete m_afmInterface;
    delete m_wmInterface;
    delete m_settingsInterface;
}

void DBusManager::setupAFMConnection()
{
    // Create interface to AFM
    m_afmInterface = new QDBusInterface(
        "com.headunit.AppLifecycle",
        "/com/headunit/AppLifecycle",
        "com.headunit.AppLifecycle",
        m_sessionBus,
        this
        );

    if (!m_afmInterface->isValid()) {
        qWarning() << "[DBusManager] AFM interface not valid:"
                   << m_sessionBus.lastError().message();
        qWarning() << "[DBusManager] AFM may not be running yet";
        m_afmConnected = false;
        emit afmConnectionChanged();
        return;
    }

    m_afmConnected = true;
    emit afmConnectionChanged();

    // Subscribe to AFM signals
    bool connected = m_sessionBus.connect(
        "com.headunit.AppLifecycle",
        "/com/headunit/AppLifecycle",
        "com.headunit.AppLifecycle",
        "StateChanged",
        this,
        SLOT(onAFMStateChanged(int, QString))
        );

    if (!connected) {
        qWarning() << "[DBusManager] Failed to connect to StateChanged signal";
    }

    m_sessionBus.connect(
        "com.headunit.AppLifecycle",
        "/com/headunit/AppLifecycle",
        "com.headunit.AppLifecycle",
        "AppLaunched",
        this,
        SLOT(onAFMAppLaunched(int, int))
        );

    m_sessionBus.connect(
        "com.headunit.AppLifecycle",
        "/com/headunit/AppLifecycle",
        "com.headunit.AppLifecycle",
        "AppTerminated",
        this,
        SLOT(onAFMAppTerminated(int))
        );

    qInfo() << "[DBusManager] Connected to AFM D-Bus interface";
}

void DBusManager::setupWindowManagerConnection()
{
    m_wmInterface = new QDBusInterface(
        "com.headunit.WindowManager",
        "/com/headunit/WindowManager",
        "com.headunit.WindowManager",
        m_sessionBus,
        this
        );

    if (!m_wmInterface->isValid()) {
        qWarning() << "[DBusManager] WindowManager not available (optional)";
    } else {
        qInfo() << "[DBusManager] Connected to WindowManager D-Bus interface";
    }
}

void DBusManager::setupSettingsConnection()
{
    m_settingsInterface = new QDBusInterface(
        "com.headunit.SettingsService",
        "/com/headunit/Settings",
        "com.headunit.Settings",
        m_sessionBus,
        this
        );

    if (!m_settingsInterface->isValid()) {
        qWarning() << "[DBusManager] SettingsService not available:" 
                   << m_sessionBus.lastError().message();
    } else {
        qInfo() << "[DBusManager] Connected to SettingsService D-Bus interface";
        
        // Connect to volume change signals
        m_sessionBus.connect(
            "com.headunit.SettingsService",
            "/com/headunit/Settings",
            "com.headunit.Settings",
            "SystemVolumeChanged",
            this,
            SLOT(onSystemVolumeChanged(int))
            );
        
        // Get initial volume
        QDBusReply<int> reply = m_settingsInterface->call("GetSystemVolume");
        if (reply.isValid()) {
            m_systemVolume = reply.value();
        }
    }
}

void DBusManager::launchApp(int iviId)
{
    if (!m_afmInterface || !m_afmConnected) {
        qWarning() << "[DBusManager] AFM not connected, cannot launch app" << iviId;
        return;
    }

    qInfo() << "[DBusManager] Launching app via AFM:" << iviId;

    QDBusReply<void> reply = m_afmInterface->call("LaunchApp", iviId);

    if (!reply.isValid()) {
        qCritical() << "[DBusManager] Failed to launch app" << iviId
                    << ":" << reply.error().message();
    }
}

void DBusManager::activateApp(int iviId)
{
    if (!m_afmInterface || !m_afmConnected) {
        qWarning() << "[DBusManager] AFM not connected, cannot activate app" << iviId;
        return;
    }

    qInfo() << "[DBusManager] Activating app via AFM:" << iviId;

    QDBusReply<void> reply = m_afmInterface->call("ActivateApp", iviId);

    if (!reply.isValid()) {
        qWarning() << "[DBusManager] Failed to activate app" << iviId
                   << ":" << reply.error().message();
    }
}

void DBusManager::terminateApp(int iviId)
{
    if (!m_afmInterface || !m_afmConnected) {
        qWarning() << "[DBusManager] AFM not connected";
        return;
    }

    QDBusReply<void> reply = m_afmInterface->call("TerminateApp", iviId);

    if (!reply.isValid()) {
        qWarning() << "[DBusManager] Failed to terminate app:"
                   << reply.error().message();
    }
}

void DBusManager::notifyAppConnected(int iviId)
{
    if (!m_afmInterface || !m_afmConnected) {
        qWarning() << "[DBusManager] AFM not connected";
        return;
    }

    qDebug() << "[DBusManager] Notifying AFM: app connected" << iviId;

    QDBusReply<void> reply = m_afmInterface->call("AppConnected", iviId);

    if (!reply.isValid()) {
        qWarning() << "[DBusManager] AppConnected call failed:"
                   << reply.error().message();
    }
}

void DBusManager::notifyAppDisconnected(int iviId)
{
    if (!m_afmInterface || !m_afmConnected) {
        return;
    }

    qDebug() << "[DBusManager] Notifying AFM: app disconnected" << iviId;
    m_afmInterface->call(QDBus::NoBlock, "AppDisconnected", iviId);
}

QString DBusManager::getAppState(int iviId)
{
    if (!m_afmInterface || !m_afmConnected) {
        return "disconnected";
    }

    QDBusReply<QString> reply = m_afmInterface->call("GetAppState", iviId);

    if (reply.isValid()) {
        return reply.value();
    }

    return "unknown";
}

void DBusManager::onAFMStateChanged(int iviId, const QString &state)
{
    qDebug() << "[DBusManager] AFM state changed:" << iviId << "->" << state;
    emit appStateChanged(iviId, state);
}

void DBusManager::onAFMAppLaunched(int iviId, int runId)
{
    qInfo() << "[DBusManager] AFM launched app:" << iviId << "RunID:" << runId;
    emit appLaunched(iviId, runId);
}

void DBusManager::onAFMAppTerminated(int iviId)
{
    qInfo() << "[DBusManager] AFM terminated app:" << iviId;
    emit appTerminated(iviId);
}

void DBusManager::setSystemVolume(int volume)
{
    if (!m_settingsInterface || !m_settingsInterface->isValid()) {
        qWarning() << "[DBusManager] SettingsService not available for volume control";
        return;
    }
    
    volume = qBound(0, volume, 100);
    qInfo() << "[DBusManager] Setting system volume to:" << volume;
    
    QDBusReply<void> reply = m_settingsInterface->call("SetSystemVolume", volume);
    
    if (!reply.isValid()) {
        qWarning() << "[DBusManager] Failed to set volume:" << reply.error().message();
    }
}

int DBusManager::getSystemVolume()
{
    if (!m_settingsInterface || !m_settingsInterface->isValid()) {
        qWarning() << "[DBusManager] SettingsService not available for volume control";
        return m_systemVolume;
    }
    
    QDBusReply<int> reply = m_settingsInterface->call("GetSystemVolume");
    
    if (reply.isValid()) {
        m_systemVolume = reply.value();
    }
    
    return m_systemVolume;
}

void DBusManager::onSystemVolumeChanged(int volume)
{
    qDebug() << "[DBusManager] System volume changed to:" << volume;
    m_systemVolume = volume;
    emit systemVolumeChanged(volume);
}

