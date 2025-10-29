import QtQuick
import QtQuick.Controls

Item {
    id: root
    width: 350
    height: 80

    property bool isPlaying: false
    property color accentColor: "#3b82f6"
    property color secondaryColor: "#334155"

    signal playClicked()
    signal pauseClicked()
    signal stopClicked()
    signal previousClicked()
    signal nextClicked()

    Row {
        anchors.centerIn: parent
        spacing: 15

        // Previous button
        Rectangle {
            width: 55
            height: 55
            radius: 27.5
            color: prevButton.pressed ? Qt.darker(secondaryColor, 1.3) :
                   prevButton.containsMouse ? Qt.lighter(secondaryColor, 1.2) : secondaryColor
            border.color: prevButton.containsMouse ? accentColor : "transparent"
            border.width: 2

            Behavior on color { ColorAnimation { duration: 150 } }

            MouseArea {
                id: prevButton
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.previousClicked()
            }

            Text {
                anchors.centerIn: parent
                text: "⏮"
                color: "white"
                font.pixelSize: 22
            }
        }

        // Stop button
        Rectangle {
            width: 55
            height: 55
            radius: 27.5
            color: stopButton.pressed ? Qt.darker(secondaryColor, 1.3) :
                   stopButton.containsMouse ? Qt.lighter(secondaryColor, 1.2) : secondaryColor
            border.color: stopButton.containsMouse ? accentColor : "transparent"
            border.width: 2

            Behavior on color { ColorAnimation { duration: 150 } }

            MouseArea {
                id: stopButton
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.stopClicked()
            }

            Text {
                anchors.centerIn: parent
                text: "⏹"
                color: "white"
                font.pixelSize: 22
            }
        }

        // Play/Pause button (larger)
        Rectangle {
            width: 70
            height: 70
            radius: 35
            color: playButton.pressed ? Qt.darker(accentColor, 1.2) :
                   playButton.containsMouse ? Qt.lighter(accentColor, 1.1) : accentColor

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on scale { NumberAnimation { duration: 100 } }

            scale: playButton.pressed ? 0.95 : 1.0

            MouseArea {
                id: playButton
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (root.isPlaying) {
                        root.pauseClicked()
                    } else {
                        root.playClicked()
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: root.isPlaying ? "⏸" : "▶"
                color: "white"
                font.pixelSize: 28
            }
        }

        // Next button
        Rectangle {
            width: 55
            height: 55
            radius: 27.5
            color: nextButton.pressed ? Qt.darker(secondaryColor, 1.3) :
                   nextButton.containsMouse ? Qt.lighter(secondaryColor, 1.2) : secondaryColor
            border.color: nextButton.containsMouse ? accentColor : "transparent"
            border.width: 2

            Behavior on color { ColorAnimation { duration: 150 } }

            MouseArea {
                id: nextButton
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.nextClicked()
            }

            Text {
                anchors.centerIn: parent
                text: "⏭"
                color: "white"
                font.pixelSize: 22
            }
        }
    }
}
