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
    Q_PROPERTY(double currentSpeed READ currentSpeed NOTIFY speedChanged)
    Q_PROPERTY(double batteryLevel READ batteryLevel NOTIFY batteryChanged)
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY connectionStateChanged)

public:
    explicit GS_Handler(QObject *parent = nullptr);
    ~GS_Handler();

    QString currentGear() const;
    void setCurrentGear(const QString &gear);
    
    double currentSpeed() const;
    double batteryLevel() const;
    bool isConnected() const;

public slots:
    // Slots for PiRacer D-Bus signals
    void handlePiRacerGearChange(const QString &newGear);
    void handleSpeedChange(double speed);
    void handleBatteryChange(double battery);
    void handleServiceOwnerChanged(const QString &serviceName, 
                                  const QString &oldOwner, 
                                  const QString &newOwner);

signals:
    void currentGearChanged();
    void gearChangeRequested(const QString &gear);
    void speedChanged(double speed);
    void batteryChanged(double battery);
    void dbusConnectionError(const QString &error);
    void dbusConnectionRestored();
    void connectionStateChanged();

private:
    QString m_currentGear;
    double m_currentSpeed;
    double m_batteryLevel;
    QDBusInterface *m_piracerInterface;
    bool m_dbusConnected;
    
    void setupDBusConnection();
    void syncGearFromPiRacer();
};

#endif // GS_HANDLER_H