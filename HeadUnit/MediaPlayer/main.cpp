#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QDir>
#include "mp_handler.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("MediaPlayer");

    qmlRegisterType<MP_Handler>("MediaPlayer", 1, 0, "MPHandler");

    QQmlApplicationEngine engine;
    engine.load(QUrl::fromLocalFile(QDir::currentPath() + "/MediaPlayer/Main.qml"));

    if (engine.rootObjects().isEmpty()) {
        qWarning("Failed to load QML file");
        return -1;
    }

    // Configure as Wayland client with xdg-shell
    qputenv("WAYLAND_DISPLAY", "wayland-1");
    qputenv("QT_LOGGING_RULES", "qt6.*=true;qt6.platform.*=true;qt6.wayland.*=true");

    return app.exec();
}
