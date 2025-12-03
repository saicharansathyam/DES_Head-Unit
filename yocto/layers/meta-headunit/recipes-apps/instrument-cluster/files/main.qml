import QtQuick
import QtQuick.Window
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Window {
    id: root
    width: 1024
    height: 600
    visible: true
    title: qsTr("Instrument Cluster - 1024x600")
    color: "#000000"

    // ==================== Assets ====================
    FontLoader {
        id: orbitronFont
        source: "qrc:/fonts/Orbitron-VariableFont_wght.ttf"
    }

    // ==================== Main Container ====================
    Rectangle {
        anchors.fill: parent
        color: "#000000"

        // ==================== SPEEDOMETER (Left, 300px) ====================
        Item {
            id: speedometer
            anchors {
                left: parent.left
                leftMargin: 50
                verticalCenter: parent.verticalCenter
            }
            width: 300
            height: 300

            // Circular speedometer background
            Rectangle {
                id: speedometerBg
                anchors.centerIn: parent
                width: 280
                height: 280
                radius: 140
                color: "transparent"
                border.color: "#1e3a5f"
                border.width: 3
            }

            // Speed arc (visual gauge)
            Canvas {
                id: speedArc
                anchors.fill: speedometerBg
                
                property real currentSpeed: bridge ? Math.max(0, Math.min(bridge.speed, 300)) : 0
                
                onCurrentSpeedChanged: requestPaint()
                
                Behavior on currentSpeed {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    ctx.translate(width/2, height/2);
                    
                    var radius = 130;
                    var startAngle = -Math.PI * 0.75;  // -135 degrees
                    var endAngle = Math.PI * 0.75;     // 135 degrees
                    var totalRange = endAngle - startAngle;
                    
                    // Calculate current angle based on speed (0-300 cm/s)
                    var speedRatio = currentSpeed / 300.0;
                    var currentAngle = startAngle + (totalRange * speedRatio);
                    
                    // Draw background arc
                    ctx.beginPath();
                    ctx.arc(0, 0, radius, startAngle, endAngle, false);
                    ctx.strokeStyle = "#1e3a5f";
                    ctx.lineWidth = 8;
                    ctx.stroke();
                    
                    // Draw speed arc (green)
                    if (speedRatio > 0) {
                        ctx.beginPath();
                        ctx.arc(0, 0, radius, startAngle, currentAngle, false);
                        ctx.strokeStyle = "#00FF00";
                        ctx.lineWidth = 8;
                        ctx.stroke();
                    }
                }
                
                Connections {
                    target: bridge
                    function onSpeedChanged() {
                        speedArc.currentSpeed = Math.max(0, Math.min(bridge.speed, 300));
                    }
                }
            }

            // Speed value (center)
            Column {
                anchors.centerIn: parent
                spacing: 5
                
                Text {
                    id: speedValue
                    property real displaySpeed: bridge ? Math.max(0, bridge.speed) : 0
                    text: Math.round(displaySpeed).toString()
                    font.family: orbitronFont.name
                    font.pixelSize: 72
                    font.bold: true
                    color: "#00FF00"
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    Behavior on displaySpeed {
                        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                    }
                    
                    Connections {
                        target: bridge
                        function onSpeedChanged() {
                            speedValue.displaySpeed = Math.max(0, bridge.speed);
                        }
                    }
                }
                
                Text {
                    text: "cm/s"
                    font.family: orbitronFont.name
                    font.pixelSize: 24
                    color: "#808080"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            // Speed tick marks
            Repeater {
                model: 7  // 0, 50, 100, 150, 200, 250, 300
                
                Item {
                    property real angle: -135 + (index * 45)  // -135 to +135 degrees
                    property real radian: angle * Math.PI / 180
                    
                    x: speedometerBg.width/2 + Math.cos(radian) * 115 - 2
                    y: speedometerBg.height/2 + Math.sin(radian) * 115 - 2
                    
                    Rectangle {
                        width: 4
                        height: 15
                        color: "#FFFFFF"
                        radius: 2
                        rotation: parent.angle + 90
                    }
                }
            }
        }

        // ==================== GEAR INDICATOR (Center, 120px circle) ====================
        Item {
            id: gearDisplay
            anchors.centerIn: parent
            width: 200
            height: 250

            Column {
                anchors.centerIn: parent
                spacing: 20
                
                // Gear circle
                Rectangle {
                    id: gearCircle
                    width: 120
                    height: 120
                    radius: 60
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    property string currentGear: bridge ? bridge.gear : "P"
                    
                    color: {
                        switch(currentGear) {
                            case "P": return "#FF0000"  // Red
                            case "R": return "#FFA500"  // Orange
                            case "N": return "#0000FF"  // Blue
                            case "D": return "#00FF00"  // Green
                            case "S": return "#FF00FF"  // Purple
                            default: return "#808080"   // Gray
                        }
                    }
                    
                    border.color: "#FFFFFF"
                    border.width: 3
                    
                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }
                    
                    Text {
                        anchors.centerIn: parent
                        text: parent.currentGear
                        font.family: orbitronFont.name
                        font.pixelSize: 64
                        font.bold: true
                        color: "#FFFFFF"
                    }
                }
                
                // Mode text
                Text {
                    id: modeText
                    text: {
                        var gear = gearCircle.currentGear;
                        switch(gear) {
                            case "P": return "PARK"
                            case "R": return "REVERSE"
                            case "N": return "NEUTRAL"
                            case "D": return "DRIVE"
                            case "S": return "SPORT"
                            default: return ""
                        }
                    }
                    font.family: orbitronFont.name
                    font.pixelSize: 28
                    color: "#FFFFFF"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            // Turn indicators above gear
            Row {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.top
                    bottomMargin: 20
                }
                spacing: 80
                
                // Left turn indicator
                Item {
                    width: 60
                    height: 60
                    
                    Image {
                        id: leftIndicatorBase
                        source: "qrc:/images/left_indicator.png"
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        visible: false
                    }
                    
                    ColorOverlay {
                        anchors.fill: leftIndicatorBase
                        source: leftIndicatorBase
                        color: "#00FF00"
                        opacity: 0.0
                        
                        SequentialAnimation on opacity {
                            running: bridge && bridge.leftTurn
                            loops: Animation.Infinite
                            NumberAnimation { to: 1.0; duration: 200 }
                            NumberAnimation { to: 0.0; duration: 200 }
                            onRunningChanged: if (!running) parent.opacity = 0.0
                        }
                    }
                }
                
                // Right turn indicator
                Item {
                    width: 60
                    height: 60
                    
                    Image {
                        id: rightIndicatorBase
                        source: "qrc:/images/right_indicator.png"
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        visible: false
                    }
                    
                    ColorOverlay {
                        anchors.fill: rightIndicatorBase
                        source: rightIndicatorBase
                        color: "#00FF00"
                        opacity: 0.0
                        
                        SequentialAnimation on opacity {
                            running: bridge && bridge.rightTurn
                            loops: Animation.Infinite
                            NumberAnimation { to: 1.0; duration: 200 }
                            NumberAnimation { to: 0.0; duration: 200 }
                            onRunningChanged: if (!running) parent.opacity = 0.0
                        }
                    }
                }
            }
        }

        // ==================== BATTERY INFO (Right, 250px) ====================
        Item {
            id: batteryInfo
            anchors {
                right: parent.right
                rightMargin: 50
                verticalCenter: parent.verticalCenter
            }
            width: 250
            height: 200

            Column {
                anchors.centerIn: parent
                spacing: 15

                // Battery icon/gauge
                Rectangle {
                    id: batteryContainer
                    width: 200
                    height: 80
                    color: "transparent"
                    border.color: "#FFFFFF"
                    border.width: 3
                    radius: 5
                    anchors.horizontalCenter: parent.horizontalCenter

                    // Battery fill
                    Rectangle {
                        id: batteryFill
                        anchors {
                            left: parent.left
                            top: parent.top
                            bottom: parent.bottom
                            margins: 5
                        }
                        
                        property real batteryPercent: bridge ? Math.max(0, Math.min(bridge.battery, 100)) : 100
                        
                        width: (parent.width - 10) * (batteryPercent / 100)
                        color: {
                            if (batteryPercent > 60) return "#00FF00"
                            if (batteryPercent > 30) return "#FFA500"
                            return "#FF0000"
                        }
                        radius: 3

                        Behavior on width {
                            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                        }
                        
                        Behavior on color {
                            ColorAnimation { duration: 300 }
                        }
                        
                        Connections {
                            target: bridge
                            function onBatteryChanged() {
                                batteryFill.batteryPercent = Math.max(0, Math.min(bridge.battery, 100));
                            }
                        }
                    }

                    // Battery terminal
                    Rectangle {
                        anchors {
                            left: parent.right
                            verticalCenter: parent.verticalCenter
                        }
                        width: 10
                        height: 30
                        color: "#FFFFFF"
                    }
                }

                // Battery voltage (placeholder - connect to actual voltage from D-Bus)
                Text {
                    text: "12.6 V"
                    font.family: orbitronFont.name
                    font.pixelSize: 32
                    font.bold: true
                    color: "#00FF00"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                // Battery percentage
                Text {
                    property real displayBattery: bridge ? Math.max(0, Math.min(bridge.battery, 100)) : 100
                    text: Math.round(displayBattery) + "%"
                    font.family: orbitronFont.name
                    font.pixelSize: 28
                    color: "#FFFFFF"
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    Behavior on displayBattery {
                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                    }
                    
                    Connections {
                        target: bridge
                        function onBatteryChanged() {
                            parent.displayBattery = Math.max(0, Math.min(bridge.battery, 100));
                        }
                    }
                }
            }
        }

        // ==================== BOTTOM STATUS BAR (50px) ====================
        Rectangle {
            id: statusBar
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: 50
            color: "#1A1A1A"

            Row {
                anchors {
                    left: parent.left
                    leftMargin: 20
                    verticalCenter: parent.verticalCenter
                }
                spacing: 30

                // Temperature warning (example - connect to actual sensor)
                Image {
                    source: "qrc:/images/seame.png"  // Placeholder, use temp icon
                    width: 32
                    height: 32
                    visible: false  // Show when temperature > 90
                }

                // Low battery warning
                Image {
                    source: "qrc:/images/battery_icon.png"
                    width: 32
                    height: 32
                    visible: batteryFill.batteryPercent < 20
                    
                    ColorOverlay {
                        anchors.fill: parent
                        source: parent
                        color: "#FF0000"
                    }
                }
                
                // Connection status
                Text {
                    text: bridge ? "D-Bus Connected" : "D-Bus Disconnected"
                    font.family: orbitronFont.name
                    font.pixelSize: 14
                    color: bridge ? "#00FF00" : "#FF0000"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    Component.onCompleted: {
        console.log("=== Instrument Cluster Started ===")
        console.log("Resolution: 1024x600")
        console.log("D-Bus Bridge:", bridge ? "Connected" : "Not Connected")
    }
}
