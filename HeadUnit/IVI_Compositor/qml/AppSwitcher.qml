import QtQuick
import QtQuick.Controls

Rectangle {
    id: appSwitcher
    color: "#2d2d2d"

    signal switchToApp(int appId)

    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 2
        color: "#404040"
    }

    Row {
        anchors.centerIn: parent
        spacing: 12

        // HomePage Button
        Button {
            width: 100
            height: 50

            background: Rectangle {
                color: surfaceManager.currentRightApp === 1000 ? "#0078d7" : "#404040"
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
                    font.pixelSize: 22
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Home"
                    color: "white"
                    font.pixelSize: 11
                }
            }

            onClicked: switchToApp(1000)
        }

        // MediaPlayer Button
        Button {
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
                    text: "▶"
                    color: "white"
                    font.pixelSize: 20
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "YouTube"
                    color: "white"
                    font.pixelSize: 11
                }
            }

            onClicked: switchToApp(1005)
        }
    }
}
