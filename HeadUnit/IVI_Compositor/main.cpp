#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QtWaylandCompositor>
#include <QQuickView>
#include <QDebug>

int main(int argc, char *argv[])
{
    // DO NOT set QT_QPA_PLATFORM=wayland for the compositor!
    // The compositor creates a Wayland server, it doesn't connect to one
    // It should use the native platform (X11, eglfs, etc.)

    // Only disable window decorations if needed
    qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");

    QGuiApplication app(argc, argv);

    // Set application metadata
    app.setOrganizationName("HeadUnit");
    app.setOrganizationDomain("com.headunit");
    app.setApplicationName("HeadUnit");

    QQmlApplicationEngine engine;

    qDebug() << "Starting HeadUnit Compositor...";
    qDebug() << "Platform:" << QGuiApplication::platformName();

    const QUrl url(QStringLiteral("qrc:/qml/Main.qml"));

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl) {
                             qCritical() << "Failed to load compositor QML";
                             QCoreApplication::exit(-1);
                         }
                     }, Qt::QueuedConnection);

    engine.load(url);

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "No root objects loaded";
        return -1;
    }

    qDebug() << "HeadUnit Compositor started successfully";

    return app.exec();
}
