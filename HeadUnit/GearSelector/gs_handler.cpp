#include "gs_handler.h"
#include <QDebug>

GS_Handler::GS_Handler(QObject *parent)
    : QObject{parent}
    , m_currentGear("P")
    , m_dbusInterface(nullptr)
{
    setupDBusConnection();
}

GS_Handler::~GS_Handler()
{
    delete m_dbusInterface;
}

void GS_Handler::setupDBusConnection()
{
    // Connect to the system bus
    QDBusConnection systemBus = QDBusConnection::systemBus();
    
    if (!systemBus.isConnected()) {
        qWarning() << "Cannot connect to the D-Bus system bus";
        return;
    }

    // Create interface to the gear service
    m_dbusInterface = new QDBusInterface(
        "org.des.GearService",           // Service name
        "/org/des/GearService",          // Path
        "org.des.GearInterface",         // Interface
        systemBus,
        this
    );

    if (!m_dbusInterface->isValid()) {
        qWarning() << "Cannot create D-Bus interface:" << systemBus.lastError().message();
        return;
    }

    // Connect to gear change signals
    systemBus.connect(
        "org.des.GearService",
        "/org/des/GearService",
        "org.des.GearInterface",
        "gearChanged",
        this,
        SLOT(handleGearChange(QString))
    );
}

void GS_Handler::handleGearChange(const QString &newGear)
{
    setCurrentGear(newGear);
}

void GS_Handler::setCurrentGear(const QString &gear)
{
    if (m_currentGear != gear)
    {
        m_currentGear = gear;
        emit currentGearChanged();

        // Send gear change over DBus
        if (m_dbusInterface && m_dbusInterface->isValid()) {
            m_dbusInterface->call("setGear", gear);
        }
    }
}

QString GS_Handler::currentGear() const
{
    return m_currentGear;
}
