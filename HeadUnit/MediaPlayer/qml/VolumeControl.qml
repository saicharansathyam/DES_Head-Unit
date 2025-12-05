import QtQuick
import QtQuick.Controls

Row {
    id: volumeControl
    spacing: 15

    property real volume: 0.5

    Text {
        text: "🔊"
        font.pixelSize: 24
        color: theme.themeColor
        anchors.verticalCenter: parent.verticalCenter

        Behavior on color { ColorAnimation { duration: 300 } }
    }

    Slider {
        id: volumeSlider
        width: parent.width - 100
        from: 0
        to: 1
        value: volume
        anchors.verticalCenter: parent.verticalCenter

        background: Rectangle {
            x: volumeSlider.leftPadding
            y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
            implicitWidth: 200
            implicitHeight: 6
            width: volumeSlider.availableWidth
            height: implicitHeight
            radius: 3
            color: "#334155"

            Rectangle {
                width: volumeSlider.visualPosition * parent.width
                height: parent.height
                color: theme.themeColor
                radius: 3

                Behavior on color { ColorAnimation { duration: 300 } }
            }
        }

        handle: Rectangle {
            x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
            y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
            implicitWidth: 20
            implicitHeight: 20
            radius: 10
            color: volumeSlider.pressed ? theme.buttonPressedColor : theme.themeColor
            border.color: theme.accentColor
            border.width: 2

            Behavior on color { ColorAnimation { duration: 200 } }
        }

        onValueChanged: {
            volume = value
        }
    }

    Text {
        text: Math.round(volume * 100) + "%"
        font.pixelSize: 16
        color: theme.accentColor
        anchors.verticalCenter: parent.verticalCenter
        width: 50

        Behavior on color { ColorAnimation { duration: 300 } }
    }
}
