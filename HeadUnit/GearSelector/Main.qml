import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import GearSelector 1.0

Item {
    id: root
    width: 200
    height: 600
    visible: true

    Rectangle {
        anchors.fill: parent
        color: "#111827"

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
                            color: GearHandler.currentGear === modelData ? "#374151" : "#111827"
                            radius: 6
                        }

                        onClicked: GearHandler.currentGear = modelData
                    }
                }
            }
        }
    }
}
