import QtQuick

Window {
    visible: true
    width: 800
    height: 480
    title: "GearSelector"
    color: "#1a1a1a"
    
    Column {
        anchors.centerIn: parent
        spacing: 30

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "🔧 MINIMAL TEST - GearSelector"
            color: "white"
            font.pixelSize: 32
            font.bold: true
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Current Gear: " + gsHandler.currentGear
            color: "#00ff00"
            font.pixelSize: 48
            font.bold: true
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 20

            Repeater {
                model: ["P", "R", "N", "D"]
                
                Rectangle {
                    width: 120
                    height: 120
                    color: gsHandler.currentGear === modelData ? "#00ff00" : "#333333"
                    border.color: "#666666"
                    border.width: 2
                    radius: 10
                    
                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: 48
                        font.bold: true
                        color: gsHandler.currentGear === modelData ? "#000000" : "#ffffff"
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            console.log("🎯 CLICKED:", modelData)
                            // FIX: Use property assignment instead of function call
                            gsHandler.currentGear = modelData
                        }
                    }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Speed: " + gsHandler.currentSpeed.toFixed(1) + " cm/s"
            color: "#00aaff"
            font.pixelSize: 24
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Battery: " + gsHandler.batteryLevel.toFixed(1) + "%"
            color: "#ffaa00"
            font.pixelSize: 24
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: gsHandler.isConnected ? "✓ DBus Connected" : "✗ DBus Disconnected"
            color: gsHandler.isConnected ? "#00ff00" : "#ff0000"
            font.pixelSize: 18
        }
    }

    Component.onCompleted: {
        console.log("=== Minimal GearSelector Test Started ===")
        console.log("Initial gear:", gsHandler.currentGear)
    }
}