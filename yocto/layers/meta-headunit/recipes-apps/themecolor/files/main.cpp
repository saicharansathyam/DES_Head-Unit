#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "ThemeColorClient.h"

int main(int argc, char *argv[])
{
    // Trust systemd service environment:
    // - QT_QPA_PLATFORM=wayland      (set by service)
    // - WAYLAND_DISPLAY=wayland-2     (set by service)
    // - IVI_SURFACE_ID=1003           (set by service)
    
    QGuiApplication app(argc, argv);

    app.setApplicationName("ThemeColor");
    app.setOrganizationName("HeadUnit");

    QQmlApplicationEngine engine;

    ThemeColorClient themeClient;
    engine.rootContext()->setContextProperty("themeClient", &themeClient);

    const QUrl url(QStringLiteral("qrc:/Main.qml"));

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl) {
                             qCritical() << "Failed to load Main.qml";
                             QCoreApplication::exit(-1);
                         }
                     }, Qt::QueuedConnection);

    engine.load(url);

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "No QML objects loaded!";
        return -1;
    }

    qDebug() << "ThemeColor started successfully";

    return app.exec();
}
