#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtWaylandCompositor>
#include <QDebug>
#include "ivi_compositor.h"

int main(int argc, char *argv[])
{
    qputenv("QT_QPA_PLATFORM", "wayland");
    qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");
    qputenv("QT_LOGGING_RULES", "qt.waylandcompositor.*=true");

    QGuiApplication app(argc, argv);
    app.setApplicationName("IVI_Compositor");
    app.setOrganizationName("HeadUnit");
    ivi_compositor Comp;

    qmlRegisterType<ivi_compositor>("IVI_Compositor", 1, 0, "IVICompositor");

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("applicationDirPath", app.applicationDirPath());
    // Ensure the application directory is on the QML import path so loadFromModule can find the local module
    engine.addImportPath(app.applicationDirPath());

    // >>> CHANGE HERE: load by module URI + type name
    engine.loadFromModule("IVI_Compositor", "Main");
    if (engine.rootObjects().isEmpty()) {
        qCritical() << "Failed to load QML file";
        return -1;
    }

    qDebug() << "IVI Compositor started successfully";
    qDebug() << "Wayland socket name will be set by QML compositor";

    Comp.setAutoLaunchClients(true);

    return app.exec();
}
