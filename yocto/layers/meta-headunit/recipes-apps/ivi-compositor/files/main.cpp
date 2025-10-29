// main.cpp
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDir>
#include <QDebug>
#include "dbus_manager.h"

int main(int argc, char *argv[])
{
    qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");

    QGuiApplication app(argc, argv);
    app.setOrganizationName("HeadUnit");
    app.setOrganizationDomain("com.headunit");
    app.setApplicationName("HeadUnit");

    // Create D-Bus manager (replaces ScriptExecutor)
    DBusManager dbusManager;

    QQmlApplicationEngine engine;

    // Expose D-Bus manager to QML
    engine.rootContext()->setContextProperty("dbusManager", &dbusManager);

    qDebug() << "=== Starting HeadUnit Compositor ===";
    qDebug() << "Platform:" << QGuiApplication::platformName();
    qDebug() << "Current directory:" << QDir::currentPath();

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

    qInfo() << "=== HeadUnit Compositor Ready ===";

    return app.exec();
}
