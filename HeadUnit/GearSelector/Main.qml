import QtQuick
import QtQuick.Window
import QtQuick.Controls

Window {
    id: root
    width: 200
    height: 415
    visible: true
    title: "Gear Selector"

    Rectangle {
        anchors.fill: parent
        color: "#1a1a1a"

        Column {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 10

            // Gear Selection Grid
            Grid {
                id: gearGrid
                width: parent.width
                columns: 1
                spacing: 8
                anchors.horizontalCenter: parent.horizontalCenter

                // Park
                GearButton {
                    gear: "P"
                    label: "Park"
                    width: parent.width
                    isActive: gearHandler.currentGear === "P"
                    onClicked: gearHandler.setGear("P")
                }

                // Reverse
                GearButton {
                    gear: "R"
                    label: "Reverse"
                    width: parent.width
                    isActive: gearHandler.currentGear === "R"
                    onClicked: gearHandler.setGear("R")
                }

                // Neutral
                GearButton {
                    gear: "N"
                    label: "Neutral"
                    width: parent.width
                    isActive: gearHandler.currentGear === "N"
                    onClicked: gearHandler.setGear("N")
                }

                // Drive
                GearButton {
                    gear: "D"
                    label: "Drive"
                    width: parent.width
                    isActive: gearHandler.currentGear === "D"
                    onClicked: gearHandler.setGear("D")
                }
            }

            // Gear Position Indicator
            Rectangle {
                width: parent.width
                height: 30
                color: "transparent"

                Row {
                    anchors.centerIn: parent
                    spacing: 5

                    Repeater {
                        model: ["P", "R", "N", "D"]

                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            color: gearHandler.currentGear === modelData ? theme.themeColor : "#404040"
                            border.width: 1
                            border.color: "#666666"

                            Behavior on color {
                                ColorAnimation { duration: 200 }
                            }
                        }
                    }
                }
            }
        }
    }

    function getGearName(gear) {
        switch(gear) {
            case "P": return "PARK"
            case "R": return "REVERSE"
            case "N": return "NEUTRAL"
            case "D": return "DRIVE"
            default: return ""
        }
    }
}
