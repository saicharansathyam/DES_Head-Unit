import QtQuick
import QtQuick.Controls

Rectangle {
    id: soundSettings
    color: "transparent"

    Column {
        anchors.fill: parent
        spacing: 20

        // Header
        Text {
            text: "Sound Settings"
            color: "#00ff00"
            font.pixelSize: 24
            font.bold: true
        }

        // System volume
        Rectangle {
            width: parent.width
            height: 200
            color: "#2a2a2a"
            radius: 8

            Column {
                anchors.centerIn: parent
                spacing: 20
                width: parent.width - 60

                Text {
                    text: "System Volume"
                    color: "#ffffff"
                    font.pixelSize: 18
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                // Volume icon and value
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 15

                    Text {
                        text: settingsManager.systemVolume === 0 ? "🔇" :
                              settingsManager.systemVolume < 50 ? "🔉" : "🔊"
                        font.pixelSize: 40
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: settingsManager.systemVolume + "%"
                        color: "#00ff00"
                        font.pixelSize: 48
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Volume slider
                Slider {
                    id: volumeSlider
                    width: parent.width
                    from: 0
                    to: 100
                    value: settingsManager.systemVolume
                    stepSize: 1

                    onValueChanged: {
                        settingsManager.setSystemVolume(value)
                    }

                    background: Rectangle {
                        x: volumeSlider.leftPadding
                        y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        implicitHeight: 8
                        width: volumeSlider.availableWidth
                        height: implicitHeight
                        radius: 4
                        color: "#404040"

                        Rectangle {
                            width: volumeSlider.visualPosition * parent.width
                            height: parent.height
                            color: "#00aa00"
                            radius: 4
                        }
                    }

                    handle: Rectangle {
                        x: volumeSlider.leftPadding + volumeSlider.visualPosition *
                           (volumeSlider.availableWidth - width)
                        y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                        implicitWidth: 26
                        implicitHeight: 26
                        radius: 13
                        color: volumeSlider.pressed ? "#00ff00" : "#ffffff"
                        border.color: "#00aa00"
                        border.width: 2
                    }
                }
            }
        }

        // Quick volume buttons
        Text {
            text: "Quick Controls"
            color: "#ffffff"
            font.pixelSize: 16
            font.bold: true
        }

        Rectangle {
            width: parent.width
            height: 120
            color: "#2a2a2a"
            radius: 8

            Row {
                anchors.centerIn: parent
                spacing: 20

                Button {
                    text: "Mute"
                    width: 100
                    height: 50

                    background: Rectangle {
                        color: parent.pressed ? "#803030" : "#ff4444"
                        radius: 5
                    }

                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: settingsManager.setSystemVolume(0)
                }

                Button {
                    text: "50%"
                    width: 100
                    height: 50

                    background: Rectangle {
                        color: parent.pressed ? "#505050" : "#404040"
                        radius: 5
                    }

                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: settingsManager.setSystemVolume(50)
                }

                Button {
                    text: "75%"
                    width: 100
                    height: 50

                    background: Rectangle {
                        color: parent.pressed ? "#505050" : "#404040"
                        radius: 5
                    }

                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: settingsManager.setSystemVolume(75)
                }

                Button {
                    text: "Max"
                    width: 100
                    height: 50

                    background: Rectangle {
                        color: parent.pressed ? "#305030" : "#00aa00"
                        radius: 5
                    }

                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: settingsManager.setSystemVolume(100)
                }
            }
        }

        // Audio info
        Rectangle {
            width: parent.width
            height: 100
            color: "#2a2a2a"
            radius: 8

            Column {
                anchors.centerIn: parent
                spacing: 10

                Text {
                    text: "Audio Output Information"
                    color: "#888888"
                    font.pixelSize: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "Current output: Default"
                    color: "#ffffff"
                    font.pixelSize: 13
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "Sample rate: 48000 Hz"
                    color: "#ffffff"
                    font.pixelSize: 13
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}
