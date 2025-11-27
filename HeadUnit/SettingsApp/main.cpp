#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include "../theme_client.h"
#include "dbus_handler.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setOrganizationName("HeadUnit");
    app.setOrganizationDomain("com.headunit");
    app.setApplicationName("SettingsApp");

    // Only need D-Bus handler and theme
    DBusHandler dbusHandler;
    ThemeClient themeClient;

    QQmlApplicationEngine engine;

    // Expose only what's needed to QML
    engine.rootContext()->setContextProperty("dbusHandler", &dbusHandler);
    engine.rootContext()->setContextProperty("theme", &themeClient);

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
