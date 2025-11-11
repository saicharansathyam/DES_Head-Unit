// application_framework_manager.h

#ifndef APPLICATION_FRAMEWORK_MANAGER_H
#define APPLICATION_FRAMEWORK_MANAGER_H

#include <QObject>
#include <QProcess>
#include <QMap>
#include <QString>
#include <QTimer>
#include <QDateTime>
#include <QDBusAbstractAdaptor>
#include <QStringList>

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

    AppInfo()
        : iviId(0)
        , process(nullptr)
        , runId(0)
        , pid(0)
    {}
};

/**
 * D-Bus Adaptor for Application Lifecycle Interface
 */
class ApplicationLifecycleDBus : public QDBusAbstractAdaptor
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "com.headunit.AppLifecycle")

public:
    explicit ApplicationLifecycleDBus(QObject *parent);

public Q_SLOTS:
    Q_NOREPLY void LaunchApp(int iviId);
    Q_NOREPLY void ActivateApp(int iviId);
    Q_NOREPLY void TerminateApp(int iviId);
    Q_NOREPLY void PauseApp(int iviId);
    Q_NOREPLY void ResumeApp(int iviId);
    Q_NOREPLY void LaunchInitialApps();  // NEW

    QString GetAppState(int iviId);
    QList<int> GetRunningApps();

    Q_NOREPLY void AppConnected(int iviId);
    Q_NOREPLY void AppDisconnected(int iviId);

Q_SIGNALS:
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
 */
class ApplicationFrameworkManager : public QObject
{
    Q_OBJECT

public:
    void extracted();
    explicit ApplicationFrameworkManager(QObject *parent = nullptr);
    ~ApplicationFrameworkManager();

    void launchApp(int iviId);
    void activateApp(int iviId);
    void terminateApp(int iviId);
    void pauseApp(int iviId);
    void resumeApp(int iviId);
    QString getAppState(int iviId);
    QList<int> getRunningApps();
    void notifyAppConnected(int iviId);
    void notifyAppDisconnected(int iviId);

    // NEW methods
    void launchInitialApplications();
    bool isWaylandCompositorReady();

private Q_SLOTS:
    void onProcessStarted();
    void onProcessFinished(int exitCode, QProcess::ExitStatus status);
    void onProcessError(QProcess::ProcessError error);
    void onProcessStateChanged(QProcess::ProcessState newState);
    void onWatchdogTimeout();

private:
    void registerDBusService();
    void binExtracted();
    void setupApplicationRegistry();
    void loadConfiguration();
    void registerApplication(int iviId, const QString &name,
                             const QString &displayName,
                             const QString &binaryPath,
                             const QString &role);

    AppInfo* getAppInfo(int iviId);
    QString getAppRole(int iviId);
    void updateAppState(int iviId, const QString &newState);

    void startProcess(AppInfo *appInfo);
    void killProcess(AppInfo *appInfo);
    QProcessEnvironment createAppEnvironment(int iviId);

    QString findApplicationBinary(const QString &appName);
    QStringList getSearchPaths();

    void logInfo(const QString &message);
    void logWarning(const QString &message);
    void logError(const QString &message);

    QMap<int, AppInfo> m_applications;
    ApplicationLifecycleDBus *m_dbusAdaptor;
    QTimer *m_watchdogTimer;
    int m_nextRunId;
    QString m_logFilePath;
    QStringList m_binarySearchPaths;
};

#endif // APPLICATION_FRAMEWORK_MANAGER_H
