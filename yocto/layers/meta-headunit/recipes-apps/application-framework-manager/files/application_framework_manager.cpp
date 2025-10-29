// application_framework_manager.cpp
#include "application_framework_manager.h"
#include <QDBusConnection>
#include <QDBusError>
#include <QProcessEnvironment>
#include <QDir>
#include <QFile>
#include <QTextStream>
#include <QDateTime>
#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

// ============================================================================
// ApplicationFrameworkManager Implementation
// ============================================================================

ApplicationFrameworkManager::ApplicationFrameworkManager(QObject *parent)
    : QObject(parent)
    , m_dbusAdaptor(nullptr)
    , m_watchdogTimer(nullptr)
    , m_nextRunId(1)
{
    logInfo("=== Application Framework Manager Starting ===");

    // Setup logging
    m_logFilePath = "./logs/afm.log";
    QDir().mkpath("./logs");

    // Load configuration and setup application registry
    loadConfiguration();
    setupApplicationRegistry();

    // Register D-Bus service
    registerDBusService();

    // Setup watchdog timer for process monitoring
    m_watchdogTimer = new QTimer(this);
    connect(m_watchdogTimer, &QTimer::timeout, this, &ApplicationFrameworkManager::onWatchdogTimeout);
    m_watchdogTimer->start(5000);  // Check every 5 seconds

    logInfo("=== AFM Initialization Complete ===");
}

ApplicationFrameworkManager::~ApplicationFrameworkManager()
{
    logInfo("=== Application Framework Manager Shutting Down ===");

    // Terminate all running applications
    for (auto &appInfo : m_applications) {
        if (appInfo.process && appInfo.process->state() != QProcess::NotRunning) {
            logInfo(QString("Terminating %1 (PID: %2)").arg(appInfo.name).arg(appInfo.pid));
            appInfo.process->terminate();
            if (!appInfo.process->waitForFinished(3000)) {
                appInfo.process->kill();
            }
        }
    }

    logInfo("=== AFM Shutdown Complete ===");
}

void ApplicationFrameworkManager::loadConfiguration()
{
    // In production, load from JSON config file
    // For now, using defaults
    logInfo("Loading application configuration...");
}

void ApplicationFrameworkManager::registerApplication(int iviId, const QString &name,
                                                      const QString &displayName,
                                                      const QString &binaryPath,
                                                      const QString &role)
{
    AppInfo info;
    info.iviId = iviId;
    info.name = name;
    info.displayName = displayName;
    info.binaryPath = binaryPath;
    info.role = role;
    info.process = nullptr;
    info.state = "stopped";
    info.runId = 0;
    info.pid = 0;
    info.launchTime = QDateTime();

    m_applications[iviId] = info;
}

void ApplicationFrameworkManager::setupApplicationRegistry()
{
    logInfo("Setting up application registry...");

    registerApplication(1000, "HomePage", "Home Page", "./applications/HomePage", "HomePage");
    registerApplication(1001, "GearSelector", "Gear Selector", "./applications/GearSelector", "GearSelector");
    registerApplication(1002, "MediaPlayer", "Media Player", "./applications/MediaPlayer", "MediaPlayer");
    registerApplication(1003, "ThemeColor", "Theme & Colors", "./applications/ThemeColor", "ThemeColor");
    registerApplication(1004, "Navigation", "Navigation", "./applications/Navigation", "Navigation");
    registerApplication(1005, "Settings", "Settings", "./applications/Settings", "Settings");

    logInfo(QString("Registered %1 applications").arg(m_applications.size()));
}

void ApplicationFrameworkManager::registerDBusService()
{
    logInfo("Registering D-Bus service...");

    m_dbusAdaptor = new ApplicationLifecycleDBus(this);

    QDBusConnection sessionBus = QDBusConnection::sessionBus();

    if (!sessionBus.registerService("com.headunit.AppLifecycle")) {
        logError(QString("Failed to register D-Bus service: %1")
                     .arg(sessionBus.lastError().message()));
        return;
    }

    if (!sessionBus.registerObject("/com/headunit/AppLifecycle", this)) {
        logError(QString("Failed to register D-Bus object: %1")
                     .arg(sessionBus.lastError().message()));
        return;
    }

    logInfo("D-Bus service registered: com.headunit.AppLifecycle");
}

void ApplicationFrameworkManager::launchApp(int iviId)
{
    AppInfo *appInfo = getAppInfo(iviId);
    if (!appInfo) {
        logWarning(QString("Launch request for unknown IVI-ID: %1").arg(iviId));
        return;
    }

    // Check if already running - activate instead
    if (appInfo->state == "running" || appInfo->state == "active") {
        logInfo(QString("%1 already running, activating instead").arg(appInfo->name));
        activateApp(iviId);
        return;
    }

    logInfo(QString("Launching %1 (IVI-ID: %2)").arg(appInfo->name).arg(iviId));

    // Check if binary exists
    if (!QFile::exists(appInfo->binaryPath)) {
        logError(QString("Binary not found: %1").arg(appInfo->binaryPath));
        return;
    }

    // Update state
    updateAppState(iviId, "launching");

    // Start process
    startProcess(appInfo);
}

void ApplicationFrameworkManager::activateApp(int iviId)
{
    AppInfo *appInfo = getAppInfo(iviId);
    if (!appInfo) {
        logWarning(QString("Activate request for unknown IVI-ID: %1").arg(iviId));
        return;
    }

    // If not running, launch instead
    if (appInfo->state != "running" && appInfo->state != "paused") {
        logInfo(QString("%1 not running, launching instead").arg(appInfo->name));
        launchApp(iviId);
        return;
    }

    logInfo(QString("Activating %1 (IVI-ID: %2)").arg(appInfo->name).arg(iviId));

    // Update state to active
    updateAppState(iviId, "active");

    // Notify Window Manager (if available)
    // This would send activateWindow request to WM service
}

void ApplicationFrameworkManager::terminateApp(int iviId)
{
    AppInfo *appInfo = getAppInfo(iviId);
    if (!appInfo) {
        logWarning(QString("Terminate request for unknown IVI-ID: %1").arg(iviId));
        return;
    }

    if (!appInfo->process || appInfo->state == "stopped") {
        logWarning(QString("%1 is not running").arg(appInfo->name));
        return;
    }

    logInfo(QString("Terminating %1 (PID: %2)").arg(appInfo->name).arg(appInfo->pid));

    // Graceful termination
    appInfo->process->terminate();

    // Force kill after 3 seconds if not terminated
    QTimer::singleShot(3000, this, [this, iviId]() {
        AppInfo *info = getAppInfo(iviId);
        if (info && info->process && info->process->state() != QProcess::NotRunning) {
            logWarning(QString("Force killing %1").arg(info->name));
            info->process->kill();
        }
    });
}

void ApplicationFrameworkManager::pauseApp(int iviId)
{
    AppInfo *appInfo = getAppInfo(iviId);
    if (!appInfo || appInfo->state != "running") {
        return;
    }

    logInfo(QString("Pausing %1").arg(appInfo->name));
    updateAppState(iviId, "paused");
    emit m_dbusAdaptor->AppPaused(iviId);
}

void ApplicationFrameworkManager::resumeApp(int iviId)
{
    AppInfo *appInfo = getAppInfo(iviId);
    if (!appInfo || appInfo->state != "paused") {
        return;
    }

    logInfo(QString("Resuming %1").arg(appInfo->name));
    updateAppState(iviId, "running");
    emit m_dbusAdaptor->AppResumed(iviId);
}

QString ApplicationFrameworkManager::getAppState(int iviId)
{
    AppInfo *appInfo = getAppInfo(iviId);
    return appInfo ? appInfo->state : "unknown";
}

QList<int> ApplicationFrameworkManager::getRunningApps()
{
    QList<int> runningApps;

    for (auto it = m_applications.begin(); it != m_applications.end(); ++it) {
        if (it.value().state != "stopped") {
            runningApps.append(it.key());
        }
    }

    return runningApps;
}

void ApplicationFrameworkManager::notifyAppConnected(int iviId)
{
    AppInfo *appInfo = getAppInfo(iviId);
    if (!appInfo) {
        return;
    }

    logInfo(QString("Application connected: %1 (IVI-ID: %2)").arg(appInfo->name).arg(iviId));

    // Update state from launching to running
    if (appInfo->state == "launching") {
        updateAppState(iviId, "running");
    }
}

void ApplicationFrameworkManager::notifyAppDisconnected(int iviId)
{
    AppInfo *appInfo = getAppInfo(iviId);
    if (!appInfo) {
        return;
    }

    logInfo(QString("Application disconnected: %1 (IVI-ID: %2)").arg(appInfo->name).arg(iviId));

    // Don't change state - wait for process to actually exit
}

void ApplicationFrameworkManager::startProcess(AppInfo *appInfo)
{
    // Clean up old process if exists
    if (appInfo->process) {
        delete appInfo->process;
        appInfo->process = nullptr;
    }

    // Create new process
    appInfo->process = new QProcess(this);

    // Setup environment
    QProcessEnvironment env = createAppEnvironment(appInfo->iviId);
    appInfo->process->setProcessEnvironment(env);

    // Setup logging
    QString logDir = "./logs";
    QDir().mkpath(logDir);
    appInfo->process->setStandardOutputFile(
        QString("%1/%2.log").arg(logDir, appInfo->name),
        QIODevice::Append
        );
    appInfo->process->setStandardErrorFile(
        QString("%1/%2.err.log").arg(logDir, appInfo->name),
        QIODevice::Append
        );

    // Connect signals
    connect(appInfo->process, &QProcess::started,
            this, &ApplicationFrameworkManager::onProcessStarted);
    connect(appInfo->process,
            QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &ApplicationFrameworkManager::onProcessFinished);
    connect(appInfo->process, &QProcess::errorOccurred,
            this, &ApplicationFrameworkManager::onProcessError);
    connect(appInfo->process, &QProcess::stateChanged,
            this, &ApplicationFrameworkManager::onProcessStateChanged);

    // Launch
    logInfo(QString("Starting process: %1").arg(appInfo->binaryPath));
    appInfo->process->start(appInfo->binaryPath);

    if (!appInfo->process->waitForStarted(5000)) {
        logError(QString("Failed to start %1: %2")
                     .arg(appInfo->name)
                     .arg(appInfo->process->errorString()));
        updateAppState(appInfo->iviId, "stopped");
        return;
    }

    // Update process info
    appInfo->pid = appInfo->process->processId();
    appInfo->runId = m_nextRunId++;
    appInfo->launchTime = QDateTime::currentDateTime();

    logInfo(QString("%1 started successfully - PID: %2, RunID: %3")
                .arg(appInfo->name)
                .arg(appInfo->pid)
                .arg(appInfo->runId));

    // Emit launch signal
    emit m_dbusAdaptor->AppLaunched(appInfo->iviId, appInfo->runId);
}

QProcessEnvironment ApplicationFrameworkManager::createAppEnvironment(int iviId)
{
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();

    // Wayland configuration
    env.insert("QT_QPA_PLATFORM", "wayland");
    env.insert("QT_WAYLAND_SHELL_INTEGRATION", "ivi-shell");
    env.insert("QT_IVI_SURFACE_ID", QString::number(iviId));
    env.insert("WAYLAND_DISPLAY", "wayland-1");

    // XDG runtime directory
    QString xdgRuntime = env.value("XDG_RUNTIME_DIR", "/tmp");
    env.insert("XDG_RUNTIME_DIR", xdgRuntime);

    // Qt optimizations
    env.insert("QT_QUICK_BACKEND", "software");  // or "openvg" for GPU
    env.insert("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");

    return env;
}

void ApplicationFrameworkManager::onProcessStarted()
{
    QProcess *proc = qobject_cast<QProcess*>(sender());
    if (!proc) return;

    qint64 pid = proc->processId();
    logInfo(QString("Process started with PID: %1").arg(pid));
}

void ApplicationFrameworkManager::onProcessFinished(int exitCode, QProcess::ExitStatus status)
{
    QProcess *proc = qobject_cast<QProcess*>(sender());
    if (!proc) return;

    // Find which app this process belongs to
    for (auto &appInfo : m_applications) {
        if (appInfo.process == proc) {
            QString statusStr = (status == QProcess::NormalExit) ? "normally" : "crashed";
            logInfo(QString("%1 exited %2 with code %3")
                        .arg(appInfo.name)
                        .arg(statusStr)
                        .arg(exitCode));

            // Update state
            updateAppState(appInfo.iviId, "stopped");

            // Emit termination signal
            emit m_dbusAdaptor->AppTerminated(appInfo.iviId);

            // Reset process info
            appInfo.pid = 0;
            appInfo.runId = 0;

            break;
        }
    }
}

void ApplicationFrameworkManager::onProcessError(QProcess::ProcessError error)
{
    QProcess *proc = qobject_cast<QProcess*>(sender());
    if (!proc) return;

    QString errorStr;
    switch (error) {
    case QProcess::FailedToStart:
        errorStr = "Failed to start";
        break;
    case QProcess::Crashed:
        errorStr = "Crashed";
        break;
    case QProcess::Timedout:
        errorStr = "Timed out";
        break;
    case QProcess::WriteError:
        errorStr = "Write error";
        break;
    case QProcess::ReadError:
        errorStr = "Read error";
        break;
    default:
        errorStr = "Unknown error";
    }

    logError(QString("Process error: %1 - %2").arg(errorStr).arg(proc->errorString()));
}

void ApplicationFrameworkManager::onProcessStateChanged(QProcess::ProcessState newState)
{
    QProcess *proc = qobject_cast<QProcess*>(sender());
    if (!proc) return;

    QString stateStr;
    switch (newState) {
    case QProcess::NotRunning:
        stateStr = "Not Running";
        break;
    case QProcess::Starting:
        stateStr = "Starting";
        break;
    case QProcess::Running:
        stateStr = "Running";
        break;
    }

    qDebug() << "[AFM] Process state changed to:" << stateStr;
}

void ApplicationFrameworkManager::onWatchdogTimeout()
{
    // Check for zombie processes or hung applications
    for (auto &appInfo : m_applications) {
        if (appInfo.process && appInfo.state != "stopped") {
            QProcess::ProcessState procState = appInfo.process->state();

            if (procState == QProcess::NotRunning && appInfo.state != "stopped") {
                logWarning(QString("Watchdog: %1 process not running but state is %2")
                               .arg(appInfo.name).arg(appInfo.state));
                updateAppState(appInfo.iviId, "stopped");
            }
        }
    }
}

AppInfo* ApplicationFrameworkManager::getAppInfo(int iviId)
{
    auto it = m_applications.find(iviId);
    return (it != m_applications.end()) ? &it.value() : nullptr;
}

QString ApplicationFrameworkManager::getAppRole(int iviId)
{
    AppInfo *info = getAppInfo(iviId);
    return info ? info->role : QString();
}

void ApplicationFrameworkManager::updateAppState(int iviId, const QString &newState)
{
    AppInfo *appInfo = getAppInfo(iviId);
    if (!appInfo) return;

    if (appInfo->state != newState) {
        QString oldState = appInfo->state;
        appInfo->state = newState;

        logInfo(QString("%1 state: %2 → %3").arg(appInfo->name).arg(oldState).arg(newState));

        // Emit state change signal
        emit m_dbusAdaptor->StateChanged(iviId, newState);
    }
}

void ApplicationFrameworkManager::logInfo(const QString &message)
{
    QString logMessage = QString("[%1] [INFO] %2")
    .arg(QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss"))
        .arg(message);

    qInfo().noquote() << logMessage;

    // Write to log file
    QFile logFile(m_logFilePath);
    if (logFile.open(QIODevice::Append | QIODevice::Text)) {
        QTextStream out(&logFile);
        out << logMessage << "\n";
        logFile.close();
    }
}

void ApplicationFrameworkManager::logWarning(const QString &message)
{
    QString logMessage = QString("[%1] [WARN] %2")
    .arg(QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss"))
        .arg(message);

    qWarning().noquote() << logMessage;

    QFile logFile(m_logFilePath);
    if (logFile.open(QIODevice::Append | QIODevice::Text)) {
        QTextStream out(&logFile);
        out << logMessage << "\n";
        logFile.close();
    }
}

void ApplicationFrameworkManager::logError(const QString &message)
{
    QString logMessage = QString("[%1] [ERROR] %2")
    .arg(QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss"))
        .arg(message);

    qCritical().noquote() << logMessage;

    QFile logFile(m_logFilePath);
    if (logFile.open(QIODevice::Append | QIODevice::Text)) {
        QTextStream out(&logFile);
        out << logMessage << "\n";
        logFile.close();
    }
}

// ============================================================================
// ApplicationLifecycleDBus Implementation
// ============================================================================

ApplicationLifecycleDBus::ApplicationLifecycleDBus(QObject *parent)
    : QDBusAbstractAdaptor(parent)
{
    m_manager = qobject_cast<ApplicationFrameworkManager*>(parent);
    setAutoRelaySignals(true);
}

void ApplicationLifecycleDBus::LaunchApp(int iviId)
{
    if (m_manager) {
        m_manager->launchApp(iviId);
    }
}

void ApplicationLifecycleDBus::ActivateApp(int iviId)
{
    if (m_manager) {
        m_manager->activateApp(iviId);
    }
}

void ApplicationLifecycleDBus::TerminateApp(int iviId)
{
    if (m_manager) {
        m_manager->terminateApp(iviId);
    }
}

void ApplicationLifecycleDBus::PauseApp(int iviId)
{
    if (m_manager) {
        m_manager->pauseApp(iviId);
    }
}

void ApplicationLifecycleDBus::ResumeApp(int iviId)
{
    if (m_manager) {
        m_manager->resumeApp(iviId);
    }
}

QString ApplicationLifecycleDBus::GetAppState(int iviId)
{
    return m_manager ? m_manager->getAppState(iviId) : "unknown";
}

QList<int> ApplicationLifecycleDBus::GetRunningApps()
{
    return m_manager ? m_manager->getRunningApps() : QList<int>();
}

void ApplicationLifecycleDBus::AppConnected(int iviId)
{
    if (m_manager) {
        m_manager->notifyAppConnected(iviId);
    }
}

void ApplicationLifecycleDBus::AppDisconnected(int iviId)
{
    if (m_manager) {
        m_manager->notifyAppDisconnected(iviId);
    }
}
