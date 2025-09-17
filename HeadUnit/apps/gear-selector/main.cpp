#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QObject>
#include <QDebug>

#ifdef Q_OS_UNIX
#include <QtDBus/QtDBus>
#endif

class GearController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString currentGear READ currentGear NOTIFY gearChanged)
public:
    explicit GearController(QObject *parent = nullptr) : QObject(parent) {}

    QString currentGear() const { return m_gear; }

    Q_INVOKABLE void setGear(const QString &gear) {
        m_gear = gear;
        emit gearChanged(m_gear);

#ifdef Q_OS_UNIX
        QDBusInterface iface("org.vehicle.GearService", "/", "org.vehicle.Gear", QDBusConnection::sessionBus());
        if (iface.isValid())
            iface.call("setGear", gear);
#endif
    }

signals:
    void gearChanged(const QString &gear);

private:
    QString m_gear = "P";
};

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    GearController gcontrol;
    engine.rootContext()->setContextProperty("gControl", &gcontrol);

    engine.load(QUrl(QStringLiteral("qrc:/gear-selector/GearSelector.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}

#include "main.moc"
