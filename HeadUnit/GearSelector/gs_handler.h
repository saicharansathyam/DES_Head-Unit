#ifndef GS_HANDLER_H
#define GS_HANDLER_H

#include <QObject>
#include <QString>
#include <QtDBus/QDBusInterface>
#include <QtDBus/QDBusConnection>
#include <QtDBus/QDBusMessage>
#include <QtDBus/QDBusError>

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
    void gearChangeRequested(const QString &gear);
    void dbusConnectionError(const QString &error);

private:
    QString m_currentGear;
    QDBusInterface *m_dbusInterface;
    bool m_dbusConnected;
    
    void setupDBusConnection();
    void registerDBusService();
    void sendGearChangeSignal(const QString &gear);
};

#endif // GS_HANDLER_H