#ifndef THEME_CLIENT_H
#define THEME_CLIENT_H

#include <QObject>
#include <QString>
#include <QColor>
#include <QDBusInterface>
#include <QDBusConnection>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>

class ThemeClient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString themeColor READ themeColor NOTIFY themeColorChanged)
    Q_PROPERTY(QString buttonColor READ buttonColor NOTIFY themeColorChanged)
    Q_PROPERTY(QString buttonHoverColor READ buttonHoverColor NOTIFY themeColorChanged)
    Q_PROPERTY(QString buttonPressedColor READ buttonPressedColor NOTIFY themeColorChanged)
    Q_PROPERTY(QString accentColor READ accentColor NOTIFY themeColorChanged)
    
public:
    explicit ThemeClient(QObject *parent = nullptr);
    
    QString themeColor() const { return m_themeColor; }
    QString buttonColor() const { return m_themeColor; }
    QString buttonHoverColor() const;
    QString buttonPressedColor() const;
    QString accentColor() const;
    
    Q_INVOKABLE void requestCurrentColor();
    Q_INVOKABLE void setColor(const QString &color);
    
signals:
    void themeColorChanged();
    
private slots:
    void onColorChangedSignal(const QString &color);
    void onGetColorFinished(QDBusPendingCallWatcher *watcher);
    
private:
    void setupDBusConnection();
    QColor lighten(const QColor &color, int amount) const;
    QColor darken(const QColor &color, int amount) const;
    
    QDBusInterface *m_interface;
    QString m_themeColor;
};

#endif // THEME_CLIENT_H
