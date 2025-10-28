#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtWaylandCompositor>
#include <QDebug>
#include "ivi_compositor.h"

int main(int argc, char *argv[])
{
    qputenv("QT_QPA_PLATFORM", "eglfs");
    qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");
    qputenv("QT_LOGGING_RULES", "qt.waylandcompositor.*=false");
    
    // CRITICAL: Enable touch handling in compositor
    qputenv("QT_QPA_EGLFS_DISABLE_INPUT", "0");
    qputenv("QT_QPA_EVDEV_TOUCHSCREEN_PARAMETERS", "/dev/input/event1");
    
    // CRITICAL: Enable touch synthesis for compositor too
    QGuiApplication::setAttribute(Qt::AA_SynthesizeMouseForUnhandledTouchEvents, true);

    QGuiApplication app(argc, argv);
    app.setApplicationName("IVI_Compositor");
    app.setOrganizationName("HeadUnit");
    
    ivi_compositor Comp;

    qmlRegisterType<ivi_compositor>("IVI_Compositor", 1, 0, "IVICompositor");

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("applicationDirPath", app.applicationDirPath());
    engine.rootContext()->setContextProperty("compositor", &Comp);

    engine.loadFromModule("IVI_Compositor", "Main");
    if (engine.rootObjects().isEmpty()) {
        qCritical() << "Failed to load QML file";
        return -1;
    }

    qDebug() << "IVI Compositor started successfully";

    Comp.setAutoLaunchClients(true);

    return app.exec();
}