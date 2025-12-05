import QtQuick

Rectangle {
    id: keyButton
    width: 35
    height: 40
    radius: 4
    color: backgroundColor
    border.width: 1
    border.color: "#444444"

    property string label: "A"
    property color backgroundColor: "#555555"
    signal keyClicked()

    Text {
        anchors.centerIn: parent
        text: keyButton.label
        font.pixelSize: 12
        font.bold: true
        color: "#ffffff"
    }

    MouseArea {
        anchors.fill: parent
        onPressed: keyButton.color = Qt.darker(keyButton.backgroundColor, 1.2);
        onReleased: keyButton.color = keyButton.backgroundColor;
        onClicked: keyButton.keyClicked();
    }
}
