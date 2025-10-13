import QtQuick
import QtQuick.Window
import QtQuick.Controls

ApplicationWindow {
    visible: true
    width: 400
    height: 350
    title: "Theme Color Changer - RGB Sliders"

    Rectangle {
        anchors.fill: parent
        color: '#1e293b'

        Column {
            spacing: 15
            anchors.centerIn: parent
            width: parent.width * 0.8

            Text {
                text: "Current Theme Color: " + ThemeColorClient.color
                color: ThemeColorClient.color
                font.pixelSize: 20
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }

            // Red slider
            Row {
                spacing: 10
                Label {
                    text: "Red:"
                    color: "white"
                }
                Slider {
                    id: redSlider
                    from: 0; to: 255
                    value: parseInt(ThemeColorClient.color.substr(1, 2), 16)
                    onValueChanged: updateColor()
                }
                Text {
                    text: redSlider.value.toFixed(0)
                    width: 30
                    horizontalAlignment: Text.AlignRight
                }
            }

            // Green slider
            Row {
                spacing: 10
                Label {
                    text: "Green:"
                    color: "white"
                }
                Slider {
                    id: greenSlider
                    from: 0; to: 255
                    value: parseInt(ThemeColorClient.color.substr(3, 2), 16)
                    onValueChanged: updateColor()
                }
                Text {
                    text: greenSlider.value.toFixed(0)
                    width: 30
                    horizontalAlignment: Text.AlignRight
                }
            }

            // Blue slider
            Row {
                spacing: 10
                Label {
                    text: "Blue:"
                    color: "white"
                }
                Slider {
                    id: blueSlider
                    from: 0; to: 255
                    value: parseInt(ThemeColorClient.color.substr(5, 2), 16)
                    onValueChanged: updateColor()
                }
                Text {
                    text: blueSlider.value.toFixed(0)
                    width: 30
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }

    function toHex(value) {
        var hex = Math.floor(value).toString(16)
        return hex.length === 1 ? "0" + hex : hex
    }

    function updateColor() {
        var newColor = "#" + toHex(redSlider.value) + toHex(greenSlider.value) + toHex(blueSlider.value)
        if (ThemeColorClient.color !== newColor) {
            ThemeColorClient.setColor(newColor)
        }
    }

    Connections {
        target: ThemeColorClient
        onColorChanged: {
            // Update sliders on external color change
            redSlider.value = parseInt(ThemeColorClient.color.substr(1, 2), 16)
            greenSlider.value = parseInt(ThemeColorClient.color.substr(3, 2), 16)
            blueSlider.value = parseInt(ThemeColorClient.color.substr(5, 2), 16)
        }
    }
}

