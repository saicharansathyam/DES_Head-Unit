#include "mp_handler.h"
#include <QDebug>
#include <QDBusReply>

MP_Handler::MP_Handler(QObject *parent)
    : QObject(parent)
    , m_playing(false)
    , m_volume(50)
    , m_position(0)
    , m_duration(0)
    , m_currentState("Stopped")
    , m_dbusInterface(nullptr)
    , m_dbusConnected(false)
{
    // Setup position update timer
    m_positionTimer = new QTimer(this);
    m_positionTimer->setInterval(100); // Update every 100ms
    connect(m_positionTimer, &QTimer::timeout, this, &MP_Handler::updatePosition);
    
    setupDBusConnection();
    registerDBusService();
}

MP_Handler::~MP_Handler()
{
    if (m_positionTimer) {
        m_positionTimer->stop();
        delete m_positionTimer;
    }
    
    if (m_dbusInterface) {
        delete m_dbusInterface;
    }
    
    // Unregister the service when shutting down
    QDBusConnection sessionBus = QDBusConnection::sessionBus();
    if (sessionBus.isConnected()) {
        sessionBus.unregisterService("com.example.MediaPlayer");
    }
}

void MP_Handler::setupDBusConnection()
{
    // Connect to the session bus
    QDBusConnection sessionBus = QDBusConnection::sessionBus();
    
    if (!sessionBus.isConnected()) {
        qWarning() << "Cannot connect to the D-Bus session bus";
        emit dbusConnectionError("Cannot connect to D-Bus session bus");
        return;
    }
    
    qDebug() << "Successfully connected to D-Bus session bus";

    // Create interface to communicate with other HeadUnit components
    m_dbusInterface = new QDBusInterface(
        "com.example.HeadUnit",               // Service name
        "/com/example/HeadUnit/MediaPlayer",  // Path
        "com.example.HeadUnit.MediaPlayer",   // Interface
        sessionBus,
        this
    );

    if (!m_dbusInterface->isValid()) {
        qWarning() << "D-Bus interface not valid (this is normal if no other service is running):" 
                   << sessionBus.lastError().message();
        // Don't return here - we can still register our own service
    }

    // Connect to media control signals from other components
    bool connected = sessionBus.connect(
        "",  // Empty string means any service
        "/com/example/HeadUnit/MediaPlayer",
        "com.example.HeadUnit.MediaPlayer",
        "mediaCommand",
        this,
        SLOT(handleDbusMediaCommand(QString))
    );
    
    if (connected) {
        qDebug() << "Successfully connected to mediaCommand signal";
    } else {
        qWarning() << "Failed to connect to mediaCommand signal:" << sessionBus.lastError().message();
    }
    
    // Connect to volume control signals
    connected = sessionBus.connect(
        "",  // Empty string means any service
        "/com/example/HeadUnit/MediaPlayer",
        "com.example.HeadUnit.MediaPlayer",
        "volumeChanged",
        this,
        SLOT(handleDbusVolumeChange(int))
    );
    
    if (connected) {
        qDebug() << "Successfully connected to volumeChanged signal";
        m_dbusConnected = true;
    } else {
        qWarning() << "Failed to connect to volumeChanged signal:" << sessionBus.lastError().message();
    }
}

void MP_Handler::registerDBusService()
{
    QDBusConnection sessionBus = QDBusConnection::sessionBus();
    
    // Register the service
    if (!sessionBus.registerService("com.example.MediaPlayer")) {
        qWarning() << "Could not register D-Bus service:" << sessionBus.lastError().message();
        qDebug() << "This is normal if another instance is already running";
    } else {
        qDebug() << "Successfully registered D-Bus service: com.example.MediaPlayer";
    }
    
    // Register this object on the bus
    if (!sessionBus.registerObject("/com/example/MediaPlayer", 
                                   this,
                                   QDBusConnection::ExportAllSlots | 
                                   QDBusConnection::ExportAllSignals |
                                   QDBusConnection::ExportAllProperties)) {
        qWarning() << "Could not register D-Bus object:" << sessionBus.lastError().message();
    } else {
        qDebug() << "Successfully registered D-Bus object at /com/example/MediaPlayer";
    }
}

void MP_Handler::handleDbusMediaCommand(const QString &command)
{
    qDebug() << "Received media command via D-Bus:" << command;
    
    if (command == "play") {
        play();
    } else if (command == "pause") {
        pause();
    } else if (command == "stop") {
        stop();
    } else if (command == "next") {
        next();
    } else if (command == "previous") {
        previous();
    } else {
        qWarning() << "Unknown media command:" << command;
    }
}

void MP_Handler::handleDbusVolumeChange(int volume)
{
    qDebug() << "Received volume change via D-Bus:" << volume;
    setVolume(volume);
}

void MP_Handler::updatePosition()
{
    if (m_playing && m_position < m_duration) {
        m_position += 100; // Increment by 100ms
        emit positionChanged();
        
        // Stop at end of media
        if (m_position >= m_duration && m_duration > 0) {
            stop();
        }
    }
}

QString MP_Handler::source() const
{
    return m_source;
}

void MP_Handler::setSource(const QString &src)
{
    if (m_source != src) {
        m_source = src;
        emit sourceChanged();
        
        // Reset position when new source is loaded
        m_position = 0;
        emit positionChanged();
        
        // Notify other components about source change
        sendDBusMessage("sourceChanged", src);
        
        qDebug() << "Media source changed to:" << src;
    }
}

bool MP_Handler::playing() const
{
    return m_playing;
}

int MP_Handler::volume() const
{
    return m_volume;
}

void MP_Handler::setVolume(int vol)
{
    // Clamp volume between 0 and 100
    vol = qBound(0, vol, 100);
    
    if (m_volume != vol) {
        m_volume = vol;
        emit volumeChanged();
        
        // Notify other components about volume change
        sendDBusMessage("setVolume", vol);
        
        qDebug() << "Volume changed to:" << vol;
    }
}

qint64 MP_Handler::position() const
{
    return m_position;
}

void MP_Handler::setPosition(qint64 pos)
{
    if (m_position != pos) {
        m_position = pos;
        emit positionChanged();
    }
}

qint64 MP_Handler::duration() const
{
    return m_duration;
}

void MP_Handler::setDuration(qint64 dur)
{
    if (m_duration != dur) {
        m_duration = dur;
        emit durationChanged();
        qDebug() << "Media duration set to:" << dur << "ms";
    }
}

QString MP_Handler::currentState() const
{
    return m_currentState;
}

void MP_Handler::updateState(const QString &state)
{
    if (m_currentState != state) {
        m_currentState = state;
        emit currentStateChanged();
        
        // Notify other components about state change
        sendDBusMessage("stateChanged", state);
    }
}

void MP_Handler::play()
{
    if (!m_source.isEmpty()) {
        m_playing = true;
        emit playingChanged();
        updateState("Playing");
        
        // Start position timer
        m_positionTimer->start();
        
        sendDBusMessage("play");
        qDebug() << "Media playback started";
    } else {
        emit mediaError("No media source loaded");
        qWarning() << "Cannot play: no media source loaded";
    }
}

void MP_Handler::pause()
{
    m_playing = false;
    emit playingChanged();
    updateState("Paused");
    
    // Stop position timer
    m_positionTimer->stop();
    
    sendDBusMessage("pause");
    qDebug() << "Media playback paused";
}

void MP_Handler::stop()
{
    m_playing = false;
    emit playingChanged();
    updateState("Stopped");
    
    // Stop position timer and reset position
    m_positionTimer->stop();
    m_position = 0;
    emit positionChanged();
    
    sendDBusMessage("stop");
    qDebug() << "Media playback stopped";
}

void MP_Handler::next()
{
    sendDBusMessage("next");
    qDebug() << "Next track requested";
}

void MP_Handler::previous()
{
    sendDBusMessage("previous");
    qDebug() << "Previous track requested";
}

void MP_Handler::seek(qint64 position)
{
    if (position >= 0 && position <= m_duration) {
        m_position = position;
        emit positionChanged();
        sendDBusMessage("seek", position);
        qDebug() << "Seeking to position:" << position << "ms";
    }
}

void MP_Handler::sendDBusMessage(const QString &method, const QVariant &arg)
{
    if (!m_dbusConnected) {
        qDebug() << "D-Bus not connected, skipping message:" << method;
        return;
    }
    
    QDBusMessage msg = QDBusMessage::createMethodCall(
        "com.example.HeadUnit",       // service name
        "/com/example/HeadUnit",      // object path
        "com.example.HeadUnit",       // interface name
        method
    );
    
    if (arg.isValid()) {
        msg << arg;
    }

    QDBusMessage reply = QDBusConnection::sessionBus().call(msg);

    if (reply.type() == QDBusMessage::ErrorMessage) {
        qDebug() << "[DBus] No active HeadUnit service (this is normal)";
    } else if (reply.type() == QDBusMessage::ReplyMessage) {
        if (!reply.arguments().isEmpty()) {
            qDebug() << "[DBus] Reply:" << reply.arguments().at(0).toString();
        }
    }
}