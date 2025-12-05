import QtQuick
import QtQuick.Controls

Rectangle {
    id: mediaDisplay
    color: "#1e293b"
    radius: 12
    border.width: 1
    border.color: "#334155"

    Column {
        anchors.centerIn: parent
        spacing: 15

        // Album Art or Icon
        Rectangle {
            width: 120
            height: 120
            radius: 10
            color: theme.themeColor
            anchors.horizontalCenter: parent.horizontalCenter

            Behavior on color { ColorAnimation { duration: 300 } }

            Text {
                anchors.centerIn: parent
                text: "♫"
                font.pixelSize: 60
                color: "white"
            }
        }

        // Track Info
        Column {
            spacing: 5
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                text: mpHandler.currentTrack || "No Track Playing"
                color: "white"
                font.pixelSize: 18
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: mpHandler.currentArtist || "Unknown Artist"
                color: theme.accentColor
                font.pixelSize: 14
                anchors.horizontalCenter: parent.horizontalCenter

                Behavior on color { ColorAnimation { duration: 300 } }
            }
        }
    }
}
