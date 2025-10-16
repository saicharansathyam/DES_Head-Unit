import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import QtQuick.Dialogs

ApplicationWindow {
    id: root
    width: 824
    height: 550
    //flags: Qt.FramelessWindowHint
    visible: true
    title: "MediaPlayer"

    property color primaryColor: "#1e293b"
    property color secondaryColor: "#334155"
    property color accentColor: "#3b82f6"

    MediaPlayer {
        id: player

        audioOutput: AudioOutput {
            volume: player.volume / 100.0
        }

        videoOutput: videoOutput

        onPlaybackStateChanged: {
            player.playing = (playbackState === MediaPlayer.PlayingState)
        }

        onPositionChanged: {
            player.position = position
        }

        onDurationChanged: {
            player.setDuration(duration)
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

                        Rectangle {
                            width: 100
                            height: 100
                            color: "#64748b"
                            radius: 10
                            anchors.horizontalCenter: parent.horizontalCenter
                            opacity: 0.5

                            Text {
                                text: "♪"
                                anchors.centerIn: parent
                                font.pixelSize: 48
                                color: "white"
                            }
                        }

                        Label {
                            text: player.source ? player.source.toString().split('/').pop() : "No Media Loaded"
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
                        opacity: player.playing ? 0.5 : 0

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

            // Control bar - FIXED SECTION
            Rectangle {
                Layout.fillWidth: true
                height: 180  // Fixed height instead of Layout.preferredHeight
                color: primaryColor

                Column {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 15

                    // Progress bar section
                    Item {
                        width: parent.width
                        height: 40

                        Column {
                            anchors.fill: parent
                            spacing: 5

                            Slider {
                                id: seekSlider
                                width: parent.width
                                height: 20
                                from: 0
                                to: player.duration > 0 ? player.duration : 1
                                value: player.position
                                enabled: player.duration > 0

                                onMoved: {
                                    player.position = value
                                    player.seek(value)
                                }

                                background: Rectangle {
                                    x: seekSlider.leftPadding
                                    y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                                    width: seekSlider.availableWidth
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
                                    x: seekSlider.leftPadding + seekSlider.visualPosition * (seekSlider.availableWidth - width)
                                    y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: seekSlider.pressed ? Qt.lighter(accentColor, 1.2) : accentColor

                                    Behavior on color {
                                        ColorAnimation { duration: 150 }
                                    }
                                }
                            }

                            Row {
                                width: parent.width

                                Label {
                                    id: playerPosition
                                    text: formatTime(player.position)
                                    color: "white"
                                    font.pixelSize: 12
                                }

                                Item {
                                    width: parent.width - 5
                                    height: 1
                                }

                                Label {
                                    id: playerDuration
                                    text: formatTime(player.duration)
                                    color: "white"
                                    font.pixelSize: 12
                                }
                            }
                        }
                    }

                    // Main controls section - COMPLETELY REWRITTEN
                    Item {
                        width: parent.width
                        height: 60

                        Row {
                            anchors.fill: parent
                            spacing: 0

                            // Left - Open button
                            Item {
                                width: parent.width * 0.2
                                height: parent.height

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 80
                                    height: 40
                                    color: openButton.hovered ? Qt.lighter(secondaryColor, 1.2) : secondaryColor
                                    radius: 6

                                    MouseArea {
                                        id: openButton
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: fileDialog.open()

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Open"
                                            color: "white"
                                            font.pixelSize: 14
                                        }
                                    }
                                }
                            }

                            // Center - Playback controls
                            Item {
                                width: parent.width * 0.6
                                height: parent.height

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 15

                                    // Previous button
                                    Rectangle {
                                        width: 40
                                        height: 40
                                        radius: 20
                                        color: prevButton.hovered ? Qt.lighter(secondaryColor, 1.2) : "transparent"
                                        border.color: prevButton.hovered ? secondaryColor : "transparent"
                                        border.width: 1

                                        MouseArea {
                                            id: prevButton
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: player.previous()
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "⏮"
                                            color: "white"
                                            font.pixelSize: 16
                                        }
                                    }

                                    // Play/Pause button
                                    Rectangle {
                                        width: 56
                                        height: 56
                                        radius: 28
                                        color: playButton.hovered ? Qt.lighter(accentColor, 1.1) : accentColor

                                        Behavior on color {
                                            ColorAnimation { duration: 150 }
                                        }

                                        MouseArea {
                                            id: playButton
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: {
                                                if (handler.playing) {
                                                    player.pause()
                                                } else {
                                                    player.play()
                                                }
                                            }
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: player.playing ? "⏸" : "▶"
                                            color: "white"
                                            font.pixelSize: 20
                                        }
                                    }

                                    // Next button
                                    Rectangle {
                                        width: 40
                                        height: 40
                                        radius: 20
                                        color: nextButton.hovered ? Qt.lighter(secondaryColor, 1.2) : "transparent"
                                        border.color: nextButton.hovered ? secondaryColor : "transparent"
                                        border.width: 1

                                        MouseArea {
                                            id: nextButton
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: player.next()
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "⏭"
                                            color: "white"
                                            font.pixelSize: 16
                                        }
                                    }

                                    // Stop button
                                    Rectangle {
                                        width: 40
                                        height: 40
                                        radius: 20
                                        color: stopButton.hovered ? Qt.lighter(secondaryColor, 1.2) : "transparent"
                                        border.color: stopButton.hovered ? secondaryColor : "transparent"
                                        border.width: 1

                                        MouseArea {
                                            id: stopButton
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: {
                                                player.stop()
                                            }
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "⏹"
                                            color: "white"
                                            font.pixelSize: 16
                                        }
                                    }
                                }
                            }

                            // Right - Volume control
                            Item {
                                width: parent.width * 0.2
                                height: parent.height

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 10

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "🔊"
                                        color: "white"
                                        font.pixelSize: 16
                                        opacity: 0.7
                                    }

                                    Slider {
                                        id: volumeSlider
                                        width: 100
                                        height: 20
                                        from: 0
                                        to: 100
                                        value: handler.volume
                                        anchors.verticalCenter: parent.verticalCenter

                                        onValueChanged: {
                                            handler.volume = value
                                            player.audioOutput.volume = value / 100.0
                                        }

                                        background: Rectangle {
                                            x: volumeSlider.leftPadding
                                            y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                                            width: volumeSlider.availableWidth
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
                                            x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                                            y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                                            width: 12
                                            height: 12
                                            radius: 6
                                            color: volumeSlider.pressed ? Qt.lighter(accentColor, 1.2) : accentColor
                                        }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: Math.round(handler.volume) + "%"
                                        color: "white"
                                        font.pixelSize: 12
                                        width: 35
                                    }
                                }
                            }
                        }
                    }

                    // Status bar
                    Item {
                        id:statusbar
                        width: parent.width
                        height: 20

                        Row {
                            anchors.fill: parent
                            spacing: 10

                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: player.playing ? "#10b981" : "#6b7280"
                                anchors.verticalCenter: parent.verticalCenter

                                SequentialAnimation on opacity {
                                    running: player.playing
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 0.3; duration: 500 }
                                    NumberAnimation { to: 1.0; duration: 500 }
                                }
                            }

                            Label {
                                text: handler.currentState || "Ready"
                                color: "#9ca3af"
                                font.pixelSize: 12
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Item {
                                width: parent.width - 300
                                height: 1
                            }

                            Label {
                                text: "MediaPlayer v1.0"
                                color: "#6b7280"
                                font.pixelSize: 10
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                            }
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
