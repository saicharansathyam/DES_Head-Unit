#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "PiRacerBridge.h"

int main(int argc, char *argv[])
{
    // CRITICAL: Set IVI Surface ID for Weston IVI-Shell
    qputenv("IVI_SURFACE_ID", "2001");
    
    // Force Wayland platform
    qputenv("QT_QPA_PLATFORM", "wayland");
    
    // Disable window decorations
    qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");
    
    QGuiApplication app(argc, argv);

    qDebug() << "=== Starting Instrument Cluster (Wayland Client) ===";
    qDebug() << "Platform:" << QGuiApplication::platformName();
    qDebug() << "IVI Surface ID: 2001 (Layer 2000 -> HDMI-A-2)";

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