#include "ThemeColorClient.h"
#include <QDebug>
#include <QDBusConnectionInterface>

ThemeColorClient::ThemeColorClient(QObject *parent) : QObject(parent)
{
    qDebug() << "=== ThemeColorClient Initializing ===";

    // Create D-Bus interface
    m_interface = new QDBusInterface(
        "com.piracer.dashboard",
        "/com/piracer/dashboard",
        "com.piracer.dashboard",
        QDBusConnection::sessionBus(),
        this
        );

    if (!m_interface->isValid()) {
        qWarning() << "D-Bus interface is NOT valid!";
        qWarning() << "Error:" << m_interface->lastError().message();
        qWarning() << "Make sure theme_service.py is running!";
    } else {
        qDebug() << "D-Bus interface is valid";
    }

    // Connect to D-Bus ColorChanged signal
    bool connected = QDBusConnection::sessionBus().connect(
        "com.piracer.dashboard",
        "/com/piracer/dashboard",
        "com.piracer.dashboard",
        "ColorChanged",
        this,
        SLOT(onColorChangedSignal(QString))
        );

    if (connected) {
        qDebug() << "Successfully connected to ColorChanged signal";
    } else {
        qWarning() << "Failed to connect to ColorChanged signal";
    }

    // Request current color
    requestCurrentColor();
}

void ThemeColorClient::requestCurrentColor()
{
    qDebug() << "Requesting current color from D-Bus...";

    if (!m_interface || !m_interface->isValid()) {
        qWarning() << "Cannot request color - interface not valid";
        return;
    }

    QDBusPendingReply<QString> reply = m_interface->asyncCall("GetColor");
    auto *watcher = new QDBusPendingCallWatcher(reply, this);
    connect(watcher, &QDBusPendingCallWatcher::finished,
            this, &ThemeColorClient::onGetColorFinished);
}

void ThemeColorClient::setColor(const QString &color)
{
    qDebug() << "=== setColor() called with:" << color << "===";

    if (!m_interface) {
        qCritical() << "ERROR: m_interface is NULL!";
        return;
    }

    if (!m_interface->isValid()) {
        qCritical() << "ERROR: D-Bus interface is not valid!";
        qCritical() << "Error:" << m_interface->lastError().message();
        return;
    }

    qDebug() << "Calling D-Bus SetColor method...";
    QDBusReply<void> reply = m_interface->call("SetColor", color);

    if (reply.isValid()) {
        qDebug() << "SetColor D-Bus call successful!";
    } else {
        qCritical() << "SetColor D-Bus call FAILED!";
        qCritical() << "Error:" << reply.error().message();
    }
}

QString ThemeColorClient::color() const
{
    return m_color;
}

void ThemeColorClient::onColorChangedSignal(const QString &color)
{
    qDebug() << "Received ColorChanged signal from D-Bus:" << color;

    if (m_color != color) {
        m_color = color;
        emit colorChanged();
        qDebug() << "Theme color updated to:" << color;
    }
}

void ThemeColorClient::onGetColorFinished(QDBusPendingCallWatcher *watcher)
{
    QDBusPendingReply<QString> reply = *watcher;

    if (reply.isError()) {
        qWarning() << "Failed to get color from service:";
        qWarning() << "Error:" << reply.error().message();
    } else {
        QString color = reply.value();
        qDebug() << "Initial color received from D-Bus:" << color;

        if (m_color != color) {
            m_color = color;
            emit colorChanged();
        }
    }

    watcher->deleteLater();
}
