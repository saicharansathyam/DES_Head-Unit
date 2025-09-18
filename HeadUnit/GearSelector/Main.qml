// GearSelector.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import GearSelector 1.0

Window {
    id: root
    width: 48
    height: 600
    color: "#111827"
    visible: true
    title: "Gear Selector"

    GearHandler {
        id: gearHandler
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 40
        spacing: 100

        // Gear buttons
        Column {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            Repeater {
                model: ["P", "R", "N", "D", "S"]

                delegate: Button {
                    text: modelData
                    font.pixelSize: 24
                    font.bold: true
                    width: parent.width
                    height: 60
                    palette.buttonText: "white"
                    
                    background: Rectangle {
                        color: gearHandler.currentGear === modelData ? "#374151" : "#111827"
                        radius: 6
                    }

                    onClicked: gearHandler.currentGear = modelData
                }
            }
        }
    }
}

