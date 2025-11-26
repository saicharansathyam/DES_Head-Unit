import QtQuick
import QtQuick.Controls

Item {
    id: root
    implicitHeight: 50

    Column {
        anchors.fill: parent
        spacing: 6

        // Progress Slider
        Slider {
            id: progressSlider
            width: parent.width
            height: 32
            from: 0
            to: 1
            value: mpHandler.duration > 0 ? mpHandler.currentPosition / mpHandler.duration : 0

            background: Rectangle {
                x: progressSlider.leftPadding
                y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                implicitWidth: 200
                implicitHeight: 10
                width: progressSlider.availableWidth
                height: 10
                radius: 5
                color: "#334155"

                Rectangle {
                    width: progressSlider.visualPosition * parent.width
                    height: parent.height
                    color: theme.themeColor
                    radius: 5

                    Behavior on color { ColorAnimation { duration: 300 } }
                }
            }

            handle: Rectangle {
                x: progressSlider.leftPadding + progressSlider.visualPosition * (progressSlider.availableWidth - width)
                y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                implicitWidth: 22
                implicitHeight: 22
                radius: 11
                color: progressSlider.pressed ? theme.buttonPressedColor : "white"
                border.color: theme.themeColor
                border.width: 3

                Behavior on color { ColorAnimation { duration: 200 } }
            }

            onMoved: {
                if (mpHandler.duration > 0) {
                    mpHandler.seek(value * mpHandler.duration)
                }
            }
        }

        // Time Labels
        Row {
            width: parent.width
            spacing: 10

            Text {
                text: formatTime(mpHandler.currentPosition)
                color: theme.accentColor
                font.pixelSize: 12

                Behavior on color { ColorAnimation { duration: 300 } }
            }

            Item {
                width: parent.width - 100
            }

            Text {
                text: formatTime(mpHandler.duration)
                color: "#94a3b8"
                font.pixelSize: 12
            }
        }
    }

    function formatTime(milliseconds) {
        var seconds = Math.floor(milliseconds / 1000)
        var minutes = Math.floor(seconds / 60)
        seconds = seconds % 60
        return minutes + ":" + (seconds < 10 ? "0" : "") + seconds
    }
}
