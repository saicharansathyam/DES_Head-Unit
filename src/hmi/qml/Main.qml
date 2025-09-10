import QtQuick
import QtQuick.Controls

Window {

    visible: true
    width: 1280
    height: 720
    title: qsTr("DES Head Unit")

    Rectangle {
        anchors.fill: parent
        color: "#1e1e1e"

        Text {
            text: "Welcome to DES Head Unit"
            anchors.centerIn: parent
            font.pixelSize: 32
            color: "white"
        }
    }
}
