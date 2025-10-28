#include <QGuiApplication>
#include <QQmlApplicationEngine>

int main(int argc, char *argv[])
{
    // Enable touch input debugging
    qputenv("QT_LOGGING_RULES", "qt.qpa.input=true");
    
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;
    
    engine.load(QUrl(QStringLiteral("qrc:/Main.qml")));
    
    if (engine.rootObjects().isEmpty()) {
        qCritical() << "Failed to load QML";
        return -1;
    }
    
    qDebug() << "IVI Compositor started";
    return app.exec();
}