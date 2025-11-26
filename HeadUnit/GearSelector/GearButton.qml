import QtQuick
import QtQuick.Controls

Button {
    id: gearButton

    property string gear: ""
    property string label: ""
    property bool isActive: false

    width: 55
    height: 70

    background: Rectangle {
        color: {
            if (gearButton.pressed) return theme.buttonPressedColor
            if (isActive) return theme.themeColor
            if (gearButton.hovered) return theme.buttonHoverColor
            return "#2d2d2d"
        }
        radius: 8
        border.width: isActive ? 2 : 1
        border.color: isActive ? theme.accentColor : "#404040"

        Behavior on color {
            ColorAnimation { duration: 200 }
        }

        Behavior on border.color {
            ColorAnimation { duration: 200 }
        }
    }

    contentItem: Column {
        anchors.centerIn: parent
        spacing: 3

        Text {
            text: gear
            color: isActive ? "#ffffff" : "#aaaaaa"
            font.pixelSize: 28
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter

            Behavior on color {
                ColorAnimation { duration: 200 }
            }
        }

        Text {
            text: label
            color: isActive ? "#ffffff" : "#777777"
            font.pixelSize: 9
            anchors.horizontalCenter: parent.horizontalCenter

            Behavior on color {
                ColorAnimation { duration: 200 }
            }
        }
    }
}

