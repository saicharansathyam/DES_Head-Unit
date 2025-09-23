import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import QtQuick.Dialogs
import MediaPlayer 1.0

ApplicationWindow {
    id: root
    width: 1000
    height: 600
    visible: true
    title: "MediaPlayer"
    
    property color primaryColor: "#1e293b"
    property color secondaryColor: "#334155"
    property color accentColor: "#3b82f6"
    
    MPHandler {
        id: handler
        onMediaError: function(error) {
            errorLabel.text = error
            errorTimer.restart()
        }
        onDurationChanged: {
            player.duration = handler.duration
        }
    }

    MediaPlayer {
        id: player
        source: handler.source
        audioOutput: AudioOutput {
            volume: handler.volume / 100.0
        }
        videoOutput: videoOutput
        
        onPlaybackStateChanged: {
            handler.playing = (playbackState === MediaPlayer.PlayingState)
        }
        
        onPositionChanged: {
            handler.position = position
        }
        
        onDurationChanged: {
            handler.setDuration(duration)
        }
        
        onErrorOccurred: function(error, errorString) {
            errorLabel.text = "Playback Error: " + errorString
            errorTimer.restart()
            handler.stop()
        }
        
        onHasVideoChanged: {
            if (hasVideo) {
                videoOutput.visible = true
                albumArt.visible = false
            } else {
                videoOutput.visible = false
                albumArt.visible = true
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: primaryColor }
            GradientStop { position: 1.0; color: "#0f172a" }
        }
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 0
            
            // Media display area
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"
                
                VideoOutput {
                    id: videoOutput
                    anchors.fill: parent
                    fillMode: VideoOutput.PreserveAspectFit
                    visible: false
                }
                
                // Album art / visualization placeholder when no video
                Rectangle {
                    id: albumArt
                    anchors.centerIn: parent
                    width: Math.min(parent.width * 0.6, parent.height * 0.6)
                    height: width
                    radius: 20
                    color: secondaryColor
                    visible: !videoOutput.visible
                    
                    Column {
                        anchors.centerIn: parent
                        spacing: 20
                        
                        Image {
                            source: "qrc:/icons/music-note.svg"
                            width: 100
                            height: 100
                            fillMode: Image.PreserveAspectFit
                            anchors.horizontalCenter: parent.horizontalCenter
                            opacity: 0.5
                        }
                        
                        Label {
                            text: handler.source ? handler.source.toString().split('/').pop() : "No Media Loaded"
                            color: "white"
                            font.pixelSize: 16
                            opacity: 0.7
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                    
                    // Animated border when playing
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "transparent"
                        border.color: accentColor
                        border.width: 2
                        opacity: handler.playing ? 0.5 : 0
                        
                        Behavior on opacity {
                            NumberAnimation { duration: 500 }
                        }
                        
                        SequentialAnimation on border.width {
                            running: handler.playing
                            loops: Animation.Infinite
                            NumberAnimation { to: 4; duration: 1000 }
                            NumberAnimation { to: 2; duration: 1000 }
                        }
                    }
                }
            }
            
            // Error display
            Rectangle {
                id: errorContainer
                Layout.fillWidth: true
                height: errorLabel.text ? 40 : 0
                color: "#ef4444"
                visible: height > 0
                
                Behavior on height {
                    NumberAnimation { duration: 200 }
                }
                
                Label {
                    id: errorLabel
                    anchors.centerIn: parent
                    color: "white"
                    font.pixelSize: 14
                    text: ""
                    
                    Timer {
                        id: errorTimer
                        interval: 5000
                        onTriggered: errorLabel.text = ""
                    }
                }
            }
            
            // Control bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 180
                color: primaryColor
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 15
                    
                    // Progress bar
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        
                        Slider {
                            id: seekSlider
                            Layout.fillWidth: true
                            from: 0
                            to: handler.duration > 0 ? handler.duration : 1
                            value: handler.position
                            enabled: handler.duration > 0
                            
                            onMoved: {
                                player.position = value
                                handler.seek(value)
                            }
                            
                            background: Rectangle {
                                height: 6
                                radius: 3
                                color: secondaryColor
                                
                                Rectangle {
                                    width: seekSlider.visualPosition * parent.width
                                    height: parent.height
                                    radius: 3
                                    color: accentColor
                                }
                            }
                            
                            handle: Rectangle {
                                x: seekSlider.visualPosition * (seekSlider.width - width)
                                y: (seekSlider.height - height) / 2
                                width: 16
                                height: 16
                                radius: 8
                                color: seekSlider.pressed ? Qt.lighter(accentColor, 1.2) : accentColor
                                
                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                            }
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            
                            Label {
                                text: formatTime(handler.position)
                                color: "white"
                                font.pixelSize: 12
                            }
                            
                            Item { Layout.fillWidth: true }
                            
                            Label {
                                text: formatTime(handler.duration)
                                color: "white"
                                font.pixelSize: 12
                            }
                        }
                    }
                    
                    // Main controls
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 15
                        
                        // Left side - File controls
                        Button {
                            text: "Open"
                            Layout.preferredWidth: 80
                            onClicked: fileDialog.open()
                            
                            background: Rectangle {
                                color: parent.hovered ? Qt.lighter(secondaryColor, 1.2) : secondaryColor
                                radius: 6
                            }
                            
                            contentItem: Text {
                                text: parent.text
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        // Center - Playback controls
                        RowLayout {
                            spacing: 10
                            
                            Button {
                                icon.source: "qrc:/icons/skip-back.svg"
                                icon.width: 24
                                icon.height: 24
                                onClicked: handler.previous()
                                
                                background: Rectangle {
                                    width: 40
                                    height: 40
                                    radius: 20
                                    color: parent.hovered ? Qt.lighter(secondaryColor, 1.2) : "transparent"
                                }
                            }
                            
                            Button {
                                icon.source: handler.playing ? "qrc:/icons/pause.svg" : "qrc:/icons/play.svg"
                                icon.width: 32
                                icon.height: 32
                                onClicked: {
                                    if (handler.playing) {
                                        player.pause()
                                        handler.pause()
                                    } else {
                                        player.play()
                                        handler.play()
                                    }
                                }
                                
                                background: Rectangle {
                                    width: 56
                                    height: 56
                                    radius: 28
                                    color: parent.hovered ? Qt.lighter(accentColor, 1.1) : accentColor
                                    
                                    Behavior on color {
                                        ColorAnimation { duration: 150 }
                                    }
                                }
                            }
                            
                            Button {
                                icon.source: "qrc:/icons/skip-forward.svg"
                                icon.width: 24
                                icon.height: 24
                                onClicked: handler.next()
                                
                                background: Rectangle {
                                    width: 40
                                    height: 40
                                    radius: 20
                                    color: parent.hovered ? Qt.lighter(secondaryColor, 1.2) : "transparent"
                                }
                            }
                            
                            Button {
                                icon.source: "qrc:/icons/stop.svg"
                                icon.width: 24
                                icon.height: 24
                                onClicked: {
                                    player.stop()
                                    handler.stop()
                                }
                                
                                background: Rectangle {
                                    width: 40
                                    height: 40
                                    radius: 20
                                    color: parent.hovered ? Qt.lighter(secondaryColor, 1.2) : "transparent"
                                }
                            }
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        // Right side - Volume control
                        RowLayout {
                            spacing: 10
                            
                            Image {
                                source: "qrc:/icons/volume.svg"
                                width: 20
                                height: 20
                                opacity: 0.7
                            }
                            
                            Slider {
                                id: volumeSlider
                                Layout.preferredWidth: 100
                                from: 0
                                to: 100
                                value: handler.volume
                                onValueChanged: {
                                    handler.volume = value
                                    player.audioOutput.volume = value / 100.0
                                }
                                
                                background: Rectangle {
                                    height: 4
                                    radius: 2
                                    color: secondaryColor
                                    
                                    Rectangle {
                                        width: volumeSlider.visualPosition * parent.width
                                        height: parent.height
                                        radius: 2
                                        color: accentColor
                                    }
                                }
                                
                                handle: Rectangle {
                                    x: volumeSlider.visualPosition * (volumeSlider.width - width)
                                    y: (volumeSlider.height - height) / 2
                                    width: 12
                                    height: 12
                                    radius: 6
                                    color: volumeSlider.pressed ? Qt.lighter(accentColor, 1.2) : accentColor
                                }
                            }
                            
                            Label {
                                text: handler.volume + "%"
                                color: "white"
                                font.pixelSize: 12
                                Layout.preferredWidth: 35
                            }
                        }
                    }
                    
                    // Status bar
                    RowLayout {
                        Layout.fillWidth: true
                        
                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            color: handler.playing ? "#10b981" : "#6b7280"
                            
                            SequentialAnimation on opacity {
                                running: handler.playing
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.3; duration: 500 }
                                NumberAnimation { to: 1.0; duration: 500 }
                            }
                        }
                        
                        Label {
                            text: handler.currentState
                            color: "#9ca3af"
                            font.pixelSize: 12
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Label {
                            text: "MediaPlayer v1.0"
                            color: "#6b7280"
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }
    }
    
    FileDialog {
        id: fileDialog
        title: "Select Media File"
        nameFilters: [
            "All Media (*.mp4 *.avi *.mkv *.mov *.mp3 *.wav *.flac *.m4a)",
            "Video files (*.mp4 *.avi *.mkv *.mov)",
            "Audio files (*.mp3 *.wav *.flac *.m4a)",
            "All files (*)"
        ]
        onAccepted: {
            handler.source = fileDialog.selectedFile.toString()
            player.source = fileDialog.selectedFile
        }
    }
    
    // Helper function to format time
    function formatTime(ms) {
        if (ms === 0 || isNaN(ms)) return "00:00"
        var seconds = Math.floor(ms / 1000)
        var minutes = Math.floor(seconds / 60)
        var hours = Math.floor(minutes / 60)
        seconds = seconds % 60
        minutes = minutes % 60
        
        if (hours > 0) {
            return hours + ":" + 
                   (minutes < 10 ? "0" : "") + minutes + ":" + 
                   (seconds < 10 ? "0" : "") + seconds
        } else {
            return (minutes < 10 ? "0" : "") + minutes + ":" + 
                   (seconds < 10 ? "0" : "") + seconds
        }
    }
}