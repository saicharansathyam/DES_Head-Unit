import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import GearSelector 1.0

ApplicationWindow {
    id: root
    width: 200
    height: 600
    visible: true
    title: "GearSelector"
    
    // Create the gear handler instance
    GearHandler {
        id: gearHandler
        
        onCurrentGearChanged: {
            console.log("Gear changed to:", currentGear)
        }
        
        onSpeedChanged: function(speed) {
            // Speed is in cm/s, convert to km/h for display
            var kmh = (speed / 100.0) * 3.6
            speedDisplay.text = kmh.toFixed(1)
        }
        
        onBatteryChanged: function(battery) {
            batteryBar.value = battery
        }
        
        onDbusConnectionError: function(error) {
            console.error("D-Bus error:", error)
            statusText.text = "Disconnected"
            statusIndicator.color = "#ef4444"
        }
        
        onDbusConnectionRestored: {
            console.log("D-Bus connection restored")
            statusText.text = "Connected"
            statusIndicator.color = "#10b981"
        }
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1a1f2e" }
            GradientStop { position: 1.0; color: "#111827" }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 10

            // Title
            Label {
                Layout.fillWidth: true
                text: "PIRACER CONTROL"
                font.pixelSize: 16
                font.bold: true
                font.letterSpacing: 2
                color: "#9ca3af"
                horizontalAlignment: Text.AlignHCenter
            }
            
            // Speed Display
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                color: "#1f2937"
                radius: 8
                border.color: "#374151"
                
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 2
                    
                    Label {
                        text: "SPEED"
                        font.pixelSize: 9
                        font.letterSpacing: 1
                        color: "#6b7280"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    
                    RowLayout {
                        spacing: 4
                        Layout.alignment: Qt.AlignHCenter
                        
                        Label {
                            id: speedDisplay
                            text: "0.0"
                            font.pixelSize: 28
                            font.bold: true
                            color: {
                                var speed = parseFloat(text)
                                if (speed > 20) return "#ef4444"  // Red for high speed
                                if (speed > 10) return "#fbbf24"  // Yellow for medium
                                if (speed > 0) return "#10b981"   // Green for low
                                return "#6b7280"                  // Gray for zero
                            }
                        }
                        
                        Label {
                            text: "km/h"
                            font.pixelSize: 12
                            color: "#6b7280"
                        }
                    }
                }
            }
            
            // Battery Display
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 45
                color: "#1f2937"
                radius: 8
                border.color: "#374151"
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4
                    
                    Label {
                        text: "BATTERY"
                        font.pixelSize: 9
                        font.letterSpacing: 1
                        color: "#6b7280"
                    }
                    
                    ProgressBar {
                        id: batteryBar
                        Layout.fillWidth: true
                        from: 0
                        to: 100
                        value: gearHandler.batteryLevel
                        
                        background: Rectangle {
                            implicitHeight: 12
                            radius: 4
                            color: "#374151"
                        }
                        
                        contentItem: Item {
                            implicitHeight: 12
                            
                            Rectangle {
                                width: batteryBar.visualPosition * parent.width
                                height: parent.height
                                radius: 4
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { 
                                        position: 0.0
                                        color: batteryBar.value > 50 ? "#10b981" : 
                                               batteryBar.value > 20 ? "#fbbf24" : "#ef4444"
                                    }
                                    GradientStop { 
                                        position: 1.0
                                        color: batteryBar.value > 50 ? "#059669" : 
                                               batteryBar.value > 20 ? "#f59e0b" : "#dc2626"
                                    }
                                }
                            }
                            
                            Label {
                                anchors.centerIn: parent
                                text: batteryBar.value.toFixed(0) + "%"
                                font.pixelSize: 9
                                font.bold: true
                                color: "white"
                            }
                        }
                    }
                }
            }
            
            // Current gear display
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                color: "#374151"
                radius: 10
                border.color: "#4b5563"
                border.width: 1
                
                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    
                    Label {
                        text: "CURRENT GEAR"
                        font.pixelSize: 10
                        font.letterSpacing: 1
                        color: "#9ca3af"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    
                    Label {
                        text: gearHandler.currentGear
                        font.pixelSize: 32
                        font.bold: true
                        color: {
                            switch(gearHandler.currentGear) {
                                case "P": return "#60a5fa"  // Blue for Park
                                case "R": return "#f87171"  // Red for Reverse
                                case "N": return "#9ca3af"  // Gray for Neutral
                                case "D": return "#34d399"  // Green for Drive
                                default: return "#ffffff"
                            }
                        }
                        anchors.horizontalCenter: parent.horizontalCenter
                        
                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }
                    }
                }
            }

            // Separator
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#374151"
            }

            // Gear buttons
            Column {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                Repeater {
                    model: [
                        {gear: "P", label: "Park", color: "#1e40af"},
                        {gear: "R", label: "Reverse", color: "#991b1b"},
                        {gear: "N", label: "Neutral", color: "#374151"},
                        {gear: "D", label: "Drive", color: "#166534"}
                    ]

                    delegate: Button {
                        property bool isSelected: gearHandler.currentGear === modelData.gear
                        
                        width: parent.width
                        height: 48
                        enabled: gearHandler.isConnected
                        opacity: enabled ? 1.0 : 0.5
                        
                        background: Rectangle {
                            color: parent.isSelected ? modelData.color : "#1f2937"
                            radius: 6
                            border.color: parent.isSelected ? Qt.lighter(modelData.color, 1.5) : "#374151"
                            border.width: parent.hovered ? 2 : 1
                            
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }
                        
                        contentItem: Row {
                            spacing: 10
                            anchors.centerIn: parent
                            
                            Label {
                                text: modelData.gear
                                font.pixelSize: 20
                                font.bold: true
                                color: parent.parent.isSelected ? "#ffffff" : "#9ca3af"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            
                            Label {
                                text: modelData.label
                                font.pixelSize: 12
                                color: parent.parent.isSelected ? "#e5e7eb" : "#6b7280"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        onClicked: {
                            gearHandler.currentGear = modelData.gear
                            // Visual feedback
                            background.scale = 0.95
                            scaleAnimation.start()
                        }
                        
                        NumberAnimation {
                            id: scaleAnimation
                            target: background
                            property: "scale"
                            to: 1.0
                            duration: 100
                            easing.type: Easing.OutQuad
                        }
                    }
                }
            }
            
            // Status bar
            Rectangle {
                Layout.fillWidth: true
                height: 24
                color: "#1f2937"
                radius: 4
                
                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    
                    Rectangle {
                        id: statusIndicator
                        width: 6
                        height: 6
                        radius: 3
                        color: gearHandler.isConnected ? "#10b981" : "#ef4444"
                        anchors.verticalCenter: parent.verticalCenter
                        
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: true
                            NumberAnimation { to: 0.3; duration: 1000 }
                            NumberAnimation { to: 1.0; duration: 1000 }
                        }
                    }
                    
                    Label {
                        id: statusText
                        text: gearHandler.isConnected ? "Connected" : "Disconnected"
                        font.pixelSize: 10
                        color: "#9ca3af"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}