#include "gs_handler.h"

GS_Handler::GS_Handler(QObject *parent)
    : QObject{parent}
{
    m_currentGear = "P";
}

void GS_Handler::setCurrentGear(const QString &gear)
{
    if (m_currentGear != gear)
    {
        m_currentGear = gear;
        emit currentGearChanged();
    }
}

QString GS_Handler::currentGear() const
{
    return m_currentGear;
}
