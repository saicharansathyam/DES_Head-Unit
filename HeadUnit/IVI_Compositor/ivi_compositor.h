#ifndef IVI_COMPOSITOR_H
#define IVI_COMPOSITOR_H

#include <QtWaylandCompositor/QWaylandQuickCompositor>
#include <QtWaylandCompositor/QWaylandQuickSurface>
#include <QObject>
#include <QProcess>
#include <QMap>

class ivi_compositor : public QWaylandQuickCompositor
{
    Q_OBJECT
    Q_PROPERTY(QWaylandQuickSurface* gearSelectorSurface READ gearSelectorSurface NOTIFY surfacesChanged)
    Q_PROPERTY(QWaylandQuickSurface* mediaPlayerSurface READ mediaPlayerSurface NOTIFY surfacesChanged)
public:
    explicit ivi_compositor(QObject *parent = nullptr);

    QWaylandQuickSurface* gearSelectorSurface() const;
    QWaylandQuickSurface* mediaPlayerSurface() const;

signals:
    void surfacesChanged();

protected:
    void surfaceCreated(QWaylandSurface *surface) ;

private:
    QProcess m_gearSelectorProcess;
    QProcess m_mediaPlayerProcess;
    QWaylandQuickSurface* m_gearSelectorSurface = nullptr;
    QWaylandQuickSurface* m_mediaPlayerSurface = nullptr;

    void launchClients();
};

#endif // IVI_COMPOSITOR_H
