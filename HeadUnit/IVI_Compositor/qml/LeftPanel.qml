import QtQuick
import QtWayland.Compositor

Rectangle {
    id: leftPanel

    color: "#2d2d2d"

    // Border separator with gradient
    Rectangle {
        anchors.right: parent.right
        width: 2
        height: parent.height

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#404040" }
            GradientStop { position: 0.5; color: "#606060" }
            GradientStop { position: 1.0; color: "#404040" }
        }
    }

    // Top section: Clock and Temperature
    Rectangle {
        id: infoSection
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 150
        color: "#2d2d2d"

        Column {
            anchors.centerIn: parent
            spacing: 10

            // Clock Display with glow effect
            Rectangle {
                width: 280
                height: 70
                color: "#1a1a1a"
                radius: 8
                border.color: timeGlow.visible ? "#00ff88" : "#404040"
                border.width: timeGlow.visible ? 2 : 1

                Behavior on border.color {
                    ColorAnimation { duration: 300 }
                }

                // Subtle glow effect when minutes change
                Rectangle {
                    id: timeGlow
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.color: "#00ff88"
                    border.width: 3
                    opacity: 0
                    visible: opacity > 0

                    SequentialAnimation on opacity {
                        id: glowAnimation
                        running: false
                        NumberAnimation { to: 0.5; duration: 200 }
                        NumberAnimation { to: 0; duration: 800 }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    // Time with fade transition
                    Text {
                        id: timeText
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatTime(new Date(), "hh:mm")
                        color: "#00ff88"
                        font.pixelSize: 32
                        font.bold: true
                        font.family: "Monospace"

                        Behavior on text {
                            SequentialAnimation {
                                NumberAnimation {
                                    target: timeText
                                    property: "opacity"
                                    to: 0.5
                                    duration: 100
                                }
                                PropertyAction { }
                                NumberAnimation {
                                    target: timeText
                                    property: "opacity"
                                    to: 1.0
                                    duration: 100
                                }
                            }
                        }
                    }

                    // Date
                    Text {
                        id: dateText
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDate(new Date(), "ddd, MMM dd yyyy")
                        color: "#aaaaaa"
                        font.pixelSize: 11
                    }
                }
            }

            // Temperature Display
            Rectangle {
                width: 280
                height: 50
                color: "#1a1a1a"
                radius: 8
                border.color: "#404040"
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: 15

                    // Temperature icon with pulse
                    Text {
                        id: tempIcon
                        text: "🌡"
                        font.pixelSize: 24
                        anchors.verticalCenter: parent.verticalCenter

                        SequentialAnimation on scale {
                            loops: Animation.Infinite
                            NumberAnimation { to: 1.1; duration: 2000; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 1.0; duration: 2000; easing.type: Easing.InOutQuad }
                        }
                    }

                    // Temperature value
                    Column {
                        spacing: 0

                        Row {
                            spacing: 5

                            Text {
                                id: temperatureText
                                text: "22"
                                color: "#ff9800"
                                font.pixelSize: 28
                                font.bold: true

                                Behavior on color {
                                    ColorAnimation { duration: 500 }
                                }

                                Behavior on text {
                                    NumberAnimation {
                                        target: temperatureText
                                        property: "scale"
                                        from: 1.2
                                        to: 1.0
                                        duration: 300
                                    }
                                }
                            }

                            Text {
                                text: "°C"
                                color: temperatureText.color
                                font.pixelSize: 18
                                anchors.verticalCenter: parent.verticalCenter

                                Behavior on color {
                                    ColorAnimation { duration: 500 }
                                }
                            }
                        }

                        Text {
                            text: "Ambient"
                            color: "#888888"
                            font.pixelSize: 9
                        }
                    }
                }
            }
        }

        // Bottom border with gradient
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 2

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#2d2d2d" }
                GradientStop { position: 0.5; color: "#606060" }
                GradientStop { position: 1.0; color: "#2d2d2d" }
            }
        }
    }

    // Container for GearSelector surface - FIXED sizing
    Item {
        id: gearSelectorContainer
        anchors.top: infoSection.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        //anchors.topMargin: 10
        // No left/right margins here - we'll center the surface inside

        //clip: true

        // Debug: Show the container bounds
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: "#404040"
            border.width: 1
            visible: gearSelectorContainer.children.length === 0
        }
    }

    // Placeholder
    Column {
        anchors.centerIn: gearSelectorContainer
        //spacing: 10
        visible: gearSelectorContainer.children.length === 0

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Waiting for\nGearSelector..."
            color: "#808080"
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 1000 }
                NumberAnimation { to: 1.0; duration: 1000 }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Container: " + gearSelectorContainer.width + "x" + gearSelectorContainer.height
            color: "#606060"
            font.pixelSize: 10
        }
    }

    // Timer to update clock
    Timer {
        interval: 1000
        running: true
        repeat: true

        property string lastMinute: ""

        onTriggered: {
            var now = new Date()
            var currentMinute = Qt.formatTime(now, "hh:mm")

            timeText.text = currentMinute
            dateText.text = Qt.formatDate(now, "ddd, MMM dd yyyy")

            // Trigger glow when minute changes
            if (lastMinute !== "" && lastMinute !== currentMinute) {
                glowAnimation.restart()
            }
            lastMinute = currentMinute
        }
    }

    // Timer to update temperature
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: updateTemperature()
    }

    function addSurface(surfaceItem) {
        console.log("LeftPanel: Adding GearSelector surface")
        console.log("LeftPanel: Container size:", gearSelectorContainer.width, "x", gearSelectorContainer.height)
        console.log("LeftPanel: Surface size:", surfaceItem.width, "x", surfaceItem.height)

        if (gearSelectorContainer.width === 0 || gearSelectorContainer.height === 0) {
            console.error("LeftPanel: Container has zero size! Waiting for layout...")
            // Try again after a short delay
            Qt.callLater(function() {
                addSurface(surfaceItem)
            })
            return
        }

        // Set parent first
        surfaceItem.parent = gearSelectorContainer

        // Center horizontally in the container
        // Container is 300px wide, surface is 200px wide
        // So we need 50px offset from left
        surfaceItem.x = (gearSelectorContainer.width - surfaceItem.width) / 2
        surfaceItem.y = 0

        surfaceItem.visible = true
        surfaceItem.z = 10

        console.log("LeftPanel: GearSelector positioned at", surfaceItem.x, ",", surfaceItem.y)
        console.log("LeftPanel: Surface added successfully")
    }

    function updateTemperature() {
        var currentTemp = parseInt(temperatureText.text)
        var variation = Math.random() > 0.5 ? 1 : -1
        var newTemp = currentTemp + (Math.random() > 0.7 ? variation : 0)
        newTemp = Math.max(18, Math.min(28, newTemp))
        temperatureText.text = newTemp.toString()

        if (newTemp < 20) {
            temperatureText.color = "#00bfff"
        } else if (newTemp > 25) {
            temperatureText.color = "#ff4444"
        } else {
            temperatureText.color = "#ff9800"
        }
    }

    function setTemperature(temp) {
        temperatureText.text = temp.toString()
        if (temp < 20) {
            temperatureText.color = "#00bfff"
        } else if (temp > 25) {
            temperatureText.color = "#ff4444"
        } else {
            temperatureText.color = "#ff9800"
        }
    }

    property bool use24HourFormat: true

    function setTimeFormat(is24Hour) {
        use24HourFormat = is24Hour
        var now = new Date()
        timeText.text = is24Hour ? Qt.formatTime(now, "HH:mm") : Qt.formatTime(now, "hh:mm AP")
    }

    Component.onCompleted: {
        console.log("LeftPanel: Initialized")
        console.log("LeftPanel: Total size:", width, "x", height)
        console.log("LeftPanel: Info section:", infoSection.height, "px")
        // Log container size after a delay when layout is complete
        Qt.callLater(function() {
            console.log("LeftPanel: Container size after layout:",
                       gearSelectorContainer.width, "x", gearSelectorContainer.height)
        })
    }
}
