#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "gs_handler.h"

int main(int argc, char *argv[])
{
    // Don't set QT_QPA_PLATFORM here - it should come from environment
    // when launched by the lifecycle manager

    QGuiApplication app(argc, argv);

    app.setOrganizationName("HeadUnit");
    app.setApplicationName("GearSelector");

    // Register GearHandler type
    qmlRegisterType<GS_Handler>("GearSelector", 1, 0, "GearHandler");

    QQmlApplicationEngine engine;

    const QUrl url(QStringLiteral("qrc:/Main.qml"));

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl) {
                             QCoreApplication::exit(-1);
                         }
                     }, Qt::QueuedConnection);

    engine.load(url);

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    qDebug() << "GearSelector application started";
    qDebug() << "Platform:" << QGuiApplication::platformName();

    return app.exec();
}
