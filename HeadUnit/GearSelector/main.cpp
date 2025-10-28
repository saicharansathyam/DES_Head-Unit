#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "gs_handler.h"

int main(int argc, char *argv[])
{
    // CRITICAL: Enable touch-to-mouse synthesis
    QGuiApplication::setAttribute(Qt::AA_SynthesizeMouseForUnhandledTouchEvents, true);
    
    // CRITICAL: Also enable mouse-to-touch (some systems need this)
    QGuiApplication::setAttribute(Qt::AA_SynthesizeTouchForUnhandledMouseEvents, true);

    qputenv("QT_QPA_PLATFORM", "wayland");
    qputenv("WAYLAND_DISPLAY", "wayland-1");
    qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");
    
    // DEBUG: Enable input debugging
    qputenv("QT_LOGGING_RULES", "qt.qpa.input*=true");

    QGuiApplication app(argc, argv);
    app.setApplicationName("GearSelector");

    // Create handler
    GS_Handler gsHandler;

    QQmlApplicationEngine engine;
    
    // CRITICAL: Register handler with QML
    engine.rootContext()->setContextProperty("gsHandler", &gsHandler);
    
    // Load the TEST QML
    engine.load(QUrl(QStringLiteral("qrc:/Main_Test.qml")));
    
    if (engine.rootObjects().isEmpty()) {
        qCritical() << "Failed to load QML";
        return -1;
    }

    return app.exec();
}