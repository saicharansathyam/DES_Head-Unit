// Updated gs_handler.cpp for PiRacer integration
#include "gs_handler.h"
#include <QDebug>
#include <QDBusReply>

GS_Handler::GS_Handler(QObject *parent)
    : QObject{parent}
    , m_currentGear("P")
    , m_piracerInterface(nullptr)
    , m_dbusConnected(false)
{
    setupDBusConnection();
}

GS_Handler::~GS_Handler()
{
    if (m_piracerInterface) {
        delete m_piracerInterface;
    }
}

void GS_Handler::setupDBusConnection()
{
    QDBusConnection sessionBus = QDBusConnection::sessionBus();
    
    if (!sessionBus.isConnected()) {
        qWarning() << "Cannot connect to the D-Bus session bus";
        emit dbusConnectionError("Cannot connect to D-Bus session bus");
        return;
    }
    
    qDebug() << "Successfully connected to D-Bus session bus";

    // Connect to PiRacer dashboard service
    m_piracerInterface = new QDBusInterface(
        "com.piracer.dashboard",           // Service name from your Python service
        "/com/piracer/dashboard",          // Path
        "com.piracer.dashboard",           // Interface
        sessionBus,
        this
    );

    if (!m_piracerInterface->isValid()) {
        qWarning() << "PiRacer dashboard service not available:" 
                   << sessionBus.lastError().message();
        // Try to continue anyway - service might start later
    } else {
        qDebug() << "Connected to PiRacer dashboard service";
        m_dbusConnected = true;
        
        // Get current gear from PiRacer
        syncGearFromPiRacer();
    }

    // Connect to gear change signals from PiRacer
    bool connected = sessionBus.connect(
        "com.piracer.dashboard",
        "/com/piracer/dashboard",
        "com.piracer.dashboard",
        "GearChanged",
        this,
        SLOT(handlePiRacerGearChange(QString))
    );
    
    if (connected) {
        qDebug() << "Connected to PiRacer GearChanged signal";
    } else {
        qWarning() << "Failed to connect to GearChanged signal";
    }
    
    // Connect to speed changes to display in UI
    connected = sessionBus.connect(
        "com.piracer.dashboard",
        "/com/piracer/dashboard",
        "com.piracer.dashboard",
        "SpeedChanged",
        this,
        SLOT(handleSpeedChange(double))
    );
    
    if (connected) {
        qDebug() << "Connected to PiRacer SpeedChanged signal";
    }
    
    // Connect to battery changes
    connected = sessionBus.connect(
        "com.piracer.dashboard",
        "/com/piracer/dashboard",
        "com.piracer.dashboard",
        "BatteryChanged",
        this,
        SLOT(handleBatteryChange(double))
    );
    
    if (connected) {
        qDebug() << "Connected to PiRacer BatteryChanged signal";
    }
    
    // Monitor service availability
    sessionBus.connect(
        "org.freedesktop.DBus",
        "/org/freedesktop/DBus",
        "org.freedesktop.DBus",
        "NameOwnerChanged",
        this,
        SLOT(handleServiceOwnerChanged(QString, QString, QString))
    );
}

void GS_Handler::syncGearFromPiRacer()
{
    if (!m_piracerInterface || !m_piracerInterface->isValid()) {
        return;
    }
    
    QDBusReply<QString> reply = m_piracerInterface->call("GetGear");
    if (reply.isValid()) {
        QString gear = reply.value();
        if (gear != m_currentGear) {
            m_currentGear = gear;
            emit currentGearChanged();
            qDebug() << "Synced gear from PiRacer:" << gear;
        }
    } else {
        qWarning() << "Failed to get gear from PiRacer:" << reply.error().message();
    }
}

void GS_Handler::handlePiRacerGearChange(const QString &newGear)
{
    qDebug() << "Received gear change from PiRacer:" << newGear;
    if (m_currentGear != newGear) {
        m_currentGear = newGear;
        emit currentGearChanged();
    }
}

void GS_Handler::handleSpeedChange(double speed)
{
    // Speed in cm/s from PiRacer
    m_currentSpeed = speed;
    emit speedChanged(speed);
}

void GS_Handler::handleBatteryChange(double battery)
{
    // Battery percentage from PiRacer
    m_batteryLevel = battery;
    emit batteryChanged(battery);
}

void GS_Handler::handleServiceOwnerChanged(const QString &serviceName, 
                                           const QString &oldOwner, 
                                           const QString &newOwner)
{
    if (serviceName == "com.piracer.dashboard") {
        if (newOwner.isEmpty()) {
            // Service disappeared
            qWarning() << "PiRacer dashboard service disconnected";
            m_dbusConnected = false;
            emit dbusConnectionError("PiRacer service disconnected");
        } else {
            // Service appeared
            qDebug() << "PiRacer dashboard service connected";
            m_dbusConnected = true;
            
            // Recreate interface
            delete m_piracerInterface;
            m_piracerInterface = new QDBusInterface(
                "com.piracer.dashboard",
                "/com/piracer/dashboard",
                "com.piracer.dashboard",
                QDBusConnection::sessionBus(),
                this
            );
            
            // Sync current state
            syncGearFromPiRacer();
            emit dbusConnectionRestored();
        }
    }
}

void GS_Handler::setCurrentGear(const QString &gear)
{
    // Validate gear input
    QStringList validGears = {"P", "R", "N", "D"};
    if (!validGears.contains(gear)) {
        qWarning() << "Invalid gear requested:" << gear;
        return;
    }
    
    if (m_currentGear != gear) {
        QString oldGear = m_currentGear;
        m_currentGear = gear;
        
        qDebug() << "Setting gear from" << oldGear << "to" << m_currentGear;
        
        emit currentGearChanged();
        emit gearChangeRequested(gear);
        
        // Send gear change to PiRacer dashboard service
        if (m_piracerInterface && m_piracerInterface->isValid()) {
            QDBusReply<void> reply = m_piracerInterface->call("SetGear", gear);
            if (!reply.isValid()) {
                qWarning() << "Failed to set gear on PiRacer:" << reply.error().message();
                // Optionally revert the change
                // m_currentGear = oldGear;
                // emit currentGearChanged();
            } else {
                qDebug() << "Successfully sent gear change to PiRacer";
            }
        } else {
            qWarning() << "PiRacer service not available - gear change not sent";
        }
    }
}

QString GS_Handler::currentGear() const
{
    return m_currentGear;
}

double GS_Handler::currentSpeed() const
{
    return m_currentSpeed;
}

double GS_Handler::batteryLevel() const
{
    return m_batteryLevel;
}

bool GS_Handler::isConnected() const
{
    return m_dbusConnected;
}