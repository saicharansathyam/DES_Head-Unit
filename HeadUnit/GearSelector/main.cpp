#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "gs_handler.h"

int main(int argc, char *argv[])
{

    QGuiApplication app(argc, argv);
    app.setApplicationName("GearSelector"); // Set title for xdg-shell

    qmlRegisterType<GS_Handler>("GearSelector", 1, 0, "GearHandler");

    QQmlApplicationEngine engine;
    engine.load(QUrl(QStringLiteral("qrc:/GearSelector/Main.qml")));

    if (engine.rootObjects().isEmpty())
        return -1;

    // Configure as Wayland client with xdg-shell
    qputenv("WAYLAND_DISPLAY", "wayland-1");
    qputenv("QT_LOGGING_RULES", "qt6.*=true;qt6.platform.*=true;qt6.wayland.*=true");

    return app.exec();
}
