#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "PiRacerBridge.h"

int main(int argc, char *argv[])
{
    // Force Wayland platform
    qputenv("QT_QPA_PLATFORM", "wayland");

    // Disable window decorations
    qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");

    // Set Wayland app_id before QGuiApplication
    qputenv("QT_WAYLAND_SHELL_INTEGRATION", "xdg-shell");

    QGuiApplication app(argc, argv);
    app.setOrganizationName("HeadUnit");
    app.setOrganizationDomain("com.headunit");
    app.setApplicationName("instrument-cluster");

    // Set desktop file name to match app-id for Wayland
    app.setDesktopFileName("instrument-cluster");

    qDebug() << "=== Starting Instrument Cluster (Wayland Client) ===";
    qDebug() << "Platform:" << QGuiApplication::platformName();
    qDebug() << "App-ID: instrument-cluster (HDMI-A-2)";

    QQmlApplicationEngine engine;

    PiRacerBridge bridge;
    bridge.initDBus();

    engine.rootContext()->setContextProperty("bridge", &bridge);

    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreated,
        &app, [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl) 
                QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection
    );

    engine.load(url);

    return app.exec();
}