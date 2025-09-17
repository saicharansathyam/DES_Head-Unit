import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id:root
    width: 200; height: 600
    color: "#222"

    Column {
        id: rootColumn
        anchors.centerIn: parent
        spacing: 60

        Repeater {
            model: ["P", "R", "N", "D"]

            delegate: Button {
                text: modelData
                font.pixelSize: 50
                palette.buttonText: "white"
                onClicked: gControl.setGear(modelData)
            }
        }
    }
}
