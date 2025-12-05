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

        // Volume Button (right side)
        Button {
            id: volumeButton
            width: 50
            height: 50

            background: Rectangle {
                color: volumePopup.visible ? theme.themeColor : "#404040"
                radius: 5
                border.color: theme.accentColor
                border.width: volumePopup.visible ? 2 : 1

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            contentItem: Text {
                anchors.centerIn: parent
                text: "🔊"
                color: "white"
                font.pixelSize: 22
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }

            onClicked: volumePopup.visible = !volumePopup.visible
        }
    }

    // Volume Popup Slider
    Rectangle {
        id: volumePopup
        visible: false
        width: 70
        height: 220
        color: "#2d2d2d"
        border.color: theme.accentColor
        border.width: 2
        radius: 5

        // Position above the volume button (on the right side)
        anchors.bottom: parent.top
        anchors.bottomMargin: 5
        anchors.right: parent.right
        anchors.rightMargin: 0

        z: 1000

        Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            // Volume Label
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Vol"
                color: "white"
                font.pixelSize: 10
                font.bold: true
            }

            // Volume Slider (Vertical)
            Slider {
                id: volumeSlider
                orientation: Qt.Vertical
                from: 0
                to: 100
                value: dbusManager.systemVolume
                width: 40
                height: 140
                anchors.horizontalCenter: parent.horizontalCenter

                background: Rectangle {
                    x: volumeSlider.availableWidth / 2 - 2
                    y: volumeSlider.topPadding
                    implicitWidth: 4
                    implicitHeight: 40
                    width: 4
                    height: volumeSlider.availableHeight
                    radius: 2
                    color: theme.themeColor

                    Rectangle {
                        width: parent.width
                        height: volumeSlider.visualPosition * parent.height
                        color: "#555555"
                        radius: 2
                    }
                }

                handle: Rectangle {
                    x: volumeSlider.availableWidth / 2 - width / 2
                    y: volumeSlider.topPadding + volumeSlider.visualPosition * (volumeSlider.availableHeight - height)
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 14
                    color: volumeSlider.pressed ? theme.buttonPressedColor : theme.themeColor
                    border.color: "white"
                    border.width: 2

                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }
                }

                onMoved: {
                    dbusManager.setSystemVolume(Math.round(value))
                }
            }

            // Volume Percentage Display
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Math.round(volumeSlider.value) + "%"
                color: theme.themeColor
                font.pixelSize: 12
                font.bold: true
            }
        }

        // Connections to track volume changes from D-Bus
        Connections {
            target: dbusManager
            function onSystemVolumeChanged(volume) {
                volumeSlider.value = volume
            }
        }
    }

    // Mouse area to close popup when clicking outside
    MouseArea {
        anchors.fill: parent
        enabled: volumePopup.visible
        z: 999
        onClicked: volumePopup.visible = false

        // Don't close if clicking on the popup or button
        onPressed: {
            if (mouse.x >= volumePopup.x && mouse.x <= volumePopup.x + volumePopup.width &&
                mouse.y >= volumePopup.y && mouse.y <= volumePopup.y + volumePopup.height) {
                mouse.accepted = false
            } else if (mouse.x >= volumeButton.mapToItem(appSwitcher, 0, 0).x &&
                       mouse.x <= volumeButton.mapToItem(appSwitcher, 0, 0).x + volumeButton.width &&
                       mouse.y >= volumeButton.mapToItem(appSwitcher, 0, 0).y &&
                       mouse.y <= volumeButton.mapToItem(appSwitcher, 0, 0).y + volumeButton.height) {
                mouse.accepted = false
            }
        }
    }
}
