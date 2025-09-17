#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QDebug>
#include <QProcess>

#ifdef Q_OS_UNIX
#include <QtDBus/QDBusConnection>
#include <QtDBus/QDBusInterface>
#endif

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;


    const QUrl url(QStringLiteral("qrc:/head-unit/Main.qml"));

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl)
                             QCoreApplication::exit(-1);
                     }, Qt::QueuedConnection);

    engine.load(url);

    #ifdef Q_OS_UNIX
    // Connect to system bus (Linux only)
    if (!QDBusConnection::systemBus().isConnected()) {
        qWarning() << "Cannot connect to the D-Bus system bus";
    }
    #endif


    return app.exec();
}

#include "main.moc"
