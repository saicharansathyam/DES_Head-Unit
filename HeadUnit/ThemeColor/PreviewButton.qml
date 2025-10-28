import QtQuick
import QtQuick.Controls
import "ColorUtils.js" as ColorUtils

Item {
    id: root

    property color currentColor: "#3b82f6"
    property color previewColor: currentColor
    property bool isPreviewing: false

    // Signal declaration with typed parameter
    signal colorConfirmed(color confirmedColor)

    function updatePreviewColor(newColor) {
        previewColor = newColor
        isPreviewing = true
    }

    function resetToCurrentColor() {
        previewColor = currentColor
        isPreviewing = false
    }

    Rectangle {
        id: buttonBackground
        anchors.fill: parent
        radius: width / 2
        color: isPreviewing ? previewColor : currentColor
        border.color: "white"
        border.width: 4

        Behavior on color {
            ColorAnimation { duration: 200 }
        }

        // Preview label or Confirm button
        Column {
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: isPreviewing ? "Preview" : "Current"
                color: ColorUtils.getContrastColor(buttonBackground.color)
                font.pixelSize: 18
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: isPreviewing ? "Tap to\nConfirm" : ColorUtils.colorToHex(root.currentColor)
                color: ColorUtils.getContrastColor(buttonBackground.color)
                font.pixelSize: isPreviewing ? 16 : 14
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
                wrapMode: Text.WordWrap
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: isPreviewing ? Qt.PointingHandCursor : Qt.ArrowCursor

            onClicked: {
                if (isPreviewing) {
                    root.colorConfirmed(previewColor)
                    currentColor = previewColor
                    isPreviewing = false
                    rippleAnimation.restart()
                }
            }
        }

        // Ripple effect on click
        Rectangle {
            id: ripple
            anchors.centerIn: parent
            width: 0
            height: 0
            radius: width / 2
            color: "white"
            opacity: 0

            ParallelAnimation {
                id: rippleAnimation
                NumberAnimation {
                    target: ripple
                    property: "width"
                    to: buttonBackground.width
                    duration: 400
                }
                NumberAnimation {
                    target: ripple
                    property: "height"
                    to: buttonBackground.height
                    duration: 400
                }
                NumberAnimation {
                    target: ripple
                    property: "opacity"
                    from: 0.3
                    to: 0
                    duration: 400
                }
            }
        }
    }
}
