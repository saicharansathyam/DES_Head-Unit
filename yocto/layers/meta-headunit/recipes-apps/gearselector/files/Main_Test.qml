import QtQuick
import QtQuick.Window

Window {
    id: root
    visible: true
    width: 800
    height: 480
    title: "GearSelector"
    color: "#1a1a1a"

    property string currentGear: "P"
    property int touchEvents: 0
    property int mouseEvents: 0

    Column {
        anchors.centerIn: parent
        spacing: 25

        // Title
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "🚗 TOUCH TEST"
            color: "white"
            font.pixelSize: 32
            font.bold: true
        }

        // Current gear display
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 200
            height: 100
            radius: 10
            color: "#2a2a2a"
            border.color: "#00ff00"
            border.width: 3

            Text {
                anchors.centerIn: parent
                text: root.currentGear
                color: "#00ff00"
                font.pixelSize: 64
                font.bold: true
            }
        }

        // Gear buttons
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 15

            Repeater {
                model: ["P", "R", "N", "D"]

                Rectangle {
                    id: gearButton
                    width: 140
                    height: 140
                    radius: 15
                    color: root.currentGear === modelData ? "#00ff00" : "#333333"
                    border.color: "#00ff00"
                    border.width: 3

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: root.currentGear === modelData ? "#000000" : "#00ff00"
                        font.pixelSize: 56
                        font.bold: true
                    }

                    // Touch input handler
                    MultiPointTouchArea {
                        anchors.fill: parent
                        
                        onPressed: function(touchPoints) {
                            console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                            console.log("🖐️ TOUCH PRESSED on:", modelData)
                            console.log("   Touch points:", touchPoints.length)
                            console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                            root.touchEvents++
                            gearButton.color = "#00aa00"
                        }
                        
                        onReleased: function(touchPoints) {
                            console.log("🖐️ TOUCH RELEASED on:", modelData)
                            root.currentGear = modelData
                            gearButton.color = root.currentGear === modelData ? "#00ff00" : "#333333"
                        }
                        
                        onUpdated: function(touchPoints) {
                            console.log("🖐️ TOUCH MOVED on:", modelData)
                        }
                    }

                    // Mouse input handler (fallback)
                    MouseArea {
                        anchors.fill: parent
                        
                        onPressed: {
                            console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                            console.log("🖱️ MOUSE PRESSED on:", modelData)
                            console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                            root.mouseEvents++
                            gearButton.color = "#00aa00"
                        }
                        
                        onReleased: {
                            console.log("🖱️ MOUSE RELEASED on:", modelData)
                            root.currentGear = modelData
                            gearButton.color = root.currentGear === modelData ? "#00ff00" : "#333333"
                        }
                    }
                }
            }
        }

        // Event counters
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 400
            height: 100
            radius: 10
            color: "#2a2a2a"

            Column {
                anchors.centerIn: parent
                spacing: 10

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "🖐️ Touch: " + root.touchEvents
                    color: root.touchEvents > 0 ? "#00ff00" : "#ff0000"
                    font.pixelSize: 24
                    font.bold: true
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "🖱️ Mouse: " + root.mouseEvents
                    color: root.mouseEvents > 0 ? "#00aaff" : "#666666"
                    font.pixelSize: 24
                    font.bold: true
                }
            }
        }

        // Status
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.touchEvents > 0 ? "✅ TOUCH WORKING!" : "⚠️ Touch not detected"
            color: root.touchEvents > 0 ? "#00ff00" : "#ffaa00"
            font.pixelSize: 18
            font.bold: true
        }
    }

    Component.onCompleted: {
        console.log("═══════════════════════════════════")
        console.log("🚗 GearSelector Started")
        console.log("═══════════════════════════════════")
        console.log("Window size:", width, "x", height)
        console.log("Platform:", Qt.platform.os)
        console.log("═══════════════════════════════════")
    }
}
