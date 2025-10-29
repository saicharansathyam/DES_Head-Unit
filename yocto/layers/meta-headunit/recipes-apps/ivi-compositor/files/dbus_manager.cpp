// dbus_manager.cpp
#include "dbus_manager.h"
#include <QDBusReply>
#include <QDBusError>

DBusManager::DBusManager(QObject *parent)
    : QObject(parent)
    , m_sessionBus(QDBusConnection::sessionBus())
    , m_afmInterface(nullptr)
    , m_wmInterface(nullptr)
    , m_afmConnected(false)
{
    setupAFMConnection();
    setupWindowManagerConnection();
}

DBusManager::~DBusManager()
{
    delete m_afmInterface;
    delete m_wmInterface;
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

