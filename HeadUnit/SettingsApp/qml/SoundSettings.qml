// SoundSettings.qml (color-related parts)
import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    color: "#0f172a"

    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        Text {
            text: "Sound"
            font.pixelSize: 22
            font.bold: true
            color: theme.themeColor
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        Text {
            text: "Master Volume"
            font.pixelSize: 16
            color: theme.accentColor
        }

        // Slider row
        Row {
            spacing: 12
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                text: "🔊"
                font.pixelSize: 22
                color: theme.themeColor
            }

            Slider {
                id: masterVolume
                width: 300
                from: 0
                to: 1

                background: Rectangle {
                    x: masterVolume.leftPadding
                    y: masterVolume.topPadding + masterVolume.availableHeight / 2 - height / 2
                    width: masterVolume.availableWidth
                    height: 6
                    radius: 3
                    color: "#334155"

                    Rectangle {
                        width: masterVolume.visualPosition * parent.width
                        height: parent.height
                        radius: 3
                        color: theme.themeColor
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }

                handle: Rectangle {
                    x: masterVolume.leftPadding + masterVolume.visualPosition * (masterVolume.availableWidth - width)
                    y: masterVolume.topPadding + masterVolume.availableHeight / 2 - height / 2
                    implicitWidth: 18
                    implicitHeight: 18
                    radius: 9
                    color: masterVolume.pressed ? theme.buttonPressedColor : theme.themeColor
                    border.color: theme.accentColor
                    border.width: 2
                }
            }

            Text {
                text: Math.round(masterVolume.value * 100) + "%"
                font.pixelSize: 14
                color: theme.accentColor
            }
        }
    }
}
