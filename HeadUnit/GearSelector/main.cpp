#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "gs_handler.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    qmlRegisterType<GS_Handler>("GearSelector", 1, 0, "GearHandler");

    QQmlApplicationEngine engine;
    engine.load(QUrl(QStringLiteral("qrc:/GearSelector/Main.qml")));

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
