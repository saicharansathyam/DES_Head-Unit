import QtQuick
import QtQuick.Controls

Rectangle {
    id: button
    width: parent.width
    height: 50
    color: isActive ? "#404040" : "transparent"
    radius: 5

    property string text: ""
    property string icon: ""
    property bool isActive: false

    signal clicked()

    Row {
        anchors.centerIn: parent
        spacing: 10

        Text {
            text: icon
            font.pixelSize: 20
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: button.text
            color: isActive ? "#00ff00" : "#ffffff"
            font.pixelSize: 14
            font.bold: isActive
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()

        onPressed: button.color = "#505050"
        onReleased: button.color = isActive ? "#404040" : "transparent"
    }
}

