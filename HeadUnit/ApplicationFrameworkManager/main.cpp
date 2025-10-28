// main.cpp (for AFM standalone executable)
#include "application_framework_manager.h"
#include <QCoreApplication>
#include <QDebug>

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);

    qInfo() << "================================================";
    qInfo() << " HeadUnit Application Framework Manager (AFM)";
    qInfo() << " Version 1.0";
    qInfo() << "================================================";

    ApplicationFrameworkManager afm;

    qInfo() << "[AFM] Service ready and listening on D-Bus";
    qInfo() << "[AFM] Service name: com.headunit.AppLifecycle";
    qInfo() << "[AFM] Object path: /com/headunit/AppLifecycle";
    qInfo() << "================================================";

    return app.exec();
}
