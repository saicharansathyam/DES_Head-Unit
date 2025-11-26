import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    color: "#0f172a"

    // Signal to notify when a song is selected
    signal songSelected()

    // Timer to refresh playlist periodically
    Timer {
        id: refreshTimer
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            if (mpHandler) {
                mpHandler.refreshMediaFiles()
            }
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Row {
            width: parent.width
            spacing: 15

            Text {
                text: "USB Playlist"
                font.pixelSize: 24
                font.bold: true
                color: theme.themeColor
                anchors.verticalCenter: parent.verticalCenter

                Behavior on color { ColorAnimation { duration: 300 } }
            }

            Item { width: parent.width - 400 }

            // Refresh button
            Button {
                width: 40
                height: 40
                anchors.verticalCenter: parent.verticalCenter

                background: Rectangle {
                    color: {
                        if (parent.pressed) return theme.buttonPressedColor
                        if (parent.hovered) return theme.buttonHoverColor
                        return theme.themeColor
                    }
                    radius: 8
                    border.width: 1
                    border.color: theme.accentColor

                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                contentItem: Text {
                    text: "🔄"
                    font.pixelSize: 20
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    if (mpHandler) {
                        mpHandler.refreshMediaFiles()
                        console.log("Refreshing media files...")
                    }
                }
            }

            Text {
                text: playlistView.count + " tracks"
                font.pixelSize: 14
                color: "#94a3b8"
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Empty state
        Rectangle {
            width: parent.width
            height: parent.height - 50
            visible: playlistView.count === 0
            color: "#1e293b"
            radius: 12
            border.width: 1
            border.color: "#334155"

            Column {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    text: "💾"
                    font.pixelSize: 60
                    anchors.horizontalCenter: parent.horizontalCenter
                    opacity: 0.5
                }

                Column {
                    spacing: 10
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        text: "No Media Files Found"
                        font.pixelSize: 18
                        font.bold: true
                        color: "white"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: "Insert a USB drive with music files"
                        font.pixelSize: 14
                        color: "#94a3b8"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                Button {
                    width: 150
                    height: 45
                    anchors.horizontalCenter: parent.horizontalCenter

                    background: Rectangle {
                        color: {
                            if (parent.pressed) return theme.buttonPressedColor
                            if (parent.hovered) return theme.buttonHoverColor
                            return theme.themeColor
                        }
                        radius: 8
                        border.width: 2
                        border.color: theme.accentColor

                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    contentItem: Text {
                        text: "Scan USB"
                        font.pixelSize: 14
                        font.bold: true
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        if (mpHandler) {
                            mpHandler.refreshUsbDevices()
                            mpHandler.refreshMediaFiles()
                        }
                    }
                }
            }
        }

        ListView {
            id: playlistView
            width: parent.width
            height: parent.height - 50
            visible: count > 0
            clip: true
            spacing: 8

            model: mpHandler ? mpHandler.mediaFileList : []

            delegate: Rectangle {
                required property string modelData
                required property int index

                width: playlistView.width
                height: 60
                radius: 8
                color: {
                    if (mpHandler && mpHandler.currentMediaIndex === index) {
                        return theme.themeColor
                    }
                    return mouseArea.containsMouse ? "#334155" : "#1e293b"
                }
                border.width: mpHandler && mpHandler.currentMediaIndex === index ? 2 : 1
                border.color: mpHandler && mpHandler.currentMediaIndex === index ? theme.accentColor : "#334155"

                Behavior on color { ColorAnimation { duration: 200 } }

                Row {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 15

                    // Play indicator
                    Rectangle {
                        width: 4
                        height: parent.height
                        radius: 2
                        color: theme.accentColor
                        visible: mpHandler && mpHandler.currentMediaIndex === index && mpHandler.isPlaying
                        anchors.verticalCenter: parent.verticalCenter

                        Behavior on color { ColorAnimation { duration: 300 } }

                        SequentialAnimation on opacity {
                            running: mpHandler && mpHandler.currentMediaIndex === index && mpHandler.isPlaying
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.3; duration: 800 }
                            NumberAnimation { to: 1.0; duration: 800 }
                        }
                    }

                    // Track number
                    Text {
                        text: (index + 1).toString()
                        font.pixelSize: 18
                        font.bold: mpHandler && mpHandler.currentMediaIndex === index
                        color: mpHandler && mpHandler.currentMediaIndex === index ? "white" : theme.accentColor
                        width: 40
                        anchors.verticalCenter: parent.verticalCenter

                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    // Track icon
                    Text {
                        text: getFileIcon(modelData)
                        font.pixelSize: 24
                        color: mpHandler && mpHandler.currentMediaIndex === index ? "white" : "#94a3b8"
                        anchors.verticalCenter: parent.verticalCenter

                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    // Track info
                    Column {
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 200

                        Text {
                            text: extractFileName(modelData)
                            font.pixelSize: 16
                            font.bold: mpHandler && mpHandler.currentMediaIndex === index
                            color: "white"
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: extractFileExtension(modelData).toUpperCase() + " • USB"
                            font.pixelSize: 12
                            color: mpHandler && mpHandler.currentMediaIndex === index ? "#ffffff" : "#94a3b8"
                            elide: Text.ElideRight
                            width: parent.width

                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        console.log("Playing track:", modelData)
                        if (mpHandler) {
                            mpHandler.playTrack(index)
                        }
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

    // Helper functions
    function extractFileName(filePath) {
        var fileName = filePath.split('/').pop()
        // Remove extension
        var lastDot = fileName.lastIndexOf('.')
        if (lastDot > 0) {
            return fileName.substring(0, lastDot)
        }
        return fileName
    }

    function extractFileExtension(filePath) {
        var fileName = filePath.split('/').pop()
        var lastDot = fileName.lastIndexOf('.')
        if (lastDot > 0) {
            return fileName.substring(lastDot + 1)
        }
        return ""
    }

    function getFileIcon(filePath) {
        var ext = extractFileExtension(filePath).toLowerCase()

        // Video files
        if (ext === "mp4" || ext === "avi" || ext === "mkv" || ext === "mov" || ext === "webm") {
            return "🎬"
        }

        // Audio files
        return "🎵"
    }

    Component.onCompleted: {
        console.log("USBPlaylist loaded")
        if (mpHandler) {
            console.log("Media files count:", mpHandler.mediaFileList.length)
        }
    }
}
