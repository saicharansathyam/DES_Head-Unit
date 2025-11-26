import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    color: "#0f172a"

    // Signal to notify when a song is selected
    signal songSelected()

    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Text {
            text: "USB Playlist"
            font.pixelSize: 24
            font.bold: true
            color: theme.themeColor
            anchors.horizontalCenter: parent.horizontalCenter

            Behavior on color { ColorAnimation { duration: 300 } }
        }

        ListView {
            id: playlistView
            width: parent.width
            height: parent.height - 50
            clip: true
            spacing: 8

            model: mpHandler.playlist

            delegate: Rectangle {
                width: playlistView.width
                height: 60
                radius: 8
                color: model.isPlaying ? theme.themeColor : "#1e293b"
                border.width: model.isPlaying ? 2 : 1
                border.color: model.isPlaying ? theme.accentColor : "#334155"

                Behavior on color { ColorAnimation { duration: 200 } }

                Row {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 15

                    // Track number
                    Text {
                        text: (index + 1).toString()
                        font.pixelSize: 18
                        font.bold: model.isPlaying
                        color: model.isPlaying ? "white" : theme.accentColor
                        width: 30
                        anchors.verticalCenter: parent.verticalCenter

                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    // Track info
                    Column {
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 100

                        Text {
                            text: model.title || "Unknown Track"
                            font.pixelSize: 16
                            font.bold: model.isPlaying
                            color: "white"
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: model.artist || "Unknown Artist"
                            font.pixelSize: 13
                            color: model.isPlaying ? "#ffffff" : "#94a3b8"
                            elide: Text.ElideRight
                            width: parent.width

                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }

                    // Duration
                    Text {
                        text: model.duration || "0:00"
                        font.pixelSize: 14
                        color: "#94a3b8"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        console.log("Playing track:", model.title)
                        mpHandler.playTrack(index)
                        root.songSelected()  // Emit signal to switch back to MediaDisplay
                    }
                }
            }

            ScrollBar.vertical: ScrollBar {
                active: true
                policy: ScrollBar.AsNeeded

                contentItem: Rectangle {
                    implicitWidth: 8
                    radius: 4
                    color: theme.themeColor
                    opacity: parent.pressed ? 1.0 : 0.6

                    Behavior on color { ColorAnimation { duration: 300 } }
                }
            }
        }
    }
}
