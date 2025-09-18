// GearSelector.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: root
    width: 48
    height:600
    color: "#111827"   // bg-gray-900

    property string selectedGear: "P"

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
                        color: "#111827"
                    }

                    onClicked: root.selectedGear = modelData
                }
            }
        }
    }
}

