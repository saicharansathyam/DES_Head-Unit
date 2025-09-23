#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include <QFile>
#include <QDir>
#include "gs_handler.h"

int main(int argc, char *argv[])
{
    // Set Wayland environment BEFORE creating QGuiApplication
    qputenv("QT_QPA_PLATFORM", "wayland");
    
    if (qEnvironmentVariableIsEmpty("WAYLAND_DISPLAY")) {
        qputenv("WAYLAND_DISPLAY", "wayland-1");
    }
    
    qputenv("QT_LOGGING_RULES", "qt.qpa.wayland*=true");
    
    QGuiApplication app(argc, argv);
    app.setApplicationName("GearSelector");
    app.setOrganizationName("HeadUnit");
    
    // Register the GearHandler type for QML
    qmlRegisterType<GS_Handler>("GearSelector", 1, 0, "GearHandler");
    
    QQmlApplicationEngine engine;
    
    // Try to load from resources first
    QUrl url(QStringLiteral("qrc:/Main.qml"));
    
    // If resource doesn't exist, try file path
    if (!QFile::exists(":/Main.qml")) {
        QString currentPath = QDir::currentPath();
        QString qmlFile = currentPath + "/../Main.qml";
        if (QFile::exists(qmlFile)) {
            url = QUrl::fromLocalFile(qmlFile);
            qDebug() << "Loading QML from file:" << qmlFile;
        } else {
            qCritical() << "Cannot find Main.qml";
            return -1;
        }
    } else {
        qDebug() << "Loading QML from resources";
    }
    
    engine.load(url);
    
    if (engine.rootObjects().isEmpty()) {
        qCritical() << "Failed to load QML";
        return -1;
    }
    
    qDebug() << "GearSelector started";
    qDebug() << "Wayland display:" << qgetenv("WAYLAND_DISPLAY");
    
    return app.exec();
}