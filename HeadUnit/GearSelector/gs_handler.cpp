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
    // Connect to the session bus
    QDBusConnection sessionBus = QDBusConnection::sessionBus();
    
    if (!sessionBus.isConnected()) {
        qWarning() << "Cannot connect to the D-Bus session bus";
        return;
    }

    // Create interface to the gear service
    m_dbusInterface = new QDBusInterface(
        "com.example.GearSelector",           // Service name
        "/com/example/GearSelector",          // Path
        "com.example.GearSelector",           // Interface
        sessionBus,
        this
    );

    if (!m_dbusInterface->isValid()) {
        qWarning() << "Cannot create D-Bus interface:" << sessionBus.lastError().message();
        return;
    }

    // Connect to gear change signals
    sessionBus.connect(
        "com.example.GearSelector",
        "/com/example/GearSelector",
        "com.example.GearSelector",
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
            m_dbusInterface->call("select_gear", gear);
        }
    }
}

QString GS_Handler::currentGear() const
{
    return m_currentGear;
}
