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
                color: surfaceManager.currentRightApp === 0 ? "#0078d7" : "#404040"
                radius: 5
                border.color: "#606060"
                border.width: 1
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
                color: surfaceManager.currentRightApp === 1002 ? "#0078d7" : "#404040"
                radius: 5
                border.color: "#606060"
                border.width: 1
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
                color: surfaceManager.currentRightApp === 1003 ? "#0078d7" : "#404040"
                radius: 5
                border.color: "#606060"
                border.width: 1
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
                color: surfaceManager.currentRightApp === 1004 ? "#0078d7" : "#404040"
                radius: 5
                border.color: "#606060"
                border.width: 1
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

        // YouTube Button
        Button {
            id: youtubeButton
            width: 100
            height: 50

            background: Rectangle {
                color: surfaceManager.currentRightApp === 1005 ? "#0078d7" : "#404040"
                radius: 5
                border.color: "#606060"
                border.width: 1
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
