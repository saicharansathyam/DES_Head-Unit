#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "gs_handler.h"

int main(int argc, char *argv[])
{
    // Trust systemd service environment:
    // - QT_QPA_PLATFORM=wayland      (set by service)
    // - WAYLAND_DISPLAY=wayland-2     (set by service)
    // - IVI_SURFACE_ID=1001           (set by service)
    
    QGuiApplication app(argc, argv);
    app.setOrganizationName("HeadUnit");
    app.setApplicationName("GearSelector");

    GS_Handler handler;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("gearHandler", &handler);
    
    const QUrl url(QStringLiteral("qrc:/Main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    
    engine.load(url);

    return app.exec();
}
