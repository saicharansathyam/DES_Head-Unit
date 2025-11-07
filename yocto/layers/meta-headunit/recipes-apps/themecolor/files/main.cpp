#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "ThemeColorClient.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    
    // Create theme client
    ThemeColorClient themeClient;
    
    // Setup QML engine
    QQmlApplicationEngine engine;
    
    // Register ThemeColorClient as QML type
    qmlRegisterType<ThemeColorClient>("ThemeColor", 1, 0, "ThemeColorClient");
    
    // Load QML from Qt resource system
    const QUrl url(u"qrc:/qt/qml/ThemeColor/Main.qml"_qs);
    
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreated,
        &app, [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection
    );
    
    engine.load(url);
    
    if (engine.rootObjects().isEmpty())
        return -1;
    
    return app.exec();
}
