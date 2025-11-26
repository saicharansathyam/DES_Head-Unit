import QtQuick
import QtQuick.Controls

Row {
    id: mediaControls
    spacing: 15
    anchors.horizontalCenter: parent.horizontalCenter

    property bool isPlaying: false

    signal previousClicked()
    signal playPauseClicked()
    signal nextClicked()
    signal shuffleToggled()
    signal repeatToggled()

    // Shuffle button
    Button {
        width: 50
        height: 50

        background: Rectangle {
            color: {
                if (parent.pressed) return theme.buttonPressedColor
                if (parent.hovered) return theme.buttonHoverColor
                return "#1e293b"
            }
            radius: 25
            border.width: 1
            border.color: theme.accentColor

            Behavior on color { ColorAnimation { duration: 200 } }
        }

        contentItem: Text {
            text: "🔀"
            font.pixelSize: 20
            color: "white"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        onClicked: shuffleToggled()
    }

    // Previous button
    Button {
        width: 60
        height: 60

        background: Rectangle {
            color: {
                if (parent.pressed) return theme.buttonPressedColor
                if (parent.hovered) return theme.buttonHoverColor
                return theme.themeColor
            }
            radius: 30
            border.width: 2
            border.color: theme.accentColor

            Behavior on color { ColorAnimation { duration: 200 } }
        }

        contentItem: Text {
            text: "⏮"
            font.pixelSize: 24
            color: "white"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        onClicked: previousClicked()
    }

    // Play/Pause button (larger, centered)
    Button {
        width: 80
        height: 80

        background: Rectangle {
            color: {
                if (parent.pressed) return theme.buttonPressedColor
                if (parent.hovered) return theme.buttonHoverColor
                return theme.themeColor
            }
            radius: 40
            border.width: 3
            border.color: theme.accentColor

            Behavior on color { ColorAnimation { duration: 200 } }

            // Glow effect
            Rectangle {
                anchors.centerIn: parent
                width: parent.width + 10
                height: parent.height + 10
                radius: (parent.width + 10) / 2
                color: "transparent"
                border.width: 2
                border.color: theme.themeColor
                opacity: 0.3
            }
        }

        contentItem: Text {
            text: isPlaying ? "⏸" : "▶"
            font.pixelSize: 32
            color: "white"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        onClicked: {
            isPlaying = !isPlaying
            playPauseClicked()
        }
    }

    // Next button
    Button {
        width: 60
        height: 60

        background: Rectangle {
            color: {
                if (parent.pressed) return theme.buttonPressedColor
                if (parent.hovered) return theme.buttonHoverColor
                return theme.themeColor
            }
            radius: 30
            border.width: 2
            border.color: theme.accentColor

            Behavior on color { ColorAnimation { duration: 200 } }
        }

        contentItem: Text {
            text: "⏭"
            font.pixelSize: 24
            color: "white"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        onClicked: nextClicked()
    }

    // Repeat button
    Button {
        width: 50
        height: 50

        background: Rectangle {
            color: {
                if (parent.pressed) return theme.buttonPressedColor
                if (parent.hovered) return theme.buttonHoverColor
                return "#1e293b"
            }
            radius: 25
            border.width: 1
            border.color: theme.accentColor

            Behavior on color { ColorAnimation { duration: 200 } }
        }

        contentItem: Text {
            text: "🔁"
            font.pixelSize: 20
            color: "white"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        onClicked: repeatToggled()
    }
}
