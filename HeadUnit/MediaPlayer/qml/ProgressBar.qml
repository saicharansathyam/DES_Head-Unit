import QtQuick
import QtQuick.Controls

Item {
    id: root
    height: 60

    property real position: 0
    property real duration: 1
    property color accentColor: "#3b82f6"
    property color secondaryColor: "#334155"

    signal seekRequested(real position)

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

    Column {
        anchors.fill: parent
        spacing: 8

        // Slider
        Slider {
            id: seekSlider
            width: parent.width
            height: 30
            from: 0
            to: root.duration > 0 ? root.duration : 1
            value: root.position
            enabled: root.duration > 0

            onMoved: {
                root.seekRequested(value)
            }

            background: Rectangle {
                x: seekSlider.leftPadding
                y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                width: seekSlider.availableWidth
                height: 8
                radius: 4
                color: secondaryColor

                Rectangle {
                    width: seekSlider.visualPosition * parent.width
                    height: parent.height
                    radius: 4
                    color: accentColor
                }
            }

            handle: Rectangle {
                x: seekSlider.leftPadding + seekSlider.visualPosition * (seekSlider.availableWidth - width)
                y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                width: 24
                height: 24
                radius: 12
                color: seekSlider.pressed ? Qt.lighter(accentColor, 1.3) : accentColor
                border.color: "white"
                border.width: 2

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }
        }

        // Time labels
        Row {
            width: parent.width

            Label {
                text: formatTime(root.position)
                color: "white"
                font.pixelSize: 14
                font.bold: true
            }

            Item {
                width: parent.width - 120
                height: 1
            }

            Label {
                text: formatTime(root.duration)
                color: "white"
                font.pixelSize: 14
                font.bold: true
            }
        }
    }
}
