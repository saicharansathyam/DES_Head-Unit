#include "gs_handler.h"
#include <QDebug>
#include <QDBusReply>

GS_Handler::GS_Handler(QObject *parent)
    : QObject{parent}
    , m_currentGear("P")
    , m_dbusInterface(nullptr)
    , m_dbusConnected(false)
{
    setupDBusConnection();
    registerDBusService();
}

GS_Handler::~GS_Handler()
{
    if (m_dbusInterface) {
        delete m_dbusInterface;
    }
    
    // Unregister the service when shutting down
    QDBusConnection sessionBus = QDBusConnection::sessionBus();
    if (sessionBus.isConnected()) {
        sessionBus.unregisterService("com.example.GearSelector");
    }
}

void GS_Handler::setupDBusConnection()
{
    // Connect to the session bus
    QDBusConnection sessionBus = QDBusConnection::sessionBus();
    
    if (!sessionBus.isConnected()) {
        qWarning() << "Cannot connect to the D-Bus session bus";
        emit dbusConnectionError("Cannot connect to D-Bus session bus");
        return;
    }
    
    qDebug() << "Successfully connected to D-Bus session bus";

    // Create interface to the gear service (for communicating with other components)
    m_dbusInterface = new QDBusInterface(
        "com.example.HeadUnit",               // Service name
        "/com/example/HeadUnit/GearSelector", // Path
        "com.example.HeadUnit.GearSelector",  // Interface
        sessionBus,
        this
    );

    if (!m_dbusInterface->isValid()) {
        qWarning() << "D-Bus interface not valid (this is normal if no other service is running):" 
                   << sessionBus.lastError().message();
        // Don't return here - we can still register our own service
    }

    // Connect to gear change signals from other components
    bool connected = sessionBus.connect(
        "",  // Empty string means any service
        "/com/example/HeadUnit/GearSelector",
        "com.example.HeadUnit.GearSelector",
        "gearChanged",
        this,
        SLOT(handleGearChange(QString))
    );
    
    if (connected) {
        qDebug() << "Successfully connected to gearChanged signal";
        m_dbusConnected = true;
    } else {
        qWarning() << "Failed to connect to gearChanged signal:" << sessionBus.lastError().message();
    }
}

void GS_Handler::registerDBusService()
{
    QDBusConnection sessionBus = QDBusConnection::sessionBus();
    
    // Register the service
    if (!sessionBus.registerService("com.example.GearSelector")) {
        qWarning() << "Could not register D-Bus service:" << sessionBus.lastError().message();
        qDebug() << "This is normal if another instance is already running";
    } else {
        qDebug() << "Successfully registered D-Bus service: com.example.GearSelector";
    }
    
    // Register this object on the bus
    if (!sessionBus.registerObject("/com/example/GearSelector", 
                                   this,
                                   QDBusConnection::ExportAllSlots | 
                                   QDBusConnection::ExportAllSignals |
                                   QDBusConnection::ExportAllProperties)) {
        qWarning() << "Could not register D-Bus object:" << sessionBus.lastError().message();
    } else {
        qDebug() << "Successfully registered D-Bus object at /com/example/GearSelector";
    }
}

void GS_Handler::handleGearChange(const QString &newGear)
{
    qDebug() << "Received gear change signal via D-Bus:" << newGear;
    setCurrentGear(newGear);
}

void GS_Handler::setCurrentGear(const QString &gear)
{
    // Validate gear input
    QStringList validGears = {"P", "R", "N", "D", "S", "L", "M"};
    if (!validGears.contains(gear)) {
        qWarning() << "Invalid gear requested:" << gear;
        return;
    }
    
    if (m_currentGear != gear) {
        QString oldGear = m_currentGear;
        m_currentGear = gear;
        
        qDebug() << "Gear changed from" << oldGear << "to" << m_currentGear;
        
        emit currentGearChanged();
        emit gearChangeRequested(gear);
        
        // Send gear change over D-Bus to notify other components
        sendGearChangeSignal(gear);
    }
}

void GS_Handler::sendGearChangeSignal(const QString &gear)
{
    if (!m_dbusConnected) {
        qDebug() << "D-Bus not connected, skipping signal emission";
        return;
    }
    
    // Send signal via D-Bus
    QDBusMessage msg = QDBusMessage::createSignal(
        "/com/example/GearSelector",
        "com.example.GearSelector",
        "gearChanged"
    );
    msg << gear;
    
    if (!QDBusConnection::sessionBus().send(msg)) {
        qWarning() << "Failed to send gear change signal over D-Bus";
    } else {
        qDebug() << "Sent gear change signal over D-Bus:" << gear;
    }
    
    // Also try to call method on other services if interface is valid
    if (m_dbusInterface && m_dbusInterface->isValid()) {
        QDBusReply<void> reply = m_dbusInterface->call("notifyGearChange", gear);
        if (!reply.isValid()) {
            qDebug() << "No response from HeadUnit service (this is normal if it's not running)";
        }
    }
}

QString GS_Handler::currentGear() const
{
    return m_currentGear;
}