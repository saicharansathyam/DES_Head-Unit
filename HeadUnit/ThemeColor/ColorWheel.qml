import QtQuick
import QtQuick.Controls

Item {
    id: root

    // Signal declaration with typed parameter
    signal colorSelected(color selectedColor)

    property real centerX: width / 2
    property real centerY: height / 2
    property real radius: Math.min(width, height) / 2 - 20

    Canvas {
        id: colorWheelCanvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            // Draw color wheel
            for (var angle = 0; angle < 360; angle += 1) {
                var startAngle = (angle - 90) * Math.PI / 180
                var endAngle = (angle + 1 - 90) * Math.PI / 180

                var gradient = ctx.createRadialGradient(
                    root.centerX, root.centerY, 0,
                    root.centerX, root.centerY, root.radius
                )

                var hue = angle / 360
                var color1 = Qt.hsva(hue, 0, 1, 1)
                var color2 = Qt.hsva(hue, 1, 1, 1)

                gradient.addColorStop(0, color1)
                gradient.addColorStop(1, color2)

                ctx.fillStyle = gradient
                ctx.beginPath()
                ctx.moveTo(root.centerX, root.centerY)
                ctx.arc(root.centerX, root.centerY, root.radius, startAngle, endAngle)
                ctx.closePath()
                ctx.fill()
            }
        }
    }

    // Selector handle
    Rectangle {
        id: selectorHandle
        width: 30
        height: 30
        radius: 15
        color: "transparent"
        border.color: "white"
        border.width: 3
        visible: false

        Rectangle {
            anchors.centerIn: parent
            width: 20
            height: 20
            radius: 10
            color: parent.border.color
            border.color: "black"
            border.width: 2
        }
    }

    MouseArea {
        anchors.fill: parent

        function updateSelector(mouse) {
            var dx = mouse.x - root.centerX
            var dy = mouse.y - root.centerY
            var distance = Math.sqrt(dx * dx + dy * dy)

            if (distance > root.radius) {
                distance = root.radius
            }

            var angle = Math.atan2(dy, dx)
            var x = root.centerX + distance * Math.cos(angle)
            var y = root.centerY + distance * Math.sin(angle)

            selectorHandle.x = x - selectorHandle.width / 2
            selectorHandle.y = y - selectorHandle.height / 2
            selectorHandle.visible = true

            // Calculate HSV values
            var hue = ((angle * 180 / Math.PI + 90 + 360) % 360) / 360
            var saturation = distance / root.radius
            var value = 1.0

            var selectedColor = Qt.hsva(hue, saturation, value, 1)
            root.colorSelected(selectedColor)
        }

        onPressed: function(mouse) {
            updateSelector(mouse)
        }

        onPositionChanged: function(mouse) {
            if (pressed) {
                updateSelector(mouse)
            }
        }
    }

    Component.onCompleted: {
        colorWheelCanvas.requestPaint()
    }
}
