// application_framework_manager.cpp

#include "application_framework_manager.h"
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QCoreApplication>
#include <QDBusConnection>
#include <QTextStream>
#include <QThread>
#include <QDateTime>
#include <QDBusError>

// ============================================================================
// ApplicationFrameworkManager Implementation
// ============================================================================

void ApplicationFrameworkManager::binExtracted() {
    for (const QString &path : m_binarySearchPaths) {
        logInfo(QString("  - %1").arg(path));
    }
}
ApplicationFrameworkManager::ApplicationFrameworkManager(QObject *parent)
    : QObject(parent), m_dbusAdaptor(nullptr), m_watchdogTimer(nullptr),
    m_nextRunId(1) {
    logInfo("=== Application Framework Manager Starting ===");

    // Setup logging
    m_logFilePath = "./logs/afm.log";
    QDir().mkpath("./logs");

    // Initialize binary search paths
    QString absoluteDevPath =
        "/home/seame/Documents/GitHub/DES_Head-Unit/HeadUnit/applications";

    m_binarySearchPaths << absoluteDevPath;
    m_binarySearchPaths << "/usr/local/bin";
    m_binarySearchPaths << "/usr/bin";

    logInfo("Binary search paths configured:");
    binExtracted();

    // Load configuration and setup application registry
    loadConfiguration();
    setupApplicationRegistry();

    // Register D-Bus service
    registerDBusService();

    // Launch initial applications after a delay to let compositor start
    QTimer::singleShot(5000, this, &ApplicationFrameworkManager::launchInitialApplications);

    // Setup watchdog timer for process monitoring
    m_watchdogTimer = new QTimer(this);
    connect(m_watchdogTimer, &QTimer::timeout, this,
            &ApplicationFrameworkManager::onWatchdogTimeout);
    m_watchdogTimer->start(5000);

    logInfo("=== AFM Initialization Complete ===");
    logInfo("Waiting for compositor to be ready before launching apps...");
}

ApplicationFrameworkManager::~ApplicationFrameworkManager()
{
    logInfo("=== Application Framework Manager Shutting Down ===");

    for (auto &appInfo : m_applications) {
        if (appInfo.process && appInfo.process->state() != QProcess::NotRunning) {
            logInfo(QString("Terminating %1 (PID: %2)")
                        .arg(appInfo.name).arg(appInfo.pid));
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
    logInfo("Loading application configuration...");
}

QStringList ApplicationFrameworkManager::getSearchPaths()
{
    return m_binarySearchPaths;
}

QString ApplicationFrameworkManager::findApplicationBinary(const QString &appName)
{
    logInfo(QString("Searching for binary: %1").arg(appName));

    for (const QString &searchPath : m_binarySearchPaths) {
        QString fullPath = QDir(searchPath).filePath(appName);
        QFileInfo fileInfo(fullPath);

        logInfo(QString("  Checking: %1").arg(fullPath));

        if (fileInfo.exists() && fileInfo.isFile() && fileInfo.isExecutable()) {
            QString canonicalPath = fileInfo.canonicalFilePath();
            logInfo(QString("  ✓ Found at: %1").arg(canonicalPath));
            return canonicalPath;
        }
    }

    logWarning(QString("  ✗ Binary not found in any search path: %1").arg(appName));
    return QString();
}

void ApplicationFrameworkManager::registerApplication(int iviId,
                                                      const QString &name,
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

    registerApplication(1001, "GearSelector", "Gear Selector",
                        findApplicationBinary("GearSelector"), "GearSelector");

    registerApplication(1002, "MediaPlayer", "Media Player",
                        findApplicationBinary("MediaPlayer"), "MediaPlayer");

    registerApplication(1003, "ThemeColor", "Theme & Colors",
                        findApplicationBinary("ThemeColor"), "ThemeColor");

    registerApplication(1004, "Navigation", "Navigation",
                    findApplicationBinary("Navigation"), "Navigation");

    registerApplication(1005, "Settings", "Settings",
                        findApplicationBinary("Settings"), "Settings");

    logInfo(QString("Registered %1 applications").arg(m_applications.size()));

    for (const auto &app : m_applications) {
        if (app.binaryPath.isEmpty()) {
            logWarning(QString("  %1 - BINARY NOT FOUND").arg(app.displayName));
        } else {
            logInfo(QString("  %1 - %2").arg(app.displayName).arg(app.binaryPath));
        }
    }
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

// NEW: Check if Wayland compositor is ready
bool ApplicationFrameworkManager::isWaylandCompositorReady()
{
    QString xdgRuntime = qEnvironmentVariable("XDG_RUNTIME_DIR", "/tmp");
    QString waylandSocket = QDir(xdgRuntime).filePath("wayland-1");

    QFileInfo socketInfo(waylandSocket);
    bool ready = socketInfo.exists() && socketInfo.isReadable();

    if (ready) {
        logInfo(QString("✓ Wayland compositor ready: %1").arg(waylandSocket));
    } else {
        logWarning(QString("✗ Wayland compositor not ready: %1").arg(waylandSocket));
    }

    return ready;
}

// NEW: Launch initial applications with compositor check
void ApplicationFrameworkManager::launchInitialApplications()
{
    logInfo("=== Launching Initial Applications ===");
    
    // Check if Wayland compositor is ready
    if (!isWaylandCompositorReady()) {
        logWarning("Wayland compositor not ready, delaying app launch");
        QTimer::singleShot(2000, this, &ApplicationFrameworkManager::launchInitialApplications);
        return;
    }
    
    // Launch apps that are marked as autostart in applications.json
    for (auto it = m_applications.begin(); it != m_applications.end(); ++it) {
        int iviId = it.key();
        AppInfo &appInfo = it.value();
        
        // For now, launch GearSelector(1001), MediaPlayer(1002), ThemeColor(1003)
        if (iviId == 1001 || iviId == 1002 || iviId == 1003) {
            logInfo(QString("Auto-launching app: %1 (ID: %2)").arg(appInfo.displayName).arg(iviId));
            launchApp(iviId);
            
            // Small delay between launches
            QThread::msleep(1000);
        }
    }
    
    logInfo("=== Initial application launch complete ===");
}

void ApplicationFrameworkManager::launchApp(int iviId)
{
    AppInfo *appInfo = getAppInfo(iviId);
    if (!appInfo) {
        logWarning(QString("Launch request for unknown IVI-ID: %1").arg(iviId));
        return;
    }

    // Check if already running
    if (appInfo->state == "running" || appInfo->state == "active") {
        logInfo(QString("%1 already running, activating instead").arg(appInfo->name));
        activateApp(iviId);
        return;
    }

    logInfo(QString("Launching %1 (IVI-ID: %2)").arg(appInfo->name).arg(iviId));

    // Check if binary path is valid
    if (appInfo->binaryPath.isEmpty()) {
        logError(QString("Binary path not set for %1 - attempting to find it...")
                     .arg(appInfo->name));

        QString foundPath = findApplicationBinary(appInfo->name);
        if (!foundPath.isEmpty()) {
            appInfo->binaryPath = foundPath;
            logInfo(QString("Found binary at: %1").arg(foundPath));
        } else {
            logError(QString("Binary not found for %1").arg(appInfo->name));
            return;
        }
    }

    // Final check if binary exists
    if (!QFile::exists(appInfo->binaryPath)) {
        logError(QString("Binary not found: %1").arg(appInfo->binaryPath));
        return;
    }

    // Check compositor again before launching
    if (!isWaylandCompositorReady()) {
        logError(QString("Cannot launch %1 - Wayland compositor not ready").arg(appInfo->name));
        return;
    }

    updateAppState(iviId, "launching");
    startProcess(appInfo);
}

void ApplicationFrameworkManager::activateApp(int iviId)
{
    AppInfo *appInfo = getAppInfo(iviId);
    if (!appInfo) {
        logWarning(QString("Activate request for unknown IVI-ID: %1").arg(iviId));
        return;
    }

    if (appInfo->state != "running") {
        logInfo(QString("App %1 not running, launching instead").arg(appInfo->name));
        launchApp(iviId);
        return;
    }

    logInfo(QString("Activating %1").arg(appInfo->name));
    updateAppState(iviId, "active");
}

void ApplicationFrameworkManager::terminateApp(int iviId)
{
    AppInfo *appInfo = getAppInfo(iviId);
    if (!appInfo) {
        logWarning(QString("Terminate request for unknown IVI-ID: %1").arg(iviId));
        return;
    }

    if (appInfo->state == "stopped") {
        logInfo(QString("%1 is already stopped").arg(appInfo->name));
        return;
    }

    logInfo(QString("Terminating %1").arg(appInfo->name));
    killProcess(appInfo);
}

void ApplicationFrameworkManager::pauseApp(int iviId)
{
    AppInfo *appInfo = getAppInfo(iviId);
    if (!appInfo) {
        logWarning(QString("Pause request for unknown IVI-ID: %1").arg(iviId));
        return;
    }

    if (appInfo->state != "active") {
        logWarning(QString("Cannot pause %1 - not active").arg(appInfo->name));
        return;
    }

    logInfo(QString("Pausing %1").arg(appInfo->name));
    updateAppState(iviId, "paused");
}

void ApplicationFrameworkManager::resumeApp(int iviId)
{
    AppInfo *appInfo = getAppInfo(iviId);
    if (!appInfo) {
        logWarning(QString("Resume request for unknown IVI-ID: %1").arg(iviId));
        return;
    }

    if (appInfo->state != "paused") {
        logWarning(QString("Cannot resume %1 - not paused").arg(appInfo->name));
        return;
    }

    logInfo(QString("Resuming %1").arg(appInfo->name));
    updateAppState(iviId, "active");
}

QString ApplicationFrameworkManager::getAppState(int iviId)
{
    AppInfo *appInfo = getAppInfo(iviId);
    if (!appInfo) {
        return "unknown";
    }
    return appInfo->state;
}

QList<int> ApplicationFrameworkManager::getRunningApps()
{
    QList<int> runningApps;
    for (const auto &appInfo : m_applications) {
        if (appInfo.state == "running" || appInfo.state == "active") {
            runningApps.append(appInfo.iviId);
        }
    }
    return runningApps;
}

void ApplicationFrameworkManager::notifyAppConnected(int iviId)
{
    AppInfo *appInfo = getAppInfo(iviId);
    if (!appInfo) {
        logWarning(QString("Connected notification for unknown IVI-ID: %1").arg(iviId));
        return;
    }

    logInfo(QString("%1 connected to compositor").arg(appInfo->name));
    updateAppState(iviId, "active");
}

void ApplicationFrameworkManager::notifyAppDisconnected(int iviId)
{
    AppInfo *appInfo = getAppInfo(iviId);
    if (!appInfo) {
        logWarning(QString("Disconnected notification for unknown IVI-ID: %1").arg(iviId));
        return;
    }

    logInfo(QString("%1 disconnected from compositor").arg(appInfo->name));

    if (appInfo->process && appInfo->process->state() == QProcess::NotRunning) {
        updateAppState(iviId, "stopped");
    }
}

void ApplicationFrameworkManager::startProcess(AppInfo *appInfo)
{
    if (!appInfo) return;

    if (!appInfo->process) {
        appInfo->process = new QProcess(this);
        connect(appInfo->process, &QProcess::started,
                this, &ApplicationFrameworkManager::onProcessStarted);
        connect(appInfo->process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
                this, &ApplicationFrameworkManager::onProcessFinished);
        connect(appInfo->process, &QProcess::errorOccurred,
                this, &ApplicationFrameworkManager::onProcessError);
        connect(appInfo->process, &QProcess::stateChanged,
                this, &ApplicationFrameworkManager::onProcessStateChanged);
    }

    // Set environment with enhanced checking
    QProcessEnvironment env = createAppEnvironment(appInfo->iviId);
    appInfo->process->setProcessEnvironment(env);

    // Start process
    logInfo(QString("Starting process: %1").arg(appInfo->binaryPath));
    appInfo->runId = m_nextRunId++;
    appInfo->launchTime = QDateTime::currentDateTime();
    appInfo->process->start(appInfo->binaryPath);
}

void ApplicationFrameworkManager::killProcess(AppInfo *appInfo)
{
    if (!appInfo || !appInfo->process) return;

    logInfo(QString("Killing process for %1 (PID: %2)")
                .arg(appInfo->name).arg(appInfo->pid));

    appInfo->process->terminate();
    if (!appInfo->process->waitForFinished(3000)) {
        appInfo->process->kill();
    }
}

// ENHANCED: Better environment setup with validation
QProcessEnvironment ApplicationFrameworkManager::createAppEnvironment(int iviId)
{
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    
    // Get XDG_RUNTIME_DIR (critical for both Wayland and EGLFS)
    QString xdgRuntime = env.value("XDG_RUNTIME_DIR");
    if (xdgRuntime.isEmpty()) {
        xdgRuntime = "/run/user/0";
        env.insert("XDG_RUNTIME_DIR", xdgRuntime);
        logWarning(QString("XDG_RUNTIME_DIR not set, using: %1").arg(xdgRuntime));
    }
    
    // Check if compositor/Wayland is available
    QString waylandSocket = QDir(xdgRuntime).filePath("wayland-1");
    bool compositorRunning = QFile::exists(waylandSocket);
    
    if (compositorRunning) {
        // WAYLAND MODE - Compositor is running
        logInfo(QString("App %1: Wayland compositor detected, using Wayland mode").arg(iviId));
        
        env.insert("QT_QPA_PLATFORM", "wayland");
        env.insert("QT_WAYLAND_SHELL_INTEGRATION", "ivi-shell");
        env.insert("QT_IVI_SURFACE_ID", QString::number(iviId));
        env.insert("WAYLAND_DISPLAY", "wayland-1");
        env.insert("QT_LOGGING_RULES", "qt.qpa.wayland*=false");
        
        logInfo(QString("Wayland socket: %1").arg(waylandSocket));
    } else {
        // EGLFS MODE - Standalone mode (no compositor)
        logInfo(QString("App %1: No compositor detected, using EGLFS standalone mode").arg(iviId));
        
        env.insert("QT_QPA_PLATFORM", "eglfs");
        env.insert("QT_QPA_EGLFS_INTEGRATION", "eglfs_kms");
        env.insert("QT_QPA_EGLFS_ALWAYS_SET_MODE", "1");
        
        logWarning("Running in standalone EGLFS mode - only one app can be active at a time");
    }
    
    // Common settings for both modes
    env.insert("LC_ALL", "C.UTF-8");
    
    logInfo(QString("App %1 environment configured with QT_QPA_PLATFORM=%2")
            .arg(iviId).arg(env.value("QT_QPA_PLATFORM")));
    
    return env;
}

void ApplicationFrameworkManager::onProcessStarted()
{
    QProcess *process = qobject_cast<QProcess*>(sender());
    if (!process) return;

    for (auto &appInfo : m_applications) {
        if (appInfo.process == process) {
            appInfo.pid = process->processId();
            updateAppState(appInfo.iviId, "running");
            logInfo(QString("%1 started successfully (PID: %2, RunID: %3)")
                        .arg(appInfo.name).arg(appInfo.pid).arg(appInfo.runId));
            break;
        }
    }
}

void ApplicationFrameworkManager::onProcessFinished(int exitCode, QProcess::ExitStatus status)
{
    QProcess *process = qobject_cast<QProcess*>(sender());
    if (!process) return;

    for (auto &appInfo : m_applications) {
        if (appInfo.process == process) {
            QString statusStr = (status == QProcess::NormalExit) ? "normally" : "crashed";
            logInfo(QString("%1 finished %2 (exit code: %3)")
                        .arg(appInfo.name).arg(statusStr).arg(exitCode));

            updateAppState(appInfo.iviId, "stopped");
            appInfo.pid = 0;
            break;
        }
    }
}

void ApplicationFrameworkManager::onProcessError(QProcess::ProcessError error)
{
    QProcess *process = qobject_cast<QProcess*>(sender());
    if (!process) return;

    for (auto &appInfo : m_applications) {
        if (appInfo.process == process) {
            logError(QString("%1 process error: %2")
                         .arg(appInfo.name).arg(process->errorString()));

            // Additional diagnostics
            if (error == QProcess::FailedToStart) {
                logError("  Reason: Failed to start");
                logError(QString("  Binary: %1").arg(appInfo.binaryPath));
                logError("  Check: Binary exists and is executable");
            } else if (error == QProcess::Crashed) {
                logError("  Reason: Process crashed");
                logError("  Check application logs for crash details");
            }

            updateAppState(appInfo.iviId, "error");
            break;
        }
    }
}

void ApplicationFrameworkManager::onProcessStateChanged(QProcess::ProcessState newState)
{
    QProcess *process = qobject_cast<QProcess*>(sender());
    if (!process) return;

    QString stateStr;
    switch (newState) {
    case QProcess::NotRunning: stateStr = "NotRunning"; break;
    case QProcess::Starting: stateStr = "Starting"; break;
    case QProcess::Running: stateStr = "Running"; break;
    }

    for (const auto &appInfo : m_applications) {
        if (appInfo.process == process) {
            logInfo(QString("%1 process state: %2").arg(appInfo.name).arg(stateStr));
            break;
        }
    }
}

void ApplicationFrameworkManager::onWatchdogTimeout()
{
    for (auto &appInfo : m_applications) {
        if (appInfo.process && appInfo.state == "running") {
            if (appInfo.process->state() == QProcess::NotRunning) {
                logWarning(QString("%1 process died unexpectedly").arg(appInfo.name));
                updateAppState(appInfo.iviId, "crashed");
                appInfo.pid = 0;
            }
        }
    }
}

AppInfo* ApplicationFrameworkManager::getAppInfo(int iviId)
{
    if (m_applications.contains(iviId)) {
        return &m_applications[iviId];
    }
    return nullptr;
}

QString ApplicationFrameworkManager::getAppRole(int iviId)
{
    AppInfo *appInfo = getAppInfo(iviId);
    return appInfo ? appInfo->role : QString();
}

void ApplicationFrameworkManager::updateAppState(int iviId, const QString &newState)
{
    AppInfo *appInfo = getAppInfo(iviId);
    if (!appInfo) return;

    if (appInfo->state != newState) {
        QString oldState = appInfo->state;
        appInfo->state = newState;
        logInfo(QString("%1 state: %2 -> %3")
                    .arg(appInfo->name).arg(oldState).arg(newState));

        if (m_dbusAdaptor) {
            emit m_dbusAdaptor->StateChanged(iviId, newState);
        }
    }
}

void ApplicationFrameworkManager::logInfo(const QString &message)
{
    QString timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss");
    QString logMessage = QString("[%1] [INFO] %2").arg(timestamp).arg(message);

    qInfo().noquote() << logMessage;

    QFile logFile(m_logFilePath);
    if (logFile.open(QIODevice::Append | QIODevice::Text)) {
        QTextStream out(&logFile);
        out << logMessage << "\n";
        logFile.close();
    }
}

void ApplicationFrameworkManager::logWarning(const QString &message)
{
    QString timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss");
    QString logMessage = QString("[%1] [WARN] %2").arg(timestamp).arg(message);

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
    QString timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss");
    QString logMessage = QString("[%1] [ERROR] %2").arg(timestamp).arg(message);

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

void ApplicationLifecycleDBus::LaunchInitialApps()
{
    if (m_manager) {
        m_manager->launchInitialApplications();
    }
}

QString ApplicationLifecycleDBus::GetAppState(int iviId)
{
    if (m_manager) {
        return m_manager->getAppState(iviId);
    }
    return "unknown";
}

QList<int> ApplicationLifecycleDBus::GetRunningApps()
{
    if (m_manager) {
        return m_manager->getRunningApps();
    }
    return QList<int>();
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
