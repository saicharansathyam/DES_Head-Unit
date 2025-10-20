#ifndef IVI_COMPOSITOR_H
#define IVI_COMPOSITOR_H

#include <QtWaylandCompositor/QWaylandQuickCompositor>
#include <QtWaylandCompositor/QWaylandQuickSurface>
#include <QtWaylandCompositor/QWaylandSeat>
#include <QObject>
#include <QProcess>
#include <QMap>
#include <QString>
#include <QTimer>

class QWaylandSurface;
class QWaylandXdgSurface;

class ivi_compositor : public QWaylandQuickCompositor
{
    Q_OBJECT
    Q_PROPERTY(QWaylandQuickSurface* gearSelectorSurface READ gearSelectorSurface NOTIFY surfacesChanged)
    Q_PROPERTY(QWaylandQuickSurface* mediaPlayerSurface READ mediaPlayerSurface NOTIFY surfacesChanged)
    Q_PROPERTY(bool autoLaunchClients READ autoLaunchClients WRITE setAutoLaunchClients NOTIFY autoLaunchClientsChanged)

public:
    explicit ivi_compositor(QObject *parent = nullptr);
    ~ivi_compositor();

    QWaylandQuickSurface* gearSelectorSurface() const;
    QWaylandQuickSurface* mediaPlayerSurface() const;
    
    bool autoLaunchClients() const;
    void setAutoLaunchClients(bool enable);
    
    Q_INVOKABLE void launchGearSelector();
    Q_INVOKABLE void launchMediaPlayer();
    Q_INVOKABLE void terminateClients();

signals:
    void surfacesChanged();
    void autoLaunchClientsChanged();
    void clientConnected(const QString &appName);
    void clientDisconnected(const QString &appName);
    void compositorReady();

protected:
    void surfaceCreated(QWaylandSurface *surface);
    void surfaceAboutToBeDestroyed(QWaylandSurface *surface);

private slots:
    void handleXdgSurfaceCreated(QWaylandXdgSurface *xdgSurface);
    void launchClients();
    void checkClientStatus();
    void onGearSelectorFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void onMediaPlayerFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void onGearSelectorError(QProcess::ProcessError error);
    void onMediaPlayerError(QProcess::ProcessError error);

private:
    QProcess *m_gearSelectorProcess;
    QProcess *m_mediaPlayerProcess;
    QWaylandQuickSurface* m_gearSelectorSurface;
    QWaylandQuickSurface* m_mediaPlayerSurface;
    QMap<QWaylandSurface*, QString> m_surfaceAppMap;
    bool m_autoLaunchClients;
    QTimer *m_launchTimer;
    QTimer *m_statusTimer;
    
    void setupProcesses();
    void connectProcessSignals();
    QString findExecutable(const QString &appName);
    void identifySurface(QWaylandSurface *surface);
};

#endif // IVI_COMPOSITOR_H