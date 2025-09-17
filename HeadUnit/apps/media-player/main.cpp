#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QObject>
#include <QDebug>

#ifdef Q_OS_UNIX
#include <QtDBus/QtDBus>
#endif

class MediaController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString currentTrack READ currentTrack NOTIFY trackChanged)
public:
    explicit MediaController(QObject *parent = nullptr) : QObject(parent) {}

    QString currentTrack() const { return m_currentTrack; }

    Q_INVOKABLE void playTrack1() { setTrackInternal("Track 1"); }
    Q_INVOKABLE void playTrack2() { setTrackInternal("Track 2"); }
    Q_INVOKABLE void playTrack3() { setTrackInternal("Track 3"); }

signals:
    void trackChanged(const QString &track);

private:
    QString m_currentTrack = "None";

    void setTrackInternal(const QString &track) {
        if (m_currentTrack == track) return;
        m_currentTrack = track;
        emit trackChanged(m_currentTrack);

#ifdef Q_OS_UNIX
        QDBusInterface iface("org.vehicle.MediaService", "/", "org.vehicle.Media", QDBusConnection::sessionBus());
        if (iface.isValid()) iface.call("playTrack", track);
#endif
    }
};

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    MediaController controller;
    engine.rootContext()->setContextProperty("MediaController", &controller);

    engine.load(QUrl(QStringLiteral("qrc:/media-player/MediaPlayer.qml")));
    if (engine.rootObjects().isEmpty()) return -1;

    return app.exec();
}

#include "main.moc"
