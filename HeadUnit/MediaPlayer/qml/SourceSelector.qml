import QtQuick
import QtQuick.Controls

Row {
    id: sourceSelector
    spacing: 10

    property string currentSource: "USB"
    signal sourceChanged(string source)

    Repeater {
        model: ["USB", "Bluetooth", "YouTube"]

        Button {
            width: 150
            height: 50

            background: Rectangle {
                color: {
                    if (parent.pressed) return theme.buttonPressedColor
                    if (parent.hovered) return theme.buttonHoverColor
                    if (modelData === currentSource) return theme.themeColor
                    return "#1e293b"
                }
                radius: 8
                border.width: modelData === currentSource ? 2 : 1
                border.color: modelData === currentSource ? theme.accentColor : "#334155"

                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on border.color { ColorAnimation { duration: 200 } }
            }

            contentItem: Row {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: {
                        if (modelData === "USB") return "💾"
                        if (modelData === "Bluetooth") return "📡"
                        if (modelData === "YouTube") return "▶"
                        return ""
                    }
                    font.pixelSize: 20
                    color: "white"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: modelData
                    color: "white"
                    font.pixelSize: 14
                    font.bold: modelData === currentSource
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            onClicked: {
                currentSource = modelData
                sourceChanged(modelData)
            }
        }
    }
}
