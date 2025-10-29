import QtQuick
import QtQuick.Window
import QtQuick.Controls

ApplicationWindow {
    visible: true
    width: 824
    height: 550
    title: "Theme Color Selector"

    Rectangle {
        anchors.fill: parent
        color: '#1e293b'

        Column {
            spacing: 20
            anchors.centerIn: parent

            Text {
                text: "Theme Color Selector"
                color: "white"
                font.pixelSize: 28
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // Color Wheel Component
            ColorWheel {
                id: colorWheel
                width: 400
                height: 400
                anchors.horizontalCenter: parent.horizontalCenter

                // Fixed: Use function with formal parameter
                onColorSelected: function(selectedColor) {
                    previewButton.updatePreviewColor(selectedColor)
                }
            }

            // Preview and Confirm Button
            PreviewButton {
                id: previewButton
                width: 150
                height: 150
                anchors.horizontalCenter: parent.horizontalCenter
                currentColor: ThemeColorClient.color

                onColorConfirmed: function(confirmedColor) {
                    ThemeColorClient.setColor(confirmedColor)
                }
            }
        }
    }

    // Listen for external color changes from DBus
    Connections {
        target: ThemeColorClient
        function onColorChanged() {
            previewButton.resetToCurrentColor()
        }
    }
}
