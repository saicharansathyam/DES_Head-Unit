import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: homeView

    color: "#0a0e1a"

    // Signal emitted when user wants to launch an app
    signal applicationRequested(int appId)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        // Main content row
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            // Left side: Map tile
            MapTile {
                Layout.preferredWidth: 420
                Layout.preferredHeight: 420
                Layout.fillHeight: false

                onNavigationClicked: {
                    console.log("HomeView: Requesting Navigation app")
                    applicationRequested(1004)
                }
            }

            // Right side: App tiles grid
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                // Media Player tile
                Rectangle {
                    id: mediaTile
                    Layout.preferredWidth: 260
                    Layout.preferredHeight: 200
                    radius: 12
                    color: "#081028"
                    border.color: hovered ? "#3a7ca5" : "#264653"
                    border.width: 2

                    property bool hovered: false

                    Behavior on border.color {
                        ColorAnimation { duration: 200 }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true

                        onEntered: mediaTile.hovered = true
                        onExited: mediaTile.hovered = false

                        onClicked: {
                            console.log("HomeView: Requesting MediaPlayer app")
                            applicationRequested(1002)
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 12

                        Text {
                            text: "♫"
                            color: "#4fc3f7"
                            font.pixelSize: 44
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: "Media Player"
                            color: "#e6eef8"
                            font.pixelSize: 16
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }

                // Theme Color tile
                Rectangle {
                    id: themeTile
                    Layout.preferredWidth: 260
                    Layout.preferredHeight: 200
                    radius: 12
                    color: "#081028"
                    border.color: hovered ? "#3a7ca5" : "#264653"
                    border.width: 2

                    property bool hovered: false

                    Behavior on border.color {
                        ColorAnimation { duration: 200 }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true

                        onEntered: themeTile.hovered = true
                        onExited: themeTile.hovered = false

                        onClicked: {
                            console.log("HomeView: Requesting ThemeColor app")
                            applicationRequested(1003)
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 12

                        Text {
                            text: "◐"
                            color: "#ffa726"
                            font.pixelSize: 44
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: "Theme Selector"
                            color: "#e6eef8"
                            font.pixelSize: 16
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        console.log("HomeView initialized - Size:", width, "x", height)
    }
}
