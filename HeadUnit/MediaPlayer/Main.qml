import QtQuick
import QtQuick.Controls
import QtMultimedia
import QtQuick.Dialogs
import MediaPlayer 1.0

Window {
    width: 1152
    height: 560
    visible: true
    title: qsTr("Media Player")

    MPHandler{
        id: handler
    }

    MediaPlayer {
        id: player
        source: handler.source
        autoPlay: false
        onErrorOccurred: {
            errorLabel.text = "Error: " + errorString
        }
        onPlaybackStateChanged: {
            handler.playing = (playbackState === MediaPlayer.PlayingState)
        }
    }

    VideoOutput {
        id: videoOutput
        anchors.fill: parent
        anchors.bottomMargin: 80
        fillMode: VideoOutput.PreserveAspectFit
    }

    Rectangle {
        id: controlBar
        width: parent.width
        height: 80
        color: "#222"
        anchors.bottom: parent.bottom

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 24
            anchors.left: parent.left
            anchors.leftMargin: 24

            Button {
                text: player.playbackState === MediaPlayer.PlayingState ? "Pause" : "Play"
                width: 80
                onClicked: {
                    if (player.playbackState === MediaPlayer.PlayingState) {
                        player.pause()
                        handler.pause()
                    } else {
                        player.play()
                        handler.play()
                    }
                }
            }

            Button {
                text: "Stop"
                width: 80
                onClicked: {
                    player.stop()
                    handler.stop()
                }
            }

            Button {
                text: "Open"
                width: 80
                onClicked: fileDialog.open()
            }

            Slider {
                id: seekSlider
                width: 400
                from: 0
                to: player.duration > 0 ? player.duration : 1
                value: player.position
                onMoved: player.seek(value)
                enabled: player.duration > 0
            }

            Label {
                text: Qt.formatTime(player.position / 1000, "mm:ss") + " / " +
                      Qt.formatTime(player.duration / 1000, "mm:ss")
                color: "white"
                width: 120
                horizontalAlignment: Label.AlignHCenter
            }

            Slider {
                id: volumeSlider
                width: 120
                from: 0
                to: 1
                value: player.volume
                onValueChanged: player.volume = value
            }

            Label {
                text: "Volume"
                color: "white"
                width: 60
                horizontalAlignment: Label.AlignHCenter
            }
        }
    }

    FileDialog {
        id: fileDialog
        title: "Select Media File"
        nameFilters: ["Video files (*.mp4 *.avi *.mkv)", "Audio files (*.mp3 *.wav)", "All files (*)"]
        onAccepted: {
            handler.source = fileDialog.fileUrl
        }
    }

    Label {
        id: errorLabel
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: controlBar.top
        color: "red"
        font.pixelSize: 16
        text: ""
    }
}
