import QtQuick
import QtQuick.Window
import QtWayland.Compositor

WaylandOutput {
    id: output

    property alias leftPanel: leftPanelItem
    property alias rightPanel: rightPanelItem

    compositor: waylandCompositor

    window: Window {
        id: mainWindow

        width: 1024
        height: 600
        visible: true

        title: "HeadUnit IVI Compositor"

        // Flags for embedded display
        flags: Qt.FramelessWindowHint

        Rectangle {
            id: background
            anchors.fill: parent
            color: "#1a1a1a"

            // Left panel - persistent GearSelector
            LeftPanel {
                id: leftPanelItem
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 300
                height: parent.height
            }

            // Right panel - switchable applications
            RightPanel {
                id: rightPanelItem
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 724
                height: parent.height

                onApplicationSwitchRequested: function(appId) {
                    surfaceManager.switchToApplication(appId)
                }
            }

            // Debug info overlay (remove in production)
            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                width: 200
                height: 80
                color: "#80000000"
                visible: true

                Column {
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        text: "Active Surfaces: " + surfaceManager.activeSurfaceCount
                        color: "white"
                        font.pixelSize: 12
                    }

                    Text {
                        text: "Current App: " + surfaceManager.currentRightApp
                        color: "white"
                        font.pixelSize: 12
                    }

                    Text {
                        text: "FPS: " + fpsCounter.fps.toFixed(0)
                        color: "white"
                        font.pixelSize: 12
                    }
                }
            }

            // FPS Counter
            QtObject {
                id: fpsCounter
                property real fps: 0
                property int frameCount: 0
                property real lastTime: 0

                function update() {
                    frameCount++
                    var currentTime = Date.now()
                    if (currentTime - lastTime >= 1000) {
                        fps = frameCount * 1000 / (currentTime - lastTime)
                        frameCount = 0
                        lastTime = currentTime
                    }
                }
            }

            Timer {
                interval: 16
                running: true
                repeat: true
                onTriggered: fpsCounter.update()
            }
        }
    }
}

