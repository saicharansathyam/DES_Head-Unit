import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    width: 1000; height: 400
    color: "#222"

    Column {
        id: rootColumn
        anchors.centerIn: parent
        spacing: 30

        property var ambientController: AmbientController

        Button { text: "Red";   onClicked: rootColumn.ambientController.setRed() }
        Button { text: "Green"; onClicked: rootColumn.ambientController.setGreen() }
        Button { text: "Blue";  onClicked: rootColumn.ambientController.setBlue() }

        Text {
            text: "Current Color: " + rootColumn.ambientController.currentColor
            color: "white"
            font.pixelSize: 24
        }
    }
}
