#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QDebug>
#include "mp_handler.h"

int main(int argc, char *argv[])
{
    // Trust systemd service environment:
    // - QT_QPA_PLATFORM=wayland      (set by service)
    // - WAYLAND_DISPLAY=wayland-2     (set by service)
    // - IVI_SURFACE_ID=1002           (set by service)
    //
    // DO NOT override these - they must come from systemd!
    
    // Enable virtual keyboard BEFORE creating QGuiApplication
    qputenv("QT_IM_MODULE", QByteArray("qtvirtualkeyboard"));

    QQuickStyle::setStyle("Fusion");
    QGuiApplication app(argc, argv);

    app.setApplicationName("MediaPlayer");
    app.setOrganizationName("HeadUnit");

    MP_Handler handler;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("mpHandler", &handler);

    // Load Main.qml from resources
    const QUrl url(QStringLiteral("qrc:/qml/Main.qml"));

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl) {
                             qCritical() << "Failed to load QML";
                             QCoreApplication::exit(-1);
                         }
                     }, Qt::QueuedConnection);

    engine.load(url);

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "No root objects loaded";
        return -1;
    }

    qDebug() << "MediaPlayer started successfully";
    return app.exec();
}
