#pragma once

#include <QObject>
#include <QtDBus/QDBusInterface>
#include <QtDBus/QDBusConnection>
#include <QtDBus/QDBusMessage>

class MP_Handler : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(bool playing READ playing NOTIFY playingChanged)

public:
    explicit MP_Handler(QObject *parent = nullptr);

    QString source() const;
    void setSource(const QString &src);

    bool playing() const;

    Q_INVOKABLE void play();
    Q_INVOKABLE void pause();
    Q_INVOKABLE void stop();

signals:
    void sourceChanged();
    void playingChanged();

private:
    QString m_source;
    bool m_playing;

    void sendDBusMessage(const QString &method);
};
