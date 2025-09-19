#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "ivi_compositor.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    ivi_compositor compositor;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("iviCompositor", &compositor);

    engine.loadFromModule("IVI_Compositor", "Main");

    return app.exec();
}
