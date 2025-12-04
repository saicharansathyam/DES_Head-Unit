import QtQuick
import QtQuick.Window
import QtWayland.Compositor
import QtWayland.Compositor.IviApplication

WaylandCompositor {
    id: waylandCompositor

    // NESTED COMPOSITOR: We provide wayland-2 socket for our apps
    // while we ourselves connect to Weston on wayland-0
    socketName: "wayland-2"

    // IVI Application extension for our nested clients
    IviApplication {
        id: iviApplication

        onIviSurfaceCreated: function(iviSurface) {
            console.log("Nested Compositor: IVI Surface created with ID:", iviSurface.iviId)
            surfaceManager.handleNewSurface(iviSurface)
            notifyAppConnected(iviSurface.iviId)
        }
    }

    // Surface manager (manages nested app surfaces)
    SurfaceManager {
        id: surfaceManager
        compositor: waylandCompositor

        onSurfaceCreatedForLeft: function(surface, item) {
            output.window.leftPanel.addSurface(item)
        }

        onSurfaceCreatedForRight: function(surface, item) {
            output.window.rightPanel.addSurface(item)
        }

        onSurfaceDestroyed: function(iviId) {
            console.log("Surface destroyed:", iviId)
            notifyAppDisconnected(iviId)
        }
    }

    // Our compositor's output (rendered as a Wayland window to Weston)
    WaylandOutput {
        id: output
        compositor: waylandCompositor
        sizeFollowsWindow: true

        window: Window {
            id: mainWindow

            property alias leftPanel: leftPanelItem
            property alias rightPanel: rightPanelItem

            width: 1024
            height: 600
            visible: true
            title: "HeadUnit IVI Nested Compositor"
            
            // Run as Wayland client (no FramelessWindowHint for Weston)
            // Weston will position us via IVI-Shell
            color: "#1a1a1a"

            Rectangle {
                id: background
                anchors.fill: parent
                color: "#1a1a1a"

                // Left panel - Clock, Temperature, GearSelector
                LeftPanel {
                    id: leftPanelItem
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 200
                }

                // Right panel - HomeView / Apps + AppSwitcher
                RightPanel {
                    id: rightPanelItem
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 824

                    onApplicationSwitchRequested: function(appId) {
                        console.log("=== Application Switch Requested ===")
                        console.log("Requested App ID:", appId)
                        console.log("Current App ID:", surfaceManager.currentRightApp)

                        var appName = getAppName(appId)
                        console.log("App Name:", appName)

                        if (appId === 0) {
                            console.log("Returning to Home")
                            surfaceManager.switchToApplication(0)
                            return
                        }

                        if (surfaceManager.currentRightApp === appId) {
                            console.log("Already displaying", appName)
                            return
                        }

                        var isRunning = surfaceManager.isAppRunning(appId)
                        console.log("Is app running?", isRunning)

                        if (isRunning) {
                            console.log("App is running - switching to surface")
                            surfaceManager.switchToApplication(appId)
                        } else {
                            console.log("App not running - requesting launch with auto-switch")
                            surfaceManager.setPendingLaunch(appId)
                            requestAppLaunch(appId)
                            console.log("Launch requested for", appName)
                        }

                        console.log("=================================")
                    }
                }

                // Status overlay
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 5
                    width: 200
                    height: 95
                    color: "#80000000"
                    radius: 5

                    Column {
                        anchors.centerIn: parent
                        spacing: 3

                        Text {
                            text: "Nested Compositor"
                            color: "#00ff00"
                            font.pixelSize: 11
                            font.bold: true
                        }

                        Text {
                            text: "Socket: wayland-2"
                            color: "white"
                            font.pixelSize: 8
                        }

                        Text {
                            text: "Surfaces: " + surfaceManager.activeSurfaceCount
                            color: "white"
                            font.pixelSize: 9
                        }

                        Text {
                            text: "Active: " + getAppName(surfaceManager.currentRightApp)
                            color: "white"
                            font.pixelSize: 9
                        }
                    }
                }
            }
        }
    }

    defaultOutput: output

    // D-Bus communication functions
    function notifyAppConnected(iviId) {
        console.log("Notifying app connected:", iviId)
        dbusManager.notifyAppConnected(iviId)
    }

    function notifyAppDisconnected(iviId) {
        console.log("Notifying app disconnected:", iviId)
        dbusManager.notifyAppDisconnected(iviId)
    }

    function requestAppLaunch(iviId) {
        console.log("Requesting app launch:", iviId)
        dbusManager.launchApp(iviId)
    }

    function getAppName(iviId) {
        var names = {
            0: "Home",
            1001: "GearSelector",
            1002: "MediaPlayer",
            1003: "ThemeColor",
            1004: "Navigation",
            1005: "Settings"
        }
        return names[iviId] || "None"
    }

    Component.onCompleted: {
        console.log("=== HeadUnit Nested Compositor Ready ===")
        console.log("Our App-ID: ivi-compositor (to Weston)")
        console.log("Our Wayland Socket: wayland-2 (for apps)")
        console.log("Target Display: HDMI-A-1 via Weston")
        console.log("Resolution: 1024x600")
        console.log("Left panel: 200px")
        console.log("Right panel: 824px")
        console.log("========================================")

        // Launch GearSelector on startup
        console.log("Launching GearSelector")
        requestAppLaunch(1001)
    }
}