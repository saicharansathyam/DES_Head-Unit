#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtWebView/QtWebView>
#include <QQuickStyle>
#include <QDebug>
#include "mp_handler.h"
#include "../theme_client.h"
int main(int argc, char *argv[])
{
    // IMPORTANT: Enable virtual keyboard BEFORE creating QGuiApplication
    qputenv("QT_IM_MODULE", QByteArray("qtvirtualkeyboard"));

    // Initialize QtWebView
    QtWebView::initialize();

    // Set Wayland environment
    qputenv("QT_QPA_PLATFORM", "wayland");
    if (qEnvironmentVariableIsEmpty("WAYLAND_DISPLAY")) {
        qputenv("WAYLAND_DISPLAY", "wayland-1");
    }

    QQuickStyle::setStyle("Fusion");
    QGuiApplication app(argc, argv);

    ThemeClient themeClient;

    app.setApplicationName("MediaPlayer");
    app.setOrganizationName("HeadUnit");

    MP_Handler handler;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("mpHandler", &handler);
    engine.rootContext()->setContextProperty("theme", &themeClient);

    // Load Main.qml from resources
    const QUrl url(QStringLiteral("qrc:/qml/Main.qml"));

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl) {
                             qCritical() << "Failed to load QML";
                             QCoreApplication::exit(-1);
                         }
                     }, Qt::QueuedConnection);

    engine.load(url);

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "No root objects loaded";
        return -1;
    }

    qDebug() << "MediaPlayer with QtWebView and Virtual Keyboard started successfully";
    return app.exec();
}
