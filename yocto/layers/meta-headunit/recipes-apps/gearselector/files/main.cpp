#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

int main(int argc, char *argv[])
{
    // Enable touch input
    qputenv("QT_QPA_PLATFORM", "wayland");
    qputenv("QT_LOGGING_RULES", "qt.qpa.input=true");
    
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;
    
    engine.load(QUrl(QStringLiteral("qrc:/Main_Test.qml")));
    
    if (engine.rootObjects().isEmpty()) {
        qCritical() << "Failed to load QML";
        return -1;
    }
    
    qDebug() << "GearSelector started";
    return app.exec();
}
