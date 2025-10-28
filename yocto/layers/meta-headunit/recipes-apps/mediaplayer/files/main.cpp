#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "mp_handler.h"

int main(int argc, char *argv[])
{
    // CRITICAL: Enable touch synthesis
    QGuiApplication::setAttribute(Qt::AA_SynthesizeMouseForUnhandledTouchEvents, true);
    QGuiApplication::setAttribute(Qt::AA_SynthesizeTouchForUnhandledMouseEvents, true);

    qputenv("QT_QPA_PLATFORM", "wayland");
    qputenv("WAYLAND_DISPLAY", "wayland-1");
    qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");
    
    // DEBUG
    qputenv("QT_LOGGING_RULES", "qt.qpa.input*=true");

    QGuiApplication app(argc, argv);
    app.setApplicationName("MediaPlayer");

    MP_Handler mpHandler;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("mpHandler", &mpHandler);
    
    engine.load(QUrl(QStringLiteral("qrc:/Main_Test.qml")));
    
    if (engine.rootObjects().isEmpty()) {
        qCritical() << "Failed to load QML";
        return -1;
    }

    return app.exec();
}