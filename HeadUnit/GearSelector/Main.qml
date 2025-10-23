import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import GearSelector 1.0

Window {
    id: root

    // Match the size expected by compositor for left panel
    width: 300
    height: 415

    visible: true
    title: "GearSelector"

    // Important: Remove FramelessWindowHint for Wayland clients
    // The compositor controls the window chrome
    // flags: Qt.FramelessWindowHint  // REMOVE THIS LINE

    // Create the gear handler instance
    GearHandler {
        id: gearHandler

        onCurrentGearChanged: {
            console.log("Gear changed to:", currentGear)
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
            anchors.margins: 10
            spacing: 10

            // Current gear display
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                color: "#374151"
                radius: 12
                border.color: "#4b5563"
                border.width: 2

                Column {
                    anchors.centerIn: parent
                    spacing: 5

                    Label {
                        text: "CURRENT GEAR"
                        font.pixelSize: 11
                        font.letterSpacing: 1.2
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
                                default: return "#ffffff"
                            }
                        }
                        anchors.horizontalCenter: parent.horizontalCenter

                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }

                        // Scale animation on change
                        Behavior on text {
                            SequentialAnimation {
                                NumberAnimation {
                                    target: parent
                                    property: "scale"
                                    to: 1.2
                                    duration: 100
                                }
                                NumberAnimation {
                                    target: parent
                                    property: "scale"
                                    to: 1.0
                                    duration: 100
                                }
                            }
                        }
                    }
                }
            }

            // Separator line
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 2
                color: "#374151"
                radius: 1
            }

            // Gear buttons
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10

                Repeater {
                    model: ListModel {
                        ListElement { gear: "P"; label: "Park"; color: "#1e40af" }
                        ListElement { gear: "R"; label: "Reverse"; color: "#991b1b" }
                        ListElement { gear: "N"; label: "Neutral"; color: "#374151" }
                        ListElement { gear: "D"; label: "Drive"; color: "#166534" }
                    }

                    delegate: Button {
                        property bool isSelected: gearHandler.currentGear === model.gear
                        property color buttonColor: model.color

                        Layout.fillWidth: true
                        Layout.preferredHeight: 55
                        enabled: gearHandler.isConnected
                        opacity: enabled ? 1.0 : 0.5

                        background: Rectangle {
                            color: parent.isSelected ? parent.buttonColor : "#1f2937"
                            radius: 8
                            border.color: parent.isSelected ? Qt.lighter(parent.buttonColor, 1.5) : "#374151"
                            border.width: parent.hovered ? 2 : 1

                            Behavior on color {
                                ColorAnimation { duration: 200 }
                            }

                            Behavior on border.width {
                                NumberAnimation { duration: 100 }
                            }

                            // Glow effect for selected button
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: -3
                                radius: parent.radius + 2
                                color: "transparent"
                                border.color: parent.parent.parent.buttonColor
                                border.width: 2
                                opacity: parent.parent.parent.isSelected ? 0.4 : 0

                                Behavior on opacity {
                                    NumberAnimation { duration: 200 }
                                }
                            }
                        }

                        contentItem: Row {
                            spacing: 12
                            anchors.centerIn: parent

                            Label {
                                text: model.gear
                                font.pixelSize: 22
                                font.bold: true
                                color: parent.parent.isSelected ? "#ffffff" : "#9ca3af"
                                anchors.verticalCenter: parent.verticalCenter

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                            }

                            Label {
                                text: model.label
                                font.pixelSize: 13
                                color: parent.parent.isSelected ? "#e5e7eb" : "#6b7280"
                                anchors.verticalCenter: parent.verticalCenter

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                            }
                        }

                        onClicked: {
                            console.log("Button clicked: " + model.gear)
                            gearHandler.currentGear = model.gear

                            // Visual feedback - scale animation
                            scaleAnimation.start()
                        }

                        SequentialAnimation {
                            id: scaleAnimation
                            NumberAnimation {
                                target: background
                                property: "scale"
                                to: 0.95
                                duration: 80
                                easing.type: Easing.OutQuad
                            }
                            NumberAnimation {
                                target: background
                                property: "scale"
                                to: 1.0
                                duration: 80
                                easing.type: Easing.OutQuad
                            }
                        }
                    }
                }
            }

            // Status bar at bottom
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                color: "#1f2937"
                radius: 6
                border.color: "#374151"
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: 10

                    Rectangle {
                        id: statusIndicator
                        width: 8
                        height: 8
                        radius: 4
                        color: gearHandler.isConnected ? "#10b981" : "#ef4444"
                        anchors.verticalCenter: parent.verticalCenter

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: true
                            NumberAnimation { to: 0.4; duration: 800 }
                            NumberAnimation { to: 1.0; duration: 800 }
                        }
                    }

                    Label {
                        id: statusText
                        text: gearHandler.isConnected ? "Connected" : "Disconnected"
                        font.pixelSize: 11
                        color: "#9ca3af"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        console.log("=== GearSelector Application Started ===")
        console.log("Window size:", width, "x", height)
        console.log("GearHandler connected:", gearHandler.isConnected)
        console.log("Current gear:", gearHandler.currentGear)
    }
}
