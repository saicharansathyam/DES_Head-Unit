#include "ThemeColorClient.h"
#include <QDBusConnection>
#include <QDBusPendingReply>
#include <QDebug>

ThemeColorClient::ThemeColorClient(QObject *parent) : QObject(parent)
{
    m_interface = new QDBusInterface("com.piracer.dashboard",
                                     "/com/piracer/dashboard",
                                     "com.piracer.dashboard",
                                     QDBusConnection::sessionBus(),
                                     this);

    // Connect to D-Bus ColorChanged signal
    QDBusConnection::sessionBus().connect(
        "com.piracer.dashboard",
        "/com/piracer/dashboard",
        "com.piracer.dashboard",
        "ColorChanged",
        this,
        SLOT(onColorChangedSignal(QString)));

    requestCurrentColor();
}

void ThemeColorClient::requestCurrentColor()
{
    QDBusPendingReply<QString> reply = m_interface->asyncCall("GetColor");
    auto watcher = new QDBusPendingCallWatcher(reply, this);
    connect(watcher, &QDBusPendingCallWatcher::finished,
            this, &ThemeColorClient::onGetColorFinished);
}

void ThemeColorClient::setColor(const QString &color)
{
    if (m_interface)
        m_interface->call("SetColor", color);
}

QString ThemeColorClient::color() const
{
    return m_color;
}

void ThemeColorClient::onColorChangedSignal(const QString &color)
{
    if (m_color != color) {
        m_color = color;
        emit colorChanged();
        qDebug() << "Theme color changed to:" << color;
    }
}

void ThemeColorClient::onGetColorFinished(QDBusPendingCallWatcher *watcher)
{
    QDBusPendingReply<QString> reply = *watcher;
    if (reply.isError()) {
        qWarning() << "Failed to get color from service:" << reply.error().message();
        return;
    }
    QString color = reply.value();
    if (m_color != color) {
        m_color = color;
        emit colorChanged();
        qDebug() << "Initial theme color received:" << color;
    }
    watcher->deleteLater();
}


