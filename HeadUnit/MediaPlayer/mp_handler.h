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
    Q_PROPERTY(bool isPlaying READ isPlaying NOTIFY isPlayingChanged)
    Q_PROPERTY(int volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(qint64 currentPosition READ currentPosition WRITE setPosition NOTIFY currentPositionChanged)
    Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(QString currentState READ currentState NOTIFY currentStateChanged)
    Q_PROPERTY(bool serviceConnected READ serviceConnected NOTIFY serviceConnectedChanged)

    // Track info properties
    Q_PROPERTY(QString currentTrack READ currentTrack NOTIFY currentTrackChanged)
    Q_PROPERTY(QString currentArtist READ currentArtist NOTIFY currentArtistChanged)

    // USB properties
    Q_PROPERTY(QStringList usbDevices READ usbDevices NOTIFY usbDevicesChanged)
    Q_PROPERTY(QStringList mediaFileList READ mediaFileList NOTIFY mediaFileListChanged)
    Q_PROPERTY(QString currentDevice READ currentDevice NOTIFY currentDeviceChanged)
    Q_PROPERTY(int currentMediaIndex READ currentMediaIndex NOTIFY currentMediaIndexChanged)
    Q_PROPERTY(QString currentFileName READ currentFileName NOTIFY currentFileNameChanged)

    // Playlist-related properties
    Q_PROPERTY(QVariantList playlist READ playlist NOTIFY playlistChanged)

public:
    explicit MP_Handler(QObject *parent = nullptr);
    ~MP_Handler();

    QString source() const;
    void setSource(const QString &src);

    QString sourceType() const;
    void setSourceType(const QString &type);

    bool isPlaying() const;
    int volume() const;
    void setVolume(int vol);

    qint64 currentPosition() const;
    void setPosition(qint64 pos);

    qint64 duration() const;

    QString currentState() const;
    bool serviceConnected() const;

    // Track info
    QString currentTrack() const;
    QString currentArtist() const;

    QStringList usbDevices() const;
    QStringList mediaFileList() const;
    QString currentDevice() const;
    int currentMediaIndex() const;
    QString currentFileName() const;

    // Playlist
    QVariantList playlist() const;

    Q_INVOKABLE void play();
    Q_INVOKABLE void pause();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void togglePlayPause();
    Q_INVOKABLE void next();
    Q_INVOKABLE void previous();
    Q_INVOKABLE void seek(qint64 position);
    Q_INVOKABLE void toggleShuffle();
    Q_INVOKABLE void toggleRepeat();

    // USB methods
    Q_INVOKABLE void selectUsbDevice(const QString &devicePath);
    Q_INVOKABLE void selectMediaFile(int index);
    Q_INVOKABLE void refreshUsbDevices();
    Q_INVOKABLE void refreshMediaFiles();
    Q_INVOKABLE void playTrack(int index);

signals:
    void sourceChanged();
    void sourceTypeChanged();
    void isPlayingChanged();
    void volumeChanged();
    void currentPositionChanged();
    void durationChanged();
    void currentStateChanged();
    void serviceConnectedChanged();
    void mediaError(const QString &error);

    // Track info signals
    void currentTrackChanged();
    void currentArtistChanged();

    // USB signals
    void usbDevicesChanged();
    void mediaFileListChanged();
    void currentDeviceChanged();
    void currentMediaIndexChanged();
    void currentFileNameChanged();
    void usbDeviceInserted(const QString &devicePath);
    void usbDeviceRemoved(const QString &devicePath);
    void playlistChanged();

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
    bool m_isPlaying;
    int m_volume;
    qint64 m_position;
    qint64 m_duration;
    QString m_currentState;
    bool m_serviceConnected;

    QString m_currentTrack;
    QString m_currentArtist;

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
    void updateTrackInfo();
    void buildPlaylist();
};

#endif // MP_HANDLER_H
