#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "ThemeColorClient.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    app.setApplicationName("ThemeColor");
    app.setOrganizationName("HeadUnit");

    QQmlApplicationEngine engine;

    // Create ThemeColorClient instance
    ThemeColorClient themeClient;
    engine.rootContext()->setContextProperty("themeClient", &themeClient);

    // Load QML from resources
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


