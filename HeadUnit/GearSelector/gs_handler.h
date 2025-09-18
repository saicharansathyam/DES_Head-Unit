#ifndef GS_HANDLER_H
#define GS_HANDLER_H

#include <QObject>

class GS_Handler : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString currentGear READ currentGear WRITE setCurrentGear NOTIFY currentGearChanged)

public:
    explicit GS_Handler(QObject *parent = nullptr);
    
    QString currentGear() const;
    void setCurrentGear(const QString &gear);

signals:
    void currentGearChanged();

private:
    QString m_currentGear;
};

#endif // GS_HANDLER_H
