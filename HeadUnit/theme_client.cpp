#include "theme_client.h"
#include <QDebug>

ThemeClient::ThemeClient(QObject *parent)
    : QObject(parent)
    , m_interface(nullptr)
    , m_themeColor("#3b82f6")  // Default blue
{
    setupDBusConnection();
    requestCurrentColor();
}

void ThemeClient::setupDBusConnection()
{
    m_interface = new QDBusInterface(
        "com.piracer.dashboard",
        "/com/piracer/dashboard",
        "com.piracer.dashboard",
        QDBusConnection::sessionBus(),
        this
    );
    
    if (!m_interface->isValid()) {
        qWarning() << "Theme service not available:"
                   << QDBusConnection::sessionBus().lastError().message();
        qWarning() << "Using default theme color";
        return;
    }
    
    // Connect to ColorChanged signal
    bool connected = QDBusConnection::sessionBus().connect(
        "com.piracer.dashboard",
        "/com/piracer/dashboard",
        "com.piracer.dashboard",
        "ColorChanged",
        this,
        SLOT(onColorChangedSignal(QString))
    );
    
    if (connected) {
        qDebug() << "ThemeClient: Connected to theme service";
    } else {
        qWarning() << "ThemeClient: Failed to connect to ColorChanged signal";
    }
}

void ThemeClient::requestCurrentColor()
{
    if (!m_interface || !m_interface->isValid()) {
        qWarning() << "Cannot request color - service not available";
        return;
    }
    
    QDBusPendingReply<QString> reply = m_interface->asyncCall("GetColor");
    auto *watcher = new QDBusPendingCallWatcher(reply, this);
    connect(watcher, &QDBusPendingCallWatcher::finished,
            this, &ThemeClient::onGetColorFinished);
}

void ThemeClient::setColor(const QString &color)
{
    if (m_interface && m_interface->isValid()) {
        m_interface->call("SetColor", color);
        qDebug() << "ThemeClient: Set color to" << color;
    } else {
        qWarning() << "Cannot set color - service not available";
    }
}

void ThemeClient::onColorChangedSignal(const QString &color)
{
    if (m_themeColor != color) {
        m_themeColor = color;
        qDebug() << "ThemeClient: Theme color changed to:" << color;
        emit themeColorChanged();
    }
}

void ThemeClient::onGetColorFinished(QDBusPendingCallWatcher *watcher)
{
    QDBusPendingReply<QString> reply = *watcher;
    
    if (reply.isError()) {
        qWarning() << "Failed to get color from service:"
                   << reply.error().message();
    } else {
        QString color = reply.value();
        if (m_themeColor != color) {
            m_themeColor = color;
            qDebug() << "ThemeClient: Initial color received:" << color;
            emit themeColorChanged();
        }
    }
    
    watcher->deleteLater();
}

QString ThemeClient::buttonHoverColor() const
{
    QColor base(m_themeColor);
    return lighten(base, 20).name();
}

QString ThemeClient::buttonPressedColor() const
{
    QColor base(m_themeColor);
    return darken(base, 20).name();
}

QString ThemeClient::accentColor() const
{
    QColor base(m_themeColor);
    return lighten(base, 40).name();
}

QColor ThemeClient::lighten(const QColor &color, int amount) const
{
    return color.lighter(100 + amount);
}

QColor ThemeClient::darken(const QColor &color, int amount) const
{
    return color.darker(100 + amount);
}
