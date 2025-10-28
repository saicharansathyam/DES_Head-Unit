import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property int volume: 50
    property color accentColor: "#3b82f6"
    property color secondaryColor: "#334155"

    signal volumeChangeRequested(int vol)

    Column {
        anchors.centerIn: parent
        spacing: 10
        width: parent.width * 0.9

        Row {
            width: parent.width
            spacing: 10

            Text {
                text: volume === 0 ? "🔇" : volume < 50 ? "🔉" : "🔊"
                color: "white"
                font.pixelSize: 20
                anchors.verticalCenter: parent.verticalCenter
            }

            Slider {
                id: volumeSlider
                width: parent.width - 70
                height: 22
                from: 0
                to: 100
                value: root.volume
                anchors.verticalCenter: parent.verticalCenter

                onValueChanged: {
                    root.volumeChangeRequested(Math.round(value))
                }

                background: Rectangle {
                    x: volumeSlider.leftPadding
                    y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                    width: volumeSlider.availableWidth
                    height: 5
                    radius: 2.5
                    color: secondaryColor

                    Rectangle {
                        width: volumeSlider.visualPosition * parent.width
                        height: parent.height
                        radius: 2.5
                        color: accentColor
                    }
                }

                handle: Rectangle {
                    x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                    y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                    width: 16
                    height: 16
                    radius: 8
                    color: volumeSlider.pressed ? Qt.lighter(accentColor, 1.2) : accentColor
                    border.color: "white"
                    border.width: 2
                }
            }

            Text {
                text: Math.round(root.volume) + "%"
                color: "white"
                font.pixelSize: 12
                font.bold: true
                width: 40
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
