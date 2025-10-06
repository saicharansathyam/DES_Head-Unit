#include "ivi_compositor.h"
#include <QtWaylandCompositor/QWaylandSurface>
#include <QtWaylandCompositor/QWaylandXdgShell>
#include <QtWaylandCompositor/QWaylandXdgSurface>
#include <QtWaylandCompositor/QWaylandWlShell>
#include <QtWaylandCompositor/QWaylandWlShellSurface>
#include <QDebug>
#include <QDir>
#include <QCoreApplication>
#include <QStandardPaths>

ivi_compositor::ivi_compositor(QObject *parent)
    : QWaylandQuickCompositor(parent)
    , m_gearSelectorProcess(nullptr)
    , m_mediaPlayerProcess(nullptr)
    , m_gearSelectorSurface(nullptr)
    , m_mediaPlayerSurface(nullptr)
    , m_autoLaunchClients(false)
    , m_launchTimer(nullptr)
    , m_statusTimer(nullptr)
{
    // Set the Wayland socket name
    setSocketName("wayland-1");
    
    setupProcesses();
    
    // Setup launch timer for auto-launching clients
    m_launchTimer = new QTimer(this);
    m_launchTimer->setSingleShot(true);
    m_launchTimer->setInterval(1000); // Wait 1 second after compositor is ready
    connect(m_launchTimer, &QTimer::timeout, this, &ivi_compositor::launchClients);
    
    // Setup status check timer
    m_statusTimer = new QTimer(this);
    m_statusTimer->setInterval(5000); // Check every 5 seconds
    connect(m_statusTimer, &QTimer::timeout, this, &ivi_compositor::checkClientStatus);
    
    // Connect to surface creation
    connect(this, &QWaylandCompositor::surfaceCreated, 
            this, &ivi_compositor::surfaceCreated);
    
    // Emit ready signal after initialization
    QTimer::singleShot(100, this, [this]() {
        emit compositorReady();
        if (m_autoLaunchClients) {
            m_launchTimer->start();
        }
    });
    
    qDebug() << "IVI Compositor initialized with socket:" << socketName();
}

ivi_compositor::~ivi_compositor()
{
    terminateClients();
    
    if (m_gearSelectorProcess) {
        delete m_gearSelectorProcess;
    }
    
    if (m_mediaPlayerProcess) {
        delete m_mediaPlayerProcess;
    }
}

void ivi_compositor::setupProcesses()
{
    // Create process objects
    m_gearSelectorProcess = new QProcess(this);
    m_mediaPlayerProcess = new QProcess(this);
    
    // Setup environment for client processes
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert("WAYLAND_DISPLAY", socketName());
    env.insert("QT_QPA_PLATFORM", "wayland");
    env.insert("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");
    
    m_gearSelectorProcess->setProcessEnvironment(env);
    m_mediaPlayerProcess->setProcessEnvironment(env);
    
    connectProcessSignals();
}

void ivi_compositor::connectProcessSignals()
{
    // Connect GearSelector process signals
    connect(m_gearSelectorProcess, 
            QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &ivi_compositor::onGearSelectorFinished);
    
    connect(m_gearSelectorProcess, &QProcess::errorOccurred,
            this, &ivi_compositor::onGearSelectorError);
    
    // Connect MediaPlayer process signals
    connect(m_mediaPlayerProcess,
            QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &ivi_compositor::onMediaPlayerFinished);
    
    connect(m_mediaPlayerProcess, &QProcess::errorOccurred,
            this, &ivi_compositor::onMediaPlayerError);
}

QString ivi_compositor::findExecutable(const QString &appName)
{
    // Try multiple locations to find the executable
    QStringList searchPaths;
    
    // 1. Same directory as compositor
    searchPaths << QCoreApplication::applicationDirPath() + "/" + appName;
    
    // 2. Parent directory structure (for development)
    searchPaths << QCoreApplication::applicationDirPath() + "/../" + appName + "/" + appName;
    searchPaths << QCoreApplication::applicationDirPath() + "/../" + appName + "/build/" + appName;
    
    // 3. Standard build directories
    QString buildDir = QDir::currentPath();
    searchPaths << buildDir + "/" + appName + "/" + appName;
    searchPaths << buildDir + "/" + appName + "/build/" + appName;
    searchPaths << buildDir + "/../" + appName + "/build/" + appName;
    
    // 4. System paths
    searchPaths << "/usr/local/bin/" + appName;
    searchPaths << "/usr/bin/" + appName;
    
    // 5. Development build paths
    searchPaths << QDir::homePath() + "/HeadUnit/" + appName + "/build/Desktop_Qt_6_8_3-Debug/" + appName;
    
    // Check each path
    for (const QString &path : searchPaths) {
        QFileInfo fileInfo(path);
        if (fileInfo.exists() && fileInfo.isExecutable()) {
            qDebug() << "Found executable:" << path;
            return fileInfo.absoluteFilePath();
        }
        
        // Also try with "app" prefix
        QString appPath = path;  // make a modifiable copy
        appPath.replace(appName, QStringLiteral("app") + appName);

        QFileInfo appFileInfo(appPath);
        if (appFileInfo.exists() && appFileInfo.isExecutable()) {
            qDebug() << "Found executable:" << appPath;
            return appFileInfo.absoluteFilePath();
        }
    }
    
    qWarning() << "Could not find executable for:" << appName;
    qWarning() << "Searched in:" << searchPaths;
    return QString();
}

void ivi_compositor::launchGearSelector()
{
    if (m_gearSelectorProcess->state() != QProcess::NotRunning) {
        qDebug() << "GearSelector is already running";
        return;
    }
    
    /*QString executable = findExecutable("GearSelector");
    if (executable.isEmpty()) {
        qWarning() << "Cannot find GearSelector executable";
        return;
    }*/
    
    qDebug() << "Launching GearSelector: /home/seame/Documents/GitHub/DES_Head-Unit/HeadUnit/GearSelector/build/Desktop_Qt_6_8_3-Debug"; //<< executable;
    //m_gearSelectorProcess->start(executable, QStringList());
    m_gearSelectorProcess->start("/home/seame/Documents/GitHub/DES_Head-Unit/HeadUnit/GearSelector/build/Desktop_Qt_6_8_3-Debug/GearSelector");
    
    if (!m_gearSelectorProcess->waitForStarted(3000)) {
        qWarning() << "Failed to start GearSelector:" << m_gearSelectorProcess->errorString();
    } else {
        qDebug() << "GearSelector launched successfully";
    }
}

void ivi_compositor::launchMediaPlayer()
{
    if (m_mediaPlayerProcess->state() != QProcess::NotRunning) {
        qDebug() << "MediaPlayer is already running";
        return;
    }
    
    /*QString executable = findExecutable("MediaPlayer");
    if (executable.isEmpty()) {
        qWarning() << "Cannot find MediaPlayer executable";
        return;
    }*/
    
    qDebug() << "Launching MediaPlayer: "; // << executable;
    //m_mediaPlayerProcess->start(executable, QStringList());
    m_mediaPlayerProcess->start("/home/seame/Documents/GitHub/DES_Head-Unit/HeadUnit/MediaPlayer/build/Desktop_Qt_6_8_3-Debug/MediaPlayer");
    
    if (!m_mediaPlayerProcess->waitForStarted(3000)) {
        qWarning() << "Failed to start MediaPlayer:" << m_mediaPlayerProcess->errorString();
    } else {
        qDebug() << "MediaPlayer launched successfully";
    }
}

void ivi_compositor::launchClients()
{
    qDebug() << "Launching client applications...";
    launchGearSelector();
    launchMediaPlayer();
    
    // Start monitoring client status
    m_statusTimer->start();
}

void ivi_compositor::terminateClients()
{
    qDebug() << "Terminating client applications...";
    
    if (m_gearSelectorProcess->state() != QProcess::NotRunning) {
        m_gearSelectorProcess->terminate();
        if (!m_gearSelectorProcess->waitForFinished(5000)) {
            m_gearSelectorProcess->kill();
        }
    }
    
    if (m_mediaPlayerProcess->state() != QProcess::NotRunning) {
        m_mediaPlayerProcess->terminate();
        if (!m_mediaPlayerProcess->waitForFinished(5000)) {
            m_mediaPlayerProcess->kill();
        }
    }
}

void ivi_compositor::checkClientStatus()
{
    // Check if clients have crashed and restart if needed
    if (m_autoLaunchClients) {
        if (m_gearSelectorProcess->state() == QProcess::NotRunning && !m_gearSelectorSurface) {
            qWarning() << "GearSelector not running, attempting restart...";
            launchGearSelector();
        }
        
        if (m_mediaPlayerProcess->state() == QProcess::NotRunning && !m_mediaPlayerSurface) {
            qWarning() << "MediaPlayer not running, attempting restart...";
            launchMediaPlayer();
        }
    }
}

void ivi_compositor::surfaceCreated(QWaylandSurface *surface)
{
    if (!surface) {
        return;
    }
    
    qDebug() << "Surface created:" << surface;
    
    // Try to identify the surface
    identifySurface(surface);
    
    // Connect to surface signals
    connect(surface, &QWaylandSurface::hasContentChanged, this, [this, surface]() {
        if (surface->hasContent()) {
            identifySurface(surface);
        }
    });
    
    connect(surface, &QWaylandSurface::surfaceDestroyed, this, [this, surface]() {
        surfaceAboutToBeDestroyed(surface);
    });
}

void ivi_compositor::identifySurface(QWaylandSurface *surface)
{
    if (!surface || !surface->client()) {
        return;
    }
    
    // Get the surface's window title from XdgSurface if available
    auto *xdgSurface = QWaylandXdgSurface::fromResource(surface->resource());
    if (xdgSurface && xdgSurface->toplevel()) {
        QString title = xdgSurface->toplevel()->title();
        qDebug() << "Surface identified via XdgSurface:" << title;
        
        auto *quickSurface = qobject_cast<QWaylandQuickSurface*>(surface);
        if (!quickSurface) {
            return;
        }
        
        if (title == "GearSelector") {
            m_gearSelectorSurface = quickSurface;
            m_surfaceAppMap[surface] = "GearSelector";
            emit surfacesChanged();
            emit clientConnected("GearSelector");
        } else if (title == "MediaPlayer") {
            m_mediaPlayerSurface = quickSurface;
            m_surfaceAppMap[surface] = "MediaPlayer";
            emit surfacesChanged();
            emit clientConnected("MediaPlayer");
        }
    }
}

void ivi_compositor::surfaceAboutToBeDestroyed(QWaylandSurface *surface)
{
    QString appName = m_surfaceAppMap.value(surface);
    
    if (surface == m_gearSelectorSurface) {
        m_gearSelectorSurface = nullptr;
        emit surfacesChanged();
        emit clientDisconnected("GearSelector");
        qDebug() << "GearSelector surface destroyed";
    } else if (surface == m_mediaPlayerSurface) {
        m_mediaPlayerSurface = nullptr;
        emit surfacesChanged();
        emit clientDisconnected("MediaPlayer");
        qDebug() << "MediaPlayer surface destroyed";
    }
    
    m_surfaceAppMap.remove(surface);
}

void ivi_compositor::handleXdgSurfaceCreated(QWaylandXdgSurface *xdgSurface)
{
    if (!xdgSurface) {
        return;
    }
    
    qDebug() << "XdgSurface created";
    
    // The actual surface identification happens in surfaceCreated
    // This is just for additional handling if needed
}

void ivi_compositor::onGearSelectorFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    qWarning() << "GearSelector process finished with exit code:" << exitCode 
               << "status:" << exitStatus;
    
    if (m_autoLaunchClients && exitStatus == QProcess::CrashExit) {
        qWarning() << "GearSelector crashed, will restart in 2 seconds...";
        QTimer::singleShot(2000, this, &ivi_compositor::launchGearSelector);
    }
}

void ivi_compositor::onMediaPlayerFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    qWarning() << "MediaPlayer process finished with exit code:" << exitCode 
               << "status:" << exitStatus;
    
    if (m_autoLaunchClients && exitStatus == QProcess::CrashExit) {
        qWarning() << "MediaPlayer crashed, will restart in 2 seconds...";
        QTimer::singleShot(2000, this, &ivi_compositor::launchMediaPlayer);
    }
}

void ivi_compositor::onGearSelectorError(QProcess::ProcessError error)
{
    qWarning() << "GearSelector process error:" << error << m_gearSelectorProcess->errorString();
}

void ivi_compositor::onMediaPlayerError(QProcess::ProcessError error)
{
    qWarning() << "MediaPlayer process error:" << error << m_mediaPlayerProcess->errorString();
}

QWaylandQuickSurface* ivi_compositor::gearSelectorSurface() const
{
    return m_gearSelectorSurface;
}

QWaylandQuickSurface* ivi_compositor::mediaPlayerSurface() const
{
    return m_mediaPlayerSurface;
}

bool ivi_compositor::autoLaunchClients() const
{
    return m_autoLaunchClients;
}

void ivi_compositor::setAutoLaunchClients(bool enable)
{
    if (m_autoLaunchClients != enable) {
        m_autoLaunchClients = enable;
        emit autoLaunchClientsChanged();
        
        if (enable && m_gearSelectorProcess->state() == QProcess::NotRunning) {
            m_launchTimer->start();
        }
    }
}
