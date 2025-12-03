// main.cpp - IVI Compositor as Wayland Client (Controller App)
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDir>
#include <QDebug>
#include "dbus_manager.h"

int main(int argc, char *argv[])
{
    // CRITICAL: Set IVI Surface ID for Weston IVI-Shell
    qputenv("IVI_SURFACE_ID", "1001");
    
    // Force Wayland platform (we're now a Wayland CLIENT, not compositor)
    qputenv("QT_QPA_PLATFORM", "wayland");
    
    // Disable window decorations
    qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");
    
    QGuiApplication app(argc, argv);
    app.setOrganizationName("HeadUnit");
    app.setOrganizationDomain("com.headunit");
    app.setApplicationName("HeadUnit");

    // Create D-Bus manager
    DBusManager dbusManager;

    QQmlApplicationEngine engine;
    
    // Expose D-Bus manager to QML
    engine.rootContext()->setContextProperty("dbusManager", &dbusManager);

    qDebug() << "=== Starting HeadUnit Controller (Wayland Client) ===";
    qDebug() << "Platform:" << QGuiApplication::platformName();
    qDebug() << "IVI Surface ID: 1001 (Layer 1000 -> HDMI-A-1)";
    qDebug() << "Current directory:" << QDir::currentPath();

    const QUrl url(QStringLiteral("qrc:/qml/Main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl) {
                             qCritical() << "Failed to load controller QML";
                             QCoreApplication::exit(-1);
                         }
                     }, Qt::QueuedConnection);

    engine.load(url);

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "No root objects loaded";
        return -1;
    }

    qInfo() << "=== HeadUnit Controller Ready ===";
    return app.exec();
}