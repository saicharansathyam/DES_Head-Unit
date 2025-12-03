#include "mp_handler.h"
#include <QDBusReply>
#include <QDebug>
#include <QFileInfo>

MP_Handler::MP_Handler(QObject *parent)
    : QObject(parent)
    , m_sourceType("usb")
    , m_playing(false)
    , m_volume(50)
    , m_position(0)
    , m_duration(0)
    , m_currentState("Stopped")
    , m_serviceConnected(false)
    , m_currentTrackIndex(-1)
    , m_serviceInterface(nullptr)
{
    m_positionPollTimer = new QTimer(this);
    m_positionPollTimer->setInterval(500);
    connect(m_positionPollTimer, &QTimer::timeout, this, &MP_Handler::pollPosition);

    setupDBusConnection();
}

MP_Handler::~MP_Handler()
{
    if (m_positionPollTimer) {
        m_positionPollTimer->stop();
    }
    if (m_serviceInterface) {
        delete m_serviceInterface;
    }
}

void MP_Handler::setupDBusConnection()
{
    QDBusConnection sessionBus = QDBusConnection::sessionBus();

    if (!sessionBus.isConnected()) {
        qWarning() << "Cannot connect to D-Bus session bus";
        emit mediaError("Cannot connect to D-Bus session bus");
        return;
    }

    m_serviceInterface = new QDBusInterface(
        "com.seame.MediaPlayer",
        "/com/seame/MediaPlayer",
        "com.seame.MediaPlayer",
        sessionBus,
        this
        );

    if (m_serviceInterface->isValid()) {
        m_serviceConnected = true;
        emit serviceConnectedChanged();
        qDebug() << "Connected to MediaPlayer service";

        // Connect to playback signals
        sessionBus.connect(
            "com.seame.MediaPlayer",
            "/com/seame/MediaPlayer",
            "com.seame.MediaPlayer",
            "PlaybackStateChanged",
            this,
            SLOT(handleServicePlaybackStateChanged(QString))
            );

        sessionBus.connect(
            "com.seame.MediaPlayer",
            "/com/seame/MediaPlayer",
            "com.seame.MediaPlayer",
            "PositionChanged",
            this,
            SLOT(handleServicePositionChanged(qint64))
            );

        sessionBus.connect(
            "com.seame.MediaPlayer",
            "/com/seame/MediaPlayer",
            "com.seame.MediaPlayer",
            "DurationChanged",
            this,
            SLOT(handleServiceDurationChanged(qint64))
            );

        // Connect to USB signals
        sessionBus.connect(
            "com.seame.MediaPlayer",
            "/com/seame/MediaPlayer",
            "com.seame.MediaPlayer",
            "UsbDevicesChanged",
            this,
            SLOT(handleUsbDevicesChanged(QStringList))
            );

        sessionBus.connect(
            "com.seame.MediaPlayer",
            "/com/seame/MediaPlayer",
            "com.seame.MediaPlayer",
            "MediaFilesChanged",
            this,
            SLOT(handleMediaFilesChanged(QStringList))
            );

        sessionBus.connect(
            "com.seame.MediaPlayer",
            "/com/seame/MediaPlayer",
            "com.seame.MediaPlayer",
            "CurrentDeviceChanged",
            this,
            SLOT(handleCurrentDeviceChanged(QString))
            );

        sessionBus.connect(
            "com.seame.MediaPlayer",
            "/com/seame/MediaPlayer",
            "com.seame.MediaPlayer",
            "UsbDeviceInserted",
            this,
            SLOT(handleUsbInserted(QString))
            );

        sessionBus.connect(
            "com.seame.MediaPlayer",
            "/com/seame/MediaPlayer",
            "com.seame.MediaPlayer",
            "UsbDeviceRemoved",
            this,
            SLOT(handleUsbRemoved(QString))
            );

        syncUsbDataFromService();
    } else {
        qWarning() << "MediaPlayer service not available:" << m_serviceInterface->lastError().message();
        emit mediaError("MediaPlayer service not available");
    }
}

void MP_Handler::syncUsbDataFromService()
{
    if (!m_serviceConnected || !m_serviceInterface) {
        return;
    }

    QDBusReply<QStringList> devicesReply = m_serviceInterface->call("GetUsbDevices");
    if (devicesReply.isValid()) {
        m_usbDevices = devicesReply.value();
        emit usbDevicesChanged();
        qDebug() << "Synced USB devices:" << m_usbDevices;
    }

    QDBusReply<QString> deviceReply = m_serviceInterface->call("GetCurrentDevice");
    if (deviceReply.isValid()) {
        m_currentDevice = deviceReply.value();
        emit currentDeviceChanged();
    }

    QDBusReply<QStringList> filesReply = m_serviceInterface->call("GetMediaFiles");
    if (filesReply.isValid()) {
        m_mediaFiles = filesReply.value();
        emit mediaFilesChanged();
        qDebug() << "Synced media files:" << m_mediaFiles.count() << "files";
    }
}

void MP_Handler::callService(const QString &method, const QVariantList &args)
{
    if (!m_serviceConnected || !m_serviceInterface) {
        qWarning() << "Service not connected, cannot call method:" << method;
        return;
    }

    QDBusMessage reply = m_serviceInterface->callWithArgumentList(QDBus::NoBlock, method, args);

    if (reply.type() == QDBusMessage::ErrorMessage) {
        qWarning() << "DBus call failed:" << method << reply.errorMessage();
        emit mediaError("Service call failed: " + method);
    }
}

QString MP_Handler::source() const { return m_source; }
QString MP_Handler::sourceType() const { return m_sourceType; }
bool MP_Handler::playing() const { return m_playing; }
int MP_Handler::volume() const { return m_volume; }
qint64 MP_Handler::position() const { return m_position; }
qint64 MP_Handler::duration() const { return m_duration; }
QString MP_Handler::currentState() const { return m_currentState; }
bool MP_Handler::serviceConnected() const { return m_serviceConnected; }
QStringList MP_Handler::usbDevices() const { return m_usbDevices; }
QStringList MP_Handler::mediaFiles() const { return m_mediaFiles; }
QString MP_Handler::currentDevice() const { return m_currentDevice; }
int MP_Handler::currentTrackIndex() const { return m_currentTrackIndex; }
QString MP_Handler::currentFileName() const { return m_currentFileName; }

void MP_Handler::setSource(const QString &src)
{
    if (m_source != src) {
        m_source = src;
        emit sourceChanged();

        // Update file name from source
        QFileInfo fileInfo(src);
        m_currentFileName = fileInfo.fileName();
        emit currentFileNameChanged();

        callService("SetSource", {src, m_sourceType});

        m_position = 0;
        emit positionChanged();
        qDebug() << "Media source changed to:" << src << "type:" << m_sourceType;
    }
}

void MP_Handler::setSourceType(const QString &type)
{
    if (m_sourceType != type) {
        m_sourceType = type;
        emit sourceTypeChanged();
        qDebug() << "Source type changed to:" << type;

        if (!m_source.isEmpty()) {
            callService("SetSource", {m_source, m_sourceType});
        }
    }
}

void MP_Handler::setVolume(int vol)
{
    vol = qBound(0, vol, 100);
    if (m_volume != vol) {
        m_volume = vol;
        emit volumeChanged();
        callService("SetVolume", {vol});
        qDebug() << "Volume changed to:" << vol;
    }
}

void MP_Handler::setPosition(qint64 pos)
{
    if (m_position != pos) {
        m_position = pos;
        emit positionChanged();
    }
}

void MP_Handler::updateState(const QString &state)
{
    if (m_currentState != state) {
        m_currentState = state;
        emit currentStateChanged();
    }
}

void MP_Handler::play()
{
    callService("Play");
    m_positionPollTimer->start();
    qDebug() << "Play command sent";
}

void MP_Handler::pause()
{
    callService("Pause");
    m_positionPollTimer->stop();
    qDebug() << "Pause command sent";
}

void MP_Handler::stop()
{
    callService("Stop");
    m_positionPollTimer->stop();
    m_position = 0;
    emit positionChanged();
    qDebug() << "Stop command sent";
}

void MP_Handler::next()
{
    if (m_currentTrackIndex >= 0 && m_currentTrackIndex < m_mediaFiles.count() - 1) {
        selectMediaFile(m_currentTrackIndex + 1);
    } else if (m_mediaFiles.count() > 0) {
        // Loop to first track
        selectMediaFile(0);
    }
    qDebug() << "Next track";
}

void MP_Handler::previous()
{
    if (m_currentTrackIndex > 0) {
        selectMediaFile(m_currentTrackIndex - 1);
    } else if (m_mediaFiles.count() > 0) {
        // Loop to last track
        selectMediaFile(m_mediaFiles.count() - 1);
    }
    qDebug() << "Previous track";
}

void MP_Handler::seek(qint64 position)
{
    if (position >= 0 && position <= m_duration) {
        callService("Seek", {position});
        m_position = position;
        emit positionChanged();
        qDebug() << "Seek to position:" << position;
    }
}

void MP_Handler::selectUsbDevice(const QString &devicePath)
{
    callService("SelectUsbDevice", {devicePath});
    m_currentTrackIndex = -1;
    emit currentTrackIndexChanged();
    qDebug() << "Selected USB device:" << devicePath;
}

void MP_Handler::selectMediaFile(int index)
{
    if (index < 0 || index >= m_mediaFiles.count()) {
        qWarning() << "Invalid track index:" << index;
        return;
    }

    m_currentTrackIndex = index;
    emit currentTrackIndexChanged();

    callService("SelectMediaFile", {index});

    // Auto-play the selected file
    QTimer::singleShot(500, this, &MP_Handler::play);

    qDebug() << "Selected and playing media file:" << m_mediaFiles[index] << "at index:" << index;
}

void MP_Handler::refreshUsbDevices()
{
    callService("RefreshUsbDevices");
    qDebug() << "Refreshing USB devices";
}

void MP_Handler::handleServicePlaybackStateChanged(const QString &state)
{
    qDebug() << "Playback state changed:" << state;
    updateState(state);

    if (state == "Playing") {
        m_playing = true;
        m_positionPollTimer->start();
    } else {
        m_playing = false;
        if (state == "Stopped") {
            m_positionPollTimer->stop();
        }
    }

    emit playingChanged();
}

void MP_Handler::handleServicePositionChanged(qint64 pos)
{
    m_position = pos;
    emit positionChanged();
}

void MP_Handler::handleServiceDurationChanged(qint64 dur)
{
    m_duration = dur;
    emit durationChanged();
    qDebug() << "Duration changed to:" << dur;
}

void MP_Handler::handleUsbDevicesChanged(const QStringList &devices)
{
    m_usbDevices = devices;
    emit usbDevicesChanged();
    qDebug() << "USB devices updated:" << devices;
}

void MP_Handler::handleMediaFilesChanged(const QStringList &files)
{
    m_mediaFiles = files;
    m_currentTrackIndex = -1;
    emit mediaFilesChanged();
    emit currentTrackIndexChanged();
    qDebug() << "Media files updated:" << files.count() << "files";
}

void MP_Handler::handleCurrentDeviceChanged(const QString &device)
{
    m_currentDevice = device;
    emit currentDeviceChanged();
    qDebug() << "Current device changed:" << device;
}

void MP_Handler::handleUsbInserted(const QString &devicePath)
{
    qDebug() << "USB device inserted:" << devicePath;
    emit usbDeviceInserted(devicePath);
    setSourceType("usb");
}

void MP_Handler::handleUsbRemoved(const QString &devicePath)
{
    qDebug() << "USB device removed:" << devicePath;
    emit usbDeviceRemoved(devicePath);
}

void MP_Handler::pollPosition()
{
    if (m_serviceConnected && m_serviceInterface) {
        QDBusReply<qint64> reply = m_serviceInterface->call("GetPosition");
        if (reply.isValid()) {
            m_position = reply.value();
            emit positionChanged();
        }
    }
}
