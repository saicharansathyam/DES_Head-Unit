import QtQuick
import QtQuick.Window
import QtQuick.Controls

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 824
    height: 470
    title: "Media Player"

    color: "#0f172a"

    Rectangle {
        anchors.fill: parent
        color: "#0f172a"

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            // Header
            Row {
                width: parent.width
                height: 50
                spacing: 15

                Text {
                    text: "Media Player"
                    font.pixelSize: 28
                    font.bold: true
                    color: "#ffffff"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    width: 100
                    height: 35
                    radius: 17.5
                    color: theme.themeColor  // Dynamic theme
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on color { ColorAnimation { duration: 300 } }

                    Text {
                        anchors.centerIn: parent
                        text: "LIVE"
                        color: "white"
                        font.pixelSize: 14
                        font.bold: true
                    }
                }
            }

            // Source Selector with Theme
            SourceSelector {
                id: sourceSelector
                width: parent.width
                height: 60
            }

            // Media Display
            MediaDisplay {
                id: mediaDisplay
                width: parent.width
                height: 180
            }

            // Progress Bar with Theme
            ProgressBar {
                id: progressBar
                width: parent.width
                height: 40
            }

            // Media Controls with Theme
            MediaControls {
                id: mediaControls
                width: parent.width
                height: 80
            }

            // Volume Control with Theme
            VolumeControl {
                id: volumeControl
                width: parent.width
                height: 60
            }
        }
    }
}
