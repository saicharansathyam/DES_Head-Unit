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
        onDbusConnectionError: function(error) {
            console.error("D-Bus error:", error)
            errorText.text = error
            errorText.visible = true
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
            anchors.margins: 20
            spacing: 15

            // Title
            Label {
                Layout.fillWidth: true
                text: "GEAR SELECTOR"
                font.pixelSize: 18
                font.bold: true
                font.letterSpacing: 2
                color: "#9ca3af"
                horizontalAlignment: Text.AlignHCenter
            }
            
            // Current gear display
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                color: "#374151"
                radius: 10
                border.color: "#4b5563"
                border.width: 1
                
                Column {
                    anchors.centerIn: parent
                    spacing: 5
                    
                    Label {
                        text: "CURRENT"
                        font.pixelSize: 10
                        font.letterSpacing: 1
                        color: "#9ca3af"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    
                    Label {
                        text: gearHandler.currentGear
                        font.pixelSize: 36
                        font.bold: true
                        color: {
                            switch(gearHandler.currentGear) {
                                case "P": return "#60a5fa"  // Blue for Park
                                case "R": return "#f87171"  // Red for Reverse
                                case "N": return "#9ca3af"  // Gray for Neutral
                                case "D": return "#34d399"  // Green for Drive
                                case "S": return "#fbbf24"  // Yellow for Sport
                                case "L": return "#fb923c"  // Orange for Low
                                case "M": return "#c084fc"  // Purple for Manual
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
                spacing: 10

                Repeater {
                    model: [
                        {gear: "P", label: "Park", color: "#1e40af"},
                        {gear: "R", label: "Reverse", color: "#991b1b"},
                        {gear: "N", label: "Neutral", color: "#374151"},
                        {gear: "D", label: "Drive", color: "#166534"},
                        {gear: "S", label: "Sport", color: "#92400e"},
                        {gear: "L", label: "Low", color: "#9a3412"},
                        {gear: "M", label: "Manual", color: "#6b21a8"}
                    ]

                    delegate: Button {
                        property bool isSelected: gearHandler.currentGear === modelData.gear
                        
                        width: parent.width
                        height: 60
                        
                        background: Rectangle {
                            color: parent.isSelected ? modelData.color : "#1f2937"
                            radius: 8
                            border.color: parent.isSelected ? Qt.lighter(modelData.color, 1.5) : "#374151"
                            border.width: parent.hovered ? 2 : 1
                            
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                            
                            Behavior on border.color {
                                ColorAnimation { duration: 150 }
                            }
                        }
                        
                        contentItem: Row {
                            spacing: 12
                            anchors.centerIn: parent
                            
                            Label {
                                text: modelData.gear
                                font.pixelSize: 24
                                font.bold: true
                                color: parent.parent.isSelected ? "#ffffff" : "#9ca3af"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            
                            Label {
                                text: modelData.label
                                font.pixelSize: 14
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
            
            // Error display (hidden by default)
            Label {
                id: errorText
                Layout.fillWidth: true
                visible: false
                color: "#ef4444"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                
                Timer {
                    interval: 5000
                    running: errorText.visible
                    onTriggered: errorText.visible = false
                }
            }
            
            // Status indicator
            Row {
                Layout.fillWidth: true
                spacing: 8
                
                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: gearHandler.currentGear !== "" ? "#10b981" : "#ef4444"
                    
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: true
                        NumberAnimation { to: 0.3; duration: 1000 }
                        NumberAnimation { to: 1.0; duration: 1000 }
                    }
                }
                
                Label {
                    text: "System Active"
                    font.pixelSize: 10
                    color: "#6b7280"
                }
            }
        }
    }
}