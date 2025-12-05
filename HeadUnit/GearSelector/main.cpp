#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include "gs_handler.h"
#include "../theme_client.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    app.setApplicationName("GearSelector");
    app.setOrganizationName("HeadUnit");

    qDebug() << "Starting GearSelector...";

    // Create gear handler
    GS_Handler gearHandler;

    // Create theme client
    ThemeClient themeClient;

    QQmlApplicationEngine engine;

    // Expose to QML
    engine.rootContext()->setContextProperty("gearHandler", &gearHandler);
    engine.rootContext()->setContextProperty("theme", &themeClient);

    // Load QML from resources
    const QUrl url(QStringLiteral("qrc:/Main.qml"));

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl) {
                             qCritical() << "Failed to load Main.qml";
                             QCoreApplication::exit(-1);
                         }
                     }, Qt::QueuedConnection);

    qDebug() << "Loading QML from:" << url;
    engine.load(url);

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "No QML objects loaded!";
        return -1;
    }

    qDebug() << "GearSelector started successfully";

    return app.exec();
}
