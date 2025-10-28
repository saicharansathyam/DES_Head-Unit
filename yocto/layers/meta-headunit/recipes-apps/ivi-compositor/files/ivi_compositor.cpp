#include "ivi_compositor.h"
#include <QtWaylandCompositor/QWaylandSurface>
#include <QtWaylandCompositor/QWaylandXdgShell>
#include <QtWaylandCompositor/QWaylandXdgSurface>
#include <QtWaylandCompositor/QWaylandWlShell>
#include <QtWaylandCompositor/QWaylandWlShellSurface>
#include <QDebug>
#include <QDir>
#include <QCoreApplication>
#include <QFileInfo>

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
    setSocketName("wayland-1");
    setupProcesses();

    m_launchTimer = new QTimer(this);
    m_launchTimer->setSingleShot(true);
    m_launchTimer->setInterval(1000);
    connect(m_launchTimer, &QTimer::timeout, this, &ivi_compositor::launchClients);

    m_statusTimer = new QTimer(this);
    m_statusTimer->setInterval(5000);
    connect(m_statusTimer, &QTimer::timeout, this, &ivi_compositor::checkClientStatus);

    connect(this, &QWaylandCompositor::surfaceCreated, this, &ivi_compositor::surfaceCreated);

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

    if (m_gearSelectorProcess) delete m_gearSelectorProcess;
    if (m_mediaPlayerProcess) delete m_mediaPlayerProcess;
}

void ivi_compositor::setupProcesses()
{
    m_gearSelectorProcess = new QProcess(this);
    m_mediaPlayerProcess  = new QProcess(this);

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
    connect(m_gearSelectorProcess,
            QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &ivi_compositor::onGearSelectorFinished);

    connect(m_gearSelectorProcess, &QProcess::errorOccurred,
            this, &ivi_compositor::onGearSelectorError);

    connect(m_mediaPlayerProcess,
            QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &ivi_compositor::onMediaPlayerFinished);

    connect(m_mediaPlayerProcess, &QProcess::errorOccurred,
            this, &ivi_compositor::onMediaPlayerError);
}

QString ivi_compositor::findExecutable(const QString &appName)
{
    QStringList searchPaths;
    searchPaths << QCoreApplication::applicationDirPath() + "/" + appName;
    searchPaths << QCoreApplication::applicationDirPath() + "/../" + appName + "/" + appName;
    searchPaths << QCoreApplication::applicationDirPath() + "/../" + appName + "/build/" + appName;

    QString buildDir = QDir::currentPath();
    searchPaths << buildDir + "/" + appName + "/" + appName;
    searchPaths << buildDir + "/" + appName + "/build/" + appName;
    searchPaths << buildDir + + "/../" + appName + "/build/" + appName;
    searchPaths << "/usr/local/bin/" + appName;
    searchPaths << "/usr/bin/" + appName;

    for (const QString &path : searchPaths) {
        QFileInfo fileInfo(path);
        if (fileInfo.exists() && fileInfo.isExecutable()) {
            qDebug() << "Found executable:" << path;
            return fileInfo.absoluteFilePath();
        }

        QString appPath = path;
        appPath.replace(appName, QStringLiteral("app") + appName);
        QFileInfo appFileInfo(appPath);
        if (appFileInfo.exists() && appFileInfo.isExecutable()) {
            qDebug() << "Found executable:" << appPath;
            return appFileInfo.absoluteFilePath();
        }
    }

    qWarning() << "Could not find executable for:" << appName;
    return QString();
}

void ivi_compositor::launchGearSelector()
{
    if (!m_gearSelectorProcess) {
        m_gearSelectorProcess = new QProcess(this);
        QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
        env.insert("QT_QPA_PLATFORM", "wayland");
        env.insert("WAYLAND_DISPLAY", "wayland-1");
        env.insert("XDG_RUNTIME_DIR", qgetenv("XDG_RUNTIME_DIR"));
        env.insert("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");
        m_gearSelectorProcess->setProcessEnvironment(env);
        connectProcessSignals();
    }

    if (m_gearSelectorProcess->state() == QProcess::NotRunning) {
        qDebug() << "Launching GearSelector";
        m_gearSelectorProcess->start("/usr/bin/GearSelector");
        if (m_gearSelectorProcess->waitForStarted(3000)) {
            qDebug() << "GearSelector launched successfully";
        } else {
            qWarning() << "Failed to start GearSelector:" << m_gearSelectorProcess->errorString();
        }
    }
}

void ivi_compositor::launchMediaPlayer()
{
    if (!m_mediaPlayerProcess) {
        m_mediaPlayerProcess = new QProcess(this);
        QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
        env.insert("QT_QPA_PLATFORM", "wayland");
        env.insert("WAYLAND_DISPLAY", "wayland-1");
        env.insert("XDG_RUNTIME_DIR", qgetenv("XDG_RUNTIME_DIR"));
        env.insert("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");
        m_mediaPlayerProcess->setProcessEnvironment(env);
        connectProcessSignals();
    }

    if (m_mediaPlayerProcess->state() == QProcess::NotRunning) {
        qDebug() << "Launching MediaPlayer";
        m_mediaPlayerProcess->start("/usr/bin/MediaPlayer");
        if (m_mediaPlayerProcess->waitForStarted(3000)) {
            qDebug() << "MediaPlayer launched successfully";
        } else {
            qWarning() << "Failed to start MediaPlayer:" << m_mediaPlayerProcess->errorString();
        }
    }
}

void ivi_compositor::launchClients()
{
    qDebug() << "Launching client applications...";
    launchGearSelector();
    launchMediaPlayer();
    m_statusTimer->start();
}

void ivi_compositor::terminateClients()
{
    qDebug() << "Terminating client applications...";

    if (m_gearSelectorProcess && m_gearSelectorProcess->state() != QProcess::NotRunning) {
        m_gearSelectorProcess->terminate();
        if (!m_gearSelectorProcess->waitForFinished(5000)) m_gearSelectorProcess->kill();
    }

    if (m_mediaPlayerProcess && m_mediaPlayerProcess->state() != QProcess::NotRunning) {
        m_mediaPlayerProcess->terminate();
        if (!m_mediaPlayerProcess->waitForFinished(5000)) m_mediaPlayerProcess->kill();
    }
}

void ivi_compositor::checkClientStatus()
{
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
    if (!surface) return;

    qDebug() << "Surface created:" << surface;
    identifySurface(surface);

    connect(surface, &QWaylandSurface::hasContentChanged, this, [this, surface]() {
        if (surface->hasContent()) identifySurface(surface);
    });

    connect(surface, &QWaylandSurface::surfaceDestroyed, this, [this, surface]() {
        surfaceAboutToBeDestroyed(surface);
    });
}

void ivi_compositor::identifySurface(QWaylandSurface *surface)
{
    if (!surface || !surface->client()) return;

    auto *xdgSurface = QWaylandXdgSurface::fromResource(surface->resource());
    if (xdgSurface && xdgSurface->toplevel()) {
        QString title = xdgSurface->toplevel()->title();
        qDebug() << "Surface identified:" << title;

        auto *quickSurface = qobject_cast<QWaylandQuickSurface*>(surface);
        if (!quickSurface) return;

        if (title == "GearSelector") {
            m_gearSelectorSurface = quickSurface;
            m_surfaceAppMap[surface] = "GearSelector";
            emit surfacesChanged();
            emit clientConnected("GearSelector");
            grantFocus(quickSurface);
        } else if (title == "MediaPlayer") {
            m_mediaPlayerSurface = quickSurface;
            m_surfaceAppMap[surface] = "MediaPlayer";
            emit surfacesChanged();
            emit clientConnected("MediaPlayer");
            grantFocus(quickSurface);
        }
    }
}

void ivi_compositor::surfaceAboutToBeDestroyed(QWaylandSurface *surface)
{
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
    Q_UNUSED(xdgSurface)
    qDebug() << "XdgSurface created";
}

void ivi_compositor::onGearSelectorFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    qWarning() << "GearSelector finished:" << exitCode << exitStatus;
    if (m_autoLaunchClients && exitStatus == QProcess::CrashExit) {
        qWarning() << "GearSelector crashed, restarting...";
        QTimer::singleShot(2000, this, &ivi_compositor::launchGearSelector);
    }
}

void ivi_compositor::onMediaPlayerFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    qWarning() << "MediaPlayer finished:" << exitCode << exitStatus;
    if (m_autoLaunchClients && exitStatus == QProcess::CrashExit) {
        qWarning() << "MediaPlayer crashed, restarting...";
        QTimer::singleShot(2000, this, &ivi_compositor::launchMediaPlayer);
    }
}

void ivi_compositor::onGearSelectorError(QProcess::ProcessError error)
{
    qWarning() << "GearSelector error:" << error << m_gearSelectorProcess->errorString();
}

void ivi_compositor::onMediaPlayerError(QProcess::ProcessError error)
{
    qWarning() << "MediaPlayer error:" << error << m_mediaPlayerProcess->errorString();
}

QWaylandQuickSurface* ivi_compositor::gearSelectorSurface() const { return m_gearSelectorSurface; }
QWaylandQuickSurface* ivi_compositor::mediaPlayerSurface() const  { return m_mediaPlayerSurface; }

bool ivi_compositor::autoLaunchClients() const { return m_autoLaunchClients; }

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

// CORRECTED: Enhanced focus helper with proper QWaylandView handling
void ivi_compositor::grantFocus(QWaylandQuickSurface *surface)
{
    if (!surface) {
        qWarning() << "grantFocus: null surface!";
        return;
    }
    
    if (auto *seat = defaultSeat()) {
        qDebug() << "=== GRANTING FOCUS TO SURFACE ===" << surface;
        
        // Set keyboard focus
        seat->setKeyboardFocus(surface);
        
        // Set mouse focus - need to get the view from the surface
        if (!surface->views().isEmpty()) {
            QWaylandView *view = surface->views().first();
            seat->setMouseFocus(view);
            
            // CRITICAL: Also send a pointer enter event
            QPointF localPos(surface->destinationSize().width() / 2, 
                            surface->destinationSize().height() / 2);
            seat->sendMouseMoveEvent(view, localPos, localPos);
            
            qDebug() << "Input focus granted successfully";
        } else {
            qWarning() << "Surface has no views!";
        }
    } else {
        qWarning() << "No seat available to set focus!";
    }
}

// Convenience for QML buttons/tabs in compositor UI
void ivi_compositor::focusApp(const QString &name)
{
    if (name == "GearSelector" && m_gearSelectorSurface) {
        grantFocus(m_gearSelectorSurface);
    } else if (name == "MediaPlayer" && m_mediaPlayerSurface) {
        grantFocus(m_mediaPlayerSurface);
    } else {
        qWarning() << "focusApp: unknown or missing surface for" << name;
    }
}
