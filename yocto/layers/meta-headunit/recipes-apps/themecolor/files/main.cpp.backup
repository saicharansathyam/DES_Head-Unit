#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "ThemeColorClient.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    ThemeColorClient themeClient;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("ThemeColorClient", &themeClient);

    engine.load(QUrl(QStringLiteral("ThemeColor/Main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}

