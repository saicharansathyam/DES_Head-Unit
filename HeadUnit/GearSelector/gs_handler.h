#ifndef GS_HANDLER_H
#define GS_HANDLER_H

#include <QObject>
#include <QtDBus/QDBusInterface>
#include <QtDBus/QDBusConnection>

class GS_Handler : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString currentGear READ currentGear WRITE setCurrentGear NOTIFY currentGearChanged)

public:
    explicit GS_Handler(QObject *parent = nullptr);
    ~GS_Handler();

    QString currentGear() const;
    void setCurrentGear(const QString &gear);

public slots:
    void handleGearChange(const QString &newGear);

signals:
    void currentGearChanged();

private:
    QString m_currentGear;
    QDBusInterface *m_dbusInterface;
    void setupDBusConnection();
};

#endif // GS_HANDLER_H
