#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QtQuickControls2/QQuickStyle>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // Optional: use a customizable style
    QQuickStyle::setStyle("Basic");

    QQmlApplicationEngine engine;
    engine.load(QUrl(QStringLiteral("qrc:/GearSelector/Main.qml")));  // <-- Must match your qrc path

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
