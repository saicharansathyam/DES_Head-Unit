#ifndef SCRIPTEXECUTOR_H
#define SCRIPTEXECUTOR_H

#include <QObject>
#include <QProcess>
#include <QString>
#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QCoreApplication>

class ScriptExecutor : public QObject
{
    Q_OBJECT

public:
    explicit ScriptExecutor(QObject *parent = nullptr) : QObject(parent) {
        findScriptPath();
    }

    Q_INVOKABLE void executeDBusCall(const QString &method, int param) {
        if (m_scriptPath.isEmpty()) {
            qWarning() << "D-Bus helper script not found!";
            return;
        }

        QString program = m_scriptPath;
        QStringList arguments;
        arguments << method << QString::number(param);

        qDebug() << "Executing D-Bus call:" << method << "with param:" << param;

        bool started = QProcess::startDetached(program, arguments);

        if (!started) {
            qWarning() << "Failed to start D-Bus helper script";
        }
    }

private:
    QString m_scriptPath;

    void findScriptPath() {
        // Get the directory where the executable is located
        QString appDir = QCoreApplication::applicationDirPath();
        qDebug() << "Application directory:" << appDir;

        // Define possible relative paths from executable location
        QStringList relativePaths = {
            "../dbus_send_helper.sh",              // build/headUnit
            "../../dbus_send_helper.sh",           // Alternative structure
            "../dbus_send_helper.sh",              // Direct parent
            "./dbus_send_helper.sh",               // Same level scripts/
            "dbus_send_helper.sh"                  // Same directory
        };

        // Try each relative path
        for (const QString &relPath : relativePaths) {
            QString fullPath = QDir(appDir).filePath(relPath);
            QFileInfo fileInfo(fullPath);

            // Resolve to canonical (absolute) path and check if exists
            QString canonicalPath = fileInfo.canonicalFilePath();

            if (!canonicalPath.isEmpty() && QFileInfo(canonicalPath).isExecutable()) {
                m_scriptPath = canonicalPath;
                qDebug() << "Found D-Bus helper script at:" << m_scriptPath;
                qDebug() << "Using relative path:" << relPath;
                return;
            }
        }

        qWarning() << "D-Bus helper script not found!";
        qWarning() << "Searched relative to:" << appDir;
        qWarning() << "Tried paths:" << relativePaths;
    }
};

#endif // SCRIPTEXECUTOR_H
