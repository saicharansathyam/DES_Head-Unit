#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtQuickControls2/QQuickStyle>  // instead of <QQuickStyle>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QUrl>
#include "mp_handler.h"

int main(int argc, char *argv[])
{
    // Set Wayland environment BEFORE creating QGuiApplication
    // This ensures Qt initializes with the correct platform plugin
    qputenv("QT_QPA_PLATFORM", "wayland");
    
    // Check if WAYLAND_DISPLAY is already set (by compositor)
    // If not, set it to the expected socket name
    if (qEnvironmentVariableIsEmpty("WAYLAND_DISPLAY")) {
        qputenv("WAYLAND_DISPLAY", "wayland-1");
    }
    
    // Enable Wayland debug logging for troubleshooting
    qputenv("QT_LOGGING_RULES", "qt.qpa.wayland*=true");
    
    // Set the Quick Controls style (optional, for better visuals)
    QQuickStyle::setStyle("Fusion");
    
    QGuiApplication app(argc, argv);
    
    // Set application name - this will be the window title
    // The compositor uses this to identify which surface belongs to which app
    app.setApplicationName("MediaPlayer");
    app.setOrganizationName("HeadUnit");
    app.setOrganizationDomain("com.headunit");
    
    // Register the MediaPlayer handler type for QML
    qmlRegisterType<MP_Handler>("MediaPlayer", 1, 0, "MPHandler");
    
    QQmlApplicationEngine engine;
    
    // Set up context properties if needed
    engine.rootContext()->setContextProperty("applicationDirPath", app.applicationDirPath());
    
    // Determine the correct path for loading QML
    QUrl url;
    
    // First try to load from Qt resource system
    if (QFile::exists(":/MediaPlayer/Main.qml")) {
        url = QUrl(QStringLiteral("qrc:/MediaPlayer/Main.qml"));
        qDebug() << "Loading QML from resource system";
    }
    // Fallback to file system (for development)
    else {
        QString qmlPath = QDir::currentPath() + "/MediaPlayer/Main.qml";
        if (QFile::exists(qmlPath)) {
            url = QUrl::fromLocalFile(qmlPath);
            qDebug() << "Loading QML from file system:" << qmlPath;
        } else {
            // Try one more location (build directory structure)
            qmlPath = app.applicationDirPath() + "/MediaPlayer/Main.qml";
            if (QFile::exists(qmlPath)) {
                url = QUrl::fromLocalFile(qmlPath);
                qDebug() << "Loading QML from app directory:" << qmlPath;
            } else {
                // Last resort - try resource with standard naming
                url = QUrl(QStringLiteral("qrc:/MediaPlayer/Main.qml"));
                qDebug() << "Attempting to load from resources as last resort";
            }
        }
    }
    
    // Handle object creation errors
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            qCritical() << "Failed to load QML file:" << url;
            QCoreApplication::exit(-1);
        }
    }, Qt::QueuedConnection);
    
    // Load the QML file
    engine.load(url);
    
    if (engine.rootObjects().isEmpty()) {
        qCritical() << "No root objects loaded from QML";
        return -1;
    }
    
    qDebug() << "MediaPlayer started successfully";
    qDebug() << "Wayland display:" << qgetenv("WAYLAND_DISPLAY");
    qDebug() << "QPA platform:" << qgetenv("QT_QPA_PLATFORM");
    
    return app.exec();
}