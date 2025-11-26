// MenuButton.qml
import QtQuick
import QtQuick.Controls

Button {
    id: root

    property string textLabel: ""
    property string iconText: ""
    property bool selected: false

    width: parent ? parent.width : 200
    height: 56

    background: Rectangle {
        anchors.fill: parent
        color: {
            if (root.pressed) return theme.buttonPressedColor
            if (root.hovered || root.selected) return theme.themeColor
            return "transparent"
        }
        radius: 0
        border.width: root.selected ? 2 : 0
        border.color: theme.accentColor

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
    }

    contentItem: Row {
        anchors.fill: parent
        anchors.leftMargin: 20
        spacing: 12

        Text {
            text: root.iconText
            font.pixelSize: 22
            verticalAlignment: Text.AlignVCenter
            color: root.selected ? "white" : "#94a3b8"
        }

        Text {
            text: root.textLabel
            font.pixelSize: 16
            font.bold: root.selected
            verticalAlignment: Text.AlignVCenter
            color: root.selected ? "white" : "#94a3b8"

            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }
}
