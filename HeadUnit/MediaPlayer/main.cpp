#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QDir>
#include "mp_handler.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    qmlRegisterType<MP_Handler>("MediaPlayer", 1, 0, "MPHandler");

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.load(QUrl::fromLocalFile(QDir::currentPath() + "/MediaPlayer/Main.qml"));

    return app.exec();
}
