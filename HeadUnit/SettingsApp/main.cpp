#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>

#include "settingsmanager.h"
#include "wifimanager.h"
#include "bluetoothmanager.h"

int main(int argc, char *argv[])
{
    qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");
    qputenv("QT_IVI_SURFACE_ID", "1005");  // IVI ID for Settings App

    QGuiApplication app(argc, argv);

    app.setOrganizationName("HeadUnit");
    app.setOrganizationDomain("com.headunit");
    app.setApplicationName("SettingsApp");

    // Create managers
    WiFiManager wifiManager;
    BluetoothManager bluetoothManager;
    SettingsManager settingsManager(&wifiManager, &bluetoothManager);

    QQmlApplicationEngine engine;

    // Expose managers to QML
    engine.rootContext()->setContextProperty("settingsManager", &settingsManager);
    engine.rootContext()->setContextProperty("wifiManager", &wifiManager);
    engine.rootContext()->setContextProperty("bluetoothManager", &bluetoothManager);

    qDebug() << "Starting Settings Application...";
    qDebug() << "IVI Surface ID: 1006";

    const QUrl url(QStringLiteral("qrc:/qml/Main.qml"));

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl) {
                             qCritical() << "Failed to load Settings QML";
                             QCoreApplication::exit(-1);
                         }
                     }, Qt::QueuedConnection);

    engine.load(url);

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "No root objects loaded";
        return -1;
    }

    qDebug() << "Settings Application started successfully";

    return app.exec();
}

