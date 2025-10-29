import QtQuick
import QtQuick.Controls

Item {
    id: root

    property string sourceType: "usb"
    property string source: ""
    property bool isPlaying: false
    property string currentFileName: ""
    property int currentTrackIndex: -1
    property color accentColor: "#3b82f6"
    property color secondaryColor: "#334155"

    Rectangle {
        anchors.fill: parent
        color: "#0f172a"

        // USB Mode - Media player display
        Column {
            anchors.centerIn: parent
            spacing: 25
            width: parent.width * 0.85
            visible: sourceType === "usb"

            Rectangle {
                width: Math.min(parent.width * 0.5, 160)
                height: width
                radius: 15
                color: secondaryColor
                anchors.horizontalCenter: parent.horizontalCenter

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.color: accentColor
                    border.width: isPlaying ? 3 : 0
                    opacity: isPlaying ? 0.8 : 0

                    Behavior on opacity { NumberAnimation { duration: 500 } }

                    SequentialAnimation on border.width {
                        running: root.isPlaying
                        loops: Animation.Infinite
                        NumberAnimation { to: 5; duration: 1000 }
                        NumberAnimation { to: 3; duration: 1000 }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 12

                    Text {
                        text: isPlaying ? "♪" : "♫"
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: 50
                        color: "white"

                        SequentialAnimation on rotation {
                            running: root.isPlaying
                            loops: Animation.Infinite
                            NumberAnimation { to: 10; duration: 500 }
                            NumberAnimation { to: -10; duration: 500 }
                            NumberAnimation { to: 0; duration: 500 }
                        }
                    }

                    Label {
                        text: isPlaying ? "Now Playing" : "Ready"
                        color: "#9ca3af"
                        font.pixelSize: 12
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 100
                color: Qt.darker(secondaryColor, 1.1)
                radius: 8
                anchors.horizontalCenter: parent.horizontalCenter
                visible: currentFileName !== ""

                Column {
                    anchors.centerIn: parent
                    width: parent.width - 24
                    spacing: 10

                    Label {
                        text: "Track " + (currentTrackIndex + 1)
                        color: accentColor
                        font.pixelSize: 12
                        font.bold: true
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Label {
                        text: currentFileName
                        color: "white"
                        font.pixelSize: 15
                        font.bold: true
                        width: parent.width
                        elide: Text.ElideMiddle
                        horizontalAlignment: Text.AlignHCenter
                        maximumLineCount: 2
                        wrapMode: Text.Wrap
                    }

                    Row {
                        spacing: 8
                        anchors.horizontalCenter: parent.horizontalCenter

                        Text {
                            text: isPlaying ? "▶" : "⏸"
                            color: accentColor
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Label {
                            text: isPlaying ? "Playing" : "Paused"
                            color: "#9ca3af"
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 80
                color: Qt.darker(secondaryColor, 1.1)
                radius: 8
                anchors.horizontalCenter: parent.horizontalCenter
                visible: currentFileName === ""

                Column {
                    anchors.centerIn: parent
                    spacing: 10

                    Text {
                        text: "🎵"
                        font.pixelSize: 30
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Label {
                        text: "No track selected"
                        color: "#9ca3af"
                        font.pixelSize: 13
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Label {
                        text: "Select a file from the playlist"
                        color: "#6b7280"
                        font.pixelSize: 10
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }

        // YouTube Mode - Load YouTubeView component
        Loader {
            id: youtubeLoader
            anchors.fill: parent
            visible: sourceType === "youtube"
            active: visible
            source: "qrc:/qml/YouTubeView.qml"

            onLoaded: {
                item.accentColor = Qt.binding(function() { return root.accentColor })
                item.secondaryColor = Qt.binding(function() { return root.secondaryColor })
            }

            onStatusChanged: {
                if (youtubeLoader.status === Loader.Error) {
                    console.error("Failed to load YouTubeView component")
                }
            }
        }
    }
}
