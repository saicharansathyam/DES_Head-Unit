import QtQuick
import QtQuick.Controls

Window {
    id: root
    visible: true
    width: 800
    height: 480
    title: "MediaPlayer"
    color: "#2a2a2a"
    
    focus: true

    Column {
        anchors.centerIn: parent
        spacing: 40

        Text {
            text: mpHandler.playing ? "▶ PLAYING" : "⏸ PAUSED"
            color: mpHandler.playing ? "#00ff00" : "#ffaa00"
            font.pixelSize: 36
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Row {
            spacing: 30
            anchors.horizontalCenter: parent.horizontalCenter

            // Play Button
            Rectangle {
                width: 100
                height: 100
                radius: 50
                color: playMouseArea.pressed ? "#00cc00" : "#009900"
                border.color: "white"
                border.width: 2

                Text {
                    anchors.centerIn: parent
                    text: "▶"
                    color: "white"
                    font.pixelSize: 40
                }

                MouseArea {
                    id: playMouseArea
                    anchors.fill: parent
                    onClicked: {
                        console.log("PLAY clicked")
                        if (typeof mpHandler !== 'undefined') {
                            mpHandler.play()
                        }
                    }
                }
            }

            // Pause Button
            Rectangle {
                width: 100
                height: 100
                radius: 50
                color: pauseMouseArea.pressed ? "#cc9900" : "#997700"
                border.color: "white"
                border.width: 2

                Text {
                    anchors.centerIn: parent
                    text: "⏸"
                    color: "white"
                    font.pixelSize: 40
                }

                MouseArea {
                    id: pauseMouseArea
                    anchors.fill: parent
                    onClicked: {
                        console.log("PAUSE clicked")
                        if (typeof mpHandler !== 'undefined') {
                            mpHandler.pause()
                        }
                    }
                }
            }

            // Stop Button
            Rectangle {
                width: 100
                height: 100
                radius: 50
                color: stopMouseArea.pressed ? "#cc0000" : "#990000"
                border.color: "white"
                border.width: 2

                Text {
                    anchors.centerIn: parent
                    text: "⏹"
                    color: "white"
                    font.pixelSize: 40
                }

                MouseArea {
                    id: stopMouseArea
                    anchors.fill: parent
                    onClicked: {
                        console.log("STOP clicked")
                        if (typeof mpHandler !== 'undefined') {
                            mpHandler.stop()
                        }
                    }
                }
            }
        }

        // Volume Slider (this already works)
        Row {
            spacing: 20
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                text: "Volume:"
                color: "white"
                font.pixelSize: 20
                anchors.verticalCenter: parent.verticalCenter
            }

            Slider {
                id: volumeSlider
                width: 300
                from: 0
                to: 100
                value: typeof mpHandler !== 'undefined' ? mpHandler.volume : 50
                onValueChanged: {
                    if (typeof mpHandler !== 'undefined') {
                        mpHandler.setVolume(value)
                    }
                }
            }

            Text {
                text: volumeSlider.value.toFixed(0)
                color: "white"
                font.pixelSize: 20
                width: 40
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}