#include <QGuiApplication>
#include <QQmlApplicationEngine>



int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;
    engine.loadFromModule("IVI_Compositor","Main");

    qputenv("WAYLAND_DISPLAY", "wayland-1");
    qputenv("QT_LOGGING_RULES", "qt6.*=true;qt6.platform.*=true;qt6.wayland.*=true");

    return app.exec();
}


