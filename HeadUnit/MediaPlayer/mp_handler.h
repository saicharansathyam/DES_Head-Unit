#ifndef MP_HANDLER_H
#define MP_HANDLER_H

#include <QObject>
#include <QString>
#include <QUrl>
#include <QtDBus/QDBusInterface>
#include <QtDBus/QDBusConnection>
#include <QtDBus/QDBusMessage>
#include <QtDBus/QDBusError>
#include <QTimer>

class MP_Handler : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(bool playing READ playing NOTIFY playingChanged)
    Q_PROPERTY(int volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(qint64 position READ position WRITE setPosition NOTIFY positionChanged)
    Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(QString currentState READ currentState NOTIFY currentStateChanged)

public:
    explicit MP_Handler(QObject *parent = nullptr);
    ~MP_Handler();

    QString source() const;
    void setSource(const QString &src);

    bool playing() const;
    
    int volume() const;
    void setVolume(int vol);
    
    qint64 position() const;
    void setPosition(qint64 pos);
    
    qint64 duration() const;
    void setDuration(qint64 dur);
    
    QString currentState() const;

    Q_INVOKABLE void play();
    Q_INVOKABLE void pause();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void next();
    Q_INVOKABLE void previous();
    Q_INVOKABLE void seek(qint64 position);

signals:
    void sourceChanged();
    void playingChanged();
    void volumeChanged();
    void positionChanged();
    void durationChanged();
    void currentStateChanged();
    void mediaError(const QString &error);
    void dbusConnectionError(const QString &error);

private slots:
    void handleDbusMediaCommand(const QString &command);
    void handleDbusVolumeChange(int volume);
    void updatePosition();

private:
    QString m_source;
    bool m_playing;
    int m_volume;
    qint64 m_position;
    qint64 m_duration;
    QString m_currentState;
    QDBusInterface *m_dbusInterface;
    bool m_dbusConnected;
    QTimer *m_positionTimer;
    
    void setupDBusConnection();
    void registerDBusService();
    void sendDBusMessage(const QString &method, const QVariant &arg = QVariant());
    void updateState(const QString &state);
};

#endif // MP_HANDLER_H