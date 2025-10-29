#ifndef THEMECOLORCLIENT_H
#define THEMECOLORCLIENT_H

#include <QObject>
#include <QDBusInterface>
#include <QDBusPendingCallWatcher>

class ThemeColorClient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString color READ color NOTIFY colorChanged)
public:
    explicit ThemeColorClient(QObject *parent = nullptr);

    Q_INVOKABLE void requestCurrentColor();
    Q_INVOKABLE void setColor(const QString &color);

    QString color() const;

signals:
    void colorChanged();

private slots:
    void onColorChangedSignal(const QString &color);
    void onGetColorFinished(QDBusPendingCallWatcher *watcher);

private:
    QDBusInterface *m_interface = nullptr;
    QString m_color;
};

#endif // THEMECOLORCLIENT_H

