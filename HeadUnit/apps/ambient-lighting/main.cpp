#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QObject>
#include <QDebug>
#include <QtDBus/QtDBus>

class AmbientController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString currentColor READ currentColor NOTIFY colorChanged)
public:
    explicit AmbientController(QObject *parent = nullptr) : QObject(parent) {}

    QString currentColor() const { return m_color; }

    Q_INVOKABLE void setRed()   { setColorInternal("Red"); }
    Q_INVOKABLE void setGreen() { setColorInternal("Green"); }
    Q_INVOKABLE void setBlue()  { setColorInternal("Blue"); }

signals:
    void colorChanged(const QString &color);

private:
    QString m_color = "Off";

    void setColorInternal(const QString &color) {
        if (m_color == color) return;
        m_color = color;
        emit colorChanged(m_color);

#ifdef Q_OS_UNIX
        QDBusInterface iface("org.vehicle.AmbientService", "/", "org.vehicle.Ambient", QDBusConnection::sessionBus());
        if (iface.isValid()) iface.call("setColor", color);
#endif
    }
};

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    AmbientController controller;
    engine.rootContext()->setContextProperty("AmbientController", &controller);

    engine.load(QUrl(QStringLiteral("qrc:/ambient-lighting/AmbientLighting.qml")));
    if (engine.rootObjects().isEmpty()) return -1;

    return app.exec();
}

#include "main.moc"
