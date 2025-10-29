// application_framework_manager.h
#ifndef APPLICATION_FRAMEWORK_MANAGER_H
#define APPLICATION_FRAMEWORK_MANAGER_H

#include <QObject>
#include <QDBusAbstractAdaptor>
#include <QDBusConnection>
#include <QProcess>
#include <QMap>
#include <QString>
#include <QTimer>
#include <QDateTime>

/**
 * Application Information Structure
 */
struct AppInfo {
    int iviId;
    QString name;
    QString displayName;
    QString binaryPath;
    QString role;
    QProcess* process;
    QString state;
    int runId;
    qint64 pid;
    QDateTime launchTime;

    // ADD default constructor to fix initialization errors
    AppInfo()
        : iviId(0)
        , process(nullptr)
        , runId(0)
        , pid(0)
    {}
};

/**
 * D-Bus Adaptor for Application Lifecycle Interface
 * Exposes methods and signals over D-Bus
 */
class ApplicationLifecycleDBus : public QDBusAbstractAdaptor
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "com.headunit.AppLifecycle")

public:
    explicit ApplicationLifecycleDBus(QObject *parent);

public Q_SLOTS:
    // Application lifecycle methods
    Q_NOREPLY void LaunchApp(int iviId);
    Q_NOREPLY void ActivateApp(int iviId);
    Q_NOREPLY void TerminateApp(int iviId);
    Q_NOREPLY void PauseApp(int iviId);
    Q_NOREPLY void ResumeApp(int iviId);

    // State query methods
    QString GetAppState(int iviId);
    QList<int> GetRunningApps();

    // Compositor notification methods
    Q_NOREPLY void AppConnected(int iviId);
    Q_NOREPLY void AppDisconnected(int iviId);

Q_SIGNALS:
    // Lifecycle signals
    void AppLaunched(int iviId, int runId);
    void AppTerminated(int iviId);
    void StateChanged(int iviId, const QString &state);
    void AppPaused(int iviId);
    void AppResumed(int iviId);

private:
    class ApplicationFrameworkManager *m_manager;
};

/**
 * Main Application Framework Manager
 * Manages application lifecycle, processes, and state
 */
class ApplicationFrameworkManager : public QObject
{
    Q_OBJECT

public:
    explicit ApplicationFrameworkManager(QObject *parent = nullptr);
    ~ApplicationFrameworkManager();

    // Public methods called by D-Bus adaptor
    void launchApp(int iviId);
    void activateApp(int iviId);
    void terminateApp(int iviId);
    void pauseApp(int iviId);
    void resumeApp(int iviId);
    QString getAppState(int iviId);
    QList<int> getRunningApps();
    void notifyAppConnected(int iviId);
    void notifyAppDisconnected(int iviId);

private Q_SLOTS:
    // Process event handlers
    void onProcessStarted();
    void onProcessFinished(int exitCode, QProcess::ExitStatus status);
    void onProcessError(QProcess::ProcessError error);
    void onProcessStateChanged(QProcess::ProcessState newState);

    // Watchdog timer
    void onWatchdogTimeout();

private:
    // Initialization
    void registerDBusService();
    void setupApplicationRegistry();
    void loadConfiguration();
    void registerApplication(int iviId, const QString &name, const QString &displayName, const QString &binaryPath, const QString &role);

    // Application management
    AppInfo* getAppInfo(int iviId);
    QString getAppRole(int iviId);
    void updateAppState(int iviId, const QString &newState);

    // Process management
    void startProcess(AppInfo *appInfo);
    void killProcess(AppInfo *appInfo);
    QProcessEnvironment createAppEnvironment(int iviId);

    // Logging
    void logInfo(const QString &message);
    void logWarning(const QString &message);
    void logError(const QString &message);

    // Data members
    QMap<int, AppInfo> m_applications;        // IVI-ID → Application info
    ApplicationLifecycleDBus *m_dbusAdaptor;  // D-Bus interface
    QTimer *m_watchdogTimer;                  // Process watchdog
    int m_nextRunId;                          // Incrementing run ID counter
    QString m_logFilePath;                    // Log file path
};

#endif // APPLICATION_FRAMEWORK_MANAGER_H
