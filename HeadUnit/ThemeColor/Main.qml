import QtQuick
import QtQuick.Window
import QtQuick.Controls

ApplicationWindow {
    visible: true
    width: 824
    height: 470  // Match compositor app height
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

                onColorSelected: function(selectedColor) {
                    console.log("Color selected from wheel:", selectedColor)
                    previewButton.updatePreviewColor(selectedColor)
                }
            }

            // Preview and Confirm Button
            PreviewButton {
                id: previewButton
                width: 150
                height: 150
                anchors.horizontalCenter: parent.horizontalCenter
                currentColor: themeClient.color  // Fixed: lowercase themeClient

                onColorConfirmed: function(confirmedColor) {
                    console.log("Color confirmed, sending to D-Bus:", confirmedColor)
                    themeClient.setColor(confirmedColor)  // Fixed: lowercase themeClient
                }
            }
        }
    }

    // Listen for external color changes from DBus
    Connections {
        target: themeClient  // Fixed: lowercase themeClient
        function onColorChanged() {
            console.log("Color changed from D-Bus:", themeClient.color)
            previewButton.resetToCurrentColor()
        }
    }

    Component.onCompleted: {
        console.log("ThemeColor app started")
        console.log("Initial color:", themeClient.color)
    }
}
