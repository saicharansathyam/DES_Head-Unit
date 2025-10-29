#ifndef MP_HANDLER_H
#define MP_HANDLER_H

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariant>
#include <QtDBus/QDBusConnection>
#include <QtDBus/QDBusInterface>
#include <QtDBus/QDBusMessage>
#include <QTimer>

class MP_Handler : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(QString sourceType READ sourceType WRITE setSourceType NOTIFY sourceTypeChanged)
    Q_PROPERTY(bool playing READ playing NOTIFY playingChanged)
    Q_PROPERTY(int volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(qint64 position READ position WRITE setPosition NOTIFY positionChanged)
    Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(QString currentState READ currentState NOTIFY currentStateChanged)
    Q_PROPERTY(bool serviceConnected READ serviceConnected NOTIFY serviceConnectedChanged)

    // USB properties
    Q_PROPERTY(QStringList usbDevices READ usbDevices NOTIFY usbDevicesChanged)
    Q_PROPERTY(QStringList mediaFiles READ mediaFiles NOTIFY mediaFilesChanged)
    Q_PROPERTY(QString currentDevice READ currentDevice NOTIFY currentDeviceChanged)
    Q_PROPERTY(int currentTrackIndex READ currentTrackIndex NOTIFY currentTrackIndexChanged)
    Q_PROPERTY(QString currentFileName READ currentFileName NOTIFY currentFileNameChanged)

public:
    explicit MP_Handler(QObject *parent = nullptr);
    ~MP_Handler();

    QString source() const;
    void setSource(const QString &src);

    QString sourceType() const;
    void setSourceType(const QString &type);

    bool playing() const;
    int volume() const;
    void setVolume(int vol);

    qint64 position() const;
    void setPosition(qint64 pos);

    qint64 duration() const;

    QString currentState() const;
    bool serviceConnected() const;

    QStringList usbDevices() const;
    QStringList mediaFiles() const;
    QString currentDevice() const;
    int currentTrackIndex() const;
    QString currentFileName() const;

    Q_INVOKABLE void play();
    Q_INVOKABLE void pause();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void next();
    Q_INVOKABLE void previous();
    Q_INVOKABLE void seek(qint64 position);

    // USB methods
    Q_INVOKABLE void selectUsbDevice(const QString &devicePath);
    Q_INVOKABLE void selectMediaFile(int index);
    Q_INVOKABLE void refreshUsbDevices();

signals:
    void sourceChanged();
    void sourceTypeChanged();
    void playingChanged();
    void volumeChanged();
    void positionChanged();
    void durationChanged();
    void currentStateChanged();
    void serviceConnectedChanged();
    void mediaError(const QString &error);

    // USB signals
    void usbDevicesChanged();
    void mediaFilesChanged();
    void currentDeviceChanged();
    void currentTrackIndexChanged();
    void currentFileNameChanged();
    void usbDeviceInserted(const QString &devicePath);
    void usbDeviceRemoved(const QString &devicePath);

private slots:
    void handleServicePlaybackStateChanged(const QString &state);
    void handleServicePositionChanged(qint64 pos);
    void handleServiceDurationChanged(qint64 dur);
    void handleUsbDevicesChanged(const QStringList &devices);
    void handleMediaFilesChanged(const QStringList &files);
    void handleCurrentDeviceChanged(const QString &device);
    void handleUsbInserted(const QString &devicePath);
    void handleUsbRemoved(const QString &devicePath);
    void pollPosition();

private:
    QString m_source;
    QString m_sourceType;
    bool m_playing;
    int m_volume;
    qint64 m_position;
    qint64 m_duration;
    QString m_currentState;
    bool m_serviceConnected;

    QStringList m_usbDevices;
    QStringList m_mediaFiles;
    QString m_currentDevice;
    int m_currentTrackIndex;
    QString m_currentFileName;

    QDBusInterface *m_serviceInterface;
    QTimer *m_positionPollTimer;

    void setupDBusConnection();
    void callService(const QString &method, const QVariantList &args = QVariantList());
    void updateState(const QString &state);
    void syncUsbDataFromService();
};

#endif // MP_HANDLER_H
