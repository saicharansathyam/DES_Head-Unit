#include "ivi_compositor.h"
#include <QtWaylandCompositor/QWaylandIviSurface>
#include <QDebug>
#include <QTimer>

ivi_compositor::ivi_compositor(QObject *parent)
    : QWaylandQuickCompositor(parent)
{
    setSocketName("wayland-ivi");
    QTimer::singleShot(1000, this, &ivi_compositor::launchClients);
}

void ivi_compositor::surfaceCreated(QWaylandSurface *surface)
{
    // Check if this surface has an IVI extension
    QList<QWaylandSurfaceRole *> roles = surface->roles();
    for (QWaylandSurfaceRole *role : roles) {
        QWaylandIviSurface *iviSurface = qobject_cast<QWaylandIviSurface *>(role);
        if (iviSurface) {
            uint iviId = iviSurface->iviId();
            QWaylandQuickSurface *quickSurface = qobject_cast<QWaylandQuickSurface *>(surface);
            qDebug() << "IVI surface created with IVI ID:" << iviId;

            if (iviId == 1) {
                m_gearSelectorSurface = quickSurface;
                emit surfacesChanged();
            } else if (iviId == 2) {
                m_mediaPlayerSurface = quickSurface;
                emit surfacesChanged();
            }
            break;
        }
    }
}

void ivi_compositor::launchClients()
{
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert("WAYLAND_DISPLAY", "wayland-ivi");

    // Launch GearSelector with IVI ID 1
    m_gearSelectorProcess.setProcessEnvironment(env);
    m_gearSelectorProcess.start("/home/seame/Desktop/Aakash/DES_Head-Unit/HeadUnit/GearSelector/build/Desktop_Qt_6_9_1-Debug/appGearSelector", QStringList() << "--ivi-id=1");

    // Launch MediaPlayer with IVI ID 2
    m_mediaPlayerProcess.setProcessEnvironment(env);
    m_mediaPlayerProcess.start("/home/seame/Desktop/Aakash/DES_Head-Unit/HeadUnit/GearSelector/build/Desktop_Qt_6_9_1-Debug/appMediaPlayer", QStringList() << "--ivi-id=2");
}

QWaylandQuickSurface* ivi_compositor::gearSelectorSurface() const
{
    return m_gearSelectorSurface;
}

QWaylandQuickSurface* ivi_compositor::mediaPlayerSurface() const
{
    return m_mediaPlayerSurface;
}
