#ifndef GS_HANDLER_H
#define GS_HANDLER_H

#include <QObject>

class GS_Handler : public QObject
{
    Q_OBJECT
public:
    explicit GS_Handler(QObject *parent = nullptr);

signals:
};

#endif // GS_HANDLER_H
