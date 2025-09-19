#include "mp_handler.h"

MP_Handler::MP_Handler(QObject *parent)
    : QObject(parent), m_playing(false)
{
}

QString MP_Handler::source() const
{
    return m_source;
}

void MP_Handler::setSource(const QString &src)
{
    if (m_source != src) {
        m_source = src;
        emit sourceChanged();
        // Optionally notify DBus about source change
        sendDBusMessage("SetSource");
    }
}

bool MP_Handler::playing() const
{
    return m_playing;
}

void MP_Handler::play()
{
    m_playing = true;
    emit playingChanged();
    sendDBusMessage("play");
}

void MP_Handler::pause()
{
    m_playing = false;
    emit playingChanged();
    sendDBusMessage("pause");
}

void MP_Handler::stop()
{
    m_playing = false;
    emit playingChanged();
    sendDBusMessage("stop");
}

void MP_Handler::sendDBusMessage(const QString &method)
{
    QDBusMessage msg = QDBusMessage::createMethodCall(
        "com.example.MediaPlayer",   // service name
        "/com/example/MediaPlayer",  // object path
        "com.example.MediaPlayer",   // interface name
        method
        );

    QDBusMessage reply = QDBusConnection::sessionBus().call(msg);

    if (reply.type() == QDBusMessage::ReplyMessage) {
        if (!reply.arguments().isEmpty())
            qDebug() << "[DBus] Reply:" << reply.arguments().at(0).toString();
    } else {
        qWarning() << "[DBus] Error:" << reply.errorMessage();
    }
}
