import QtQuick
import QtQuick.Controls

Rectangle {
    id: appSwitcher

    color: "#2d2d2d"

    signal switchToApp(int appId)

    // Top border
    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 2
        color: "#404040"
    }

    Row {
        anchors.centerIn: parent
        spacing: 12

        // Home Button
        Button {
            id: homeButton
            width: 100
            height: 50

            background: Rectangle {
                color: {
                    if (homeButton.pressed) return theme.buttonPressedColor
                    if (homeButton.hovered) return theme.buttonHoverColor
                    if (surfaceManager.currentRightApp === 0) return theme.themeColor
                    return "#404040"
                }
                radius: 5
                border.color: theme.accentColor
                border.width: surfaceManager.currentRightApp === 0 ? 2 : 1

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            contentItem: Column {
                anchors.centerIn: parent
                spacing: 3

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "⌂"
                    color: "white"
                    font.pixelSize: 20
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Home"
                    color: "white"
                    font.pixelSize: 11
                }
            }

            onClicked: switchToApp(0)  // 0 = HomeView
        }

        // MediaPlayer Button
        Button {
            id: mediaButton
            width: 100
            height: 50

            background: Rectangle {
                color: {
                    if (mediaButton.pressed) return theme.buttonPressedColor
                    if (mediaButton.hovered) return theme.buttonHoverColor
                    if (surfaceManager.currentRightApp === 1002) return theme.themeColor
                    return "#404040"
                }
                radius: 5
                border.color: theme.accentColor
                border.width: surfaceManager.currentRightApp === 1002 ? 2 : 1

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            contentItem: Column {
                anchors.centerIn: parent
                spacing: 3

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "♫"
                    color: "white"
                    font.pixelSize: 20
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Media"
                    color: "white"
                    font.pixelSize: 11
                }
            }

            onClicked: switchToApp(1002)
        }

        // ThemeColor Button
        Button {
            id: themeButton
            width: 100
            height: 50

            background: Rectangle {
                color: {
                    if (themeButton.pressed) return theme.buttonPressedColor
                    if (themeButton.hovered) return theme.buttonHoverColor
                    if (surfaceManager.currentRightApp === 1003) return theme.themeColor
                    return "#404040"
                }
                radius: 5
                border.color: theme.accentColor
                border.width: surfaceManager.currentRightApp === 1003 ? 2 : 1

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            contentItem: Column {
                anchors.centerIn: parent
                spacing: 3

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "◐"
                    color: "white"
                    font.pixelSize: 20
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Theme"
                    color: "white"
                    font.pixelSize: 11
                }
            }

            onClicked: switchToApp(1003)
        }

        // Navigation Button
        Button {
            id: navButton
            width: 100
            height: 50

            background: Rectangle {
                color: {
                    if (navButton.pressed) return theme.buttonPressedColor
                    if (navButton.hovered) return theme.buttonHoverColor
                    if (surfaceManager.currentRightApp === 1004) return theme.themeColor
                    return "#404040"
                }
                radius: 5
                border.color: theme.accentColor
                border.width: surfaceManager.currentRightApp === 1004 ? 2 : 1

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            contentItem: Column {
                anchors.centerIn: parent
                spacing: 3

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "⊕"
                    color: "white"
                    font.pixelSize: 20
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Nav"
                    color: "white"
                    font.pixelSize: 11
                }
            }

            onClicked: switchToApp(1004)
        }

        // Settings Button
        Button {
            id: settingsButton
            width: 100
            height: 50

            background: Rectangle {
                color: {
                    if (settingsButton.pressed) return theme.buttonPressedColor
                    if (settingsButton.hovered) return theme.buttonHoverColor
                    if (surfaceManager.currentRightApp === 1005) return theme.themeColor
                    return "#404040"
                }
                radius: 5
                border.color: theme.accentColor
                border.width: surfaceManager.currentRightApp === 1005 ? 2 : 1

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            contentItem: Column {
                anchors.centerIn: parent
                spacing: 3

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "⚙"
                    color: "white"
                    font.pixelSize: 20
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Settings"
                    color: "white"
                    font.pixelSize: 11
                }
            }

            onClicked: switchToApp(1005)
        }
    }
}
