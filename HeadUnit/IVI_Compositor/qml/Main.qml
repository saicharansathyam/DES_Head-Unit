import QtQuick
import QtQuick.Window
import QtWayland.Compositor
import QtWayland.Compositor.IviApplication

WaylandCompositor {
    id: waylandCompositor

    socketName: "wayland-1"

    /*// Text Input Manager for virtual keyboard support
    TextInputManager {
        id: textInputManager
    }

    // QtTextInputMethodManager for Qt Virtual Keyboard integration
    QtTextInputMethodManager {
        id: qtTextInputMethodManager
    }*/

    // IVI Application extension
    IviApplication {
        id: iviApplication

        onIviSurfaceCreated: function(iviSurface) {
            console.log("IVI Surface created with ID:", iviSurface.iviId)
            surfaceManager.handleNewSurface(iviSurface)
            notifyAppConnected(iviSurface.iviId)
        }
    }

    // Surface manager
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

    // Wayland Output
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
            title: "HeadUnit IVI Compositor"
            flags: Qt.FramelessWindowHint

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

                        // Special handling for Home (appId = 0)
                        if (appId === 0) {
                            console.log("Returning to Home")
                            surfaceManager.switchToApplication(0)
                            return
                        }

                        // Check if this is the currently displayed app
                        if (surfaceManager.currentRightApp === appId) {
                            console.log("Already displaying", appName)
                            return
                        }

                        // Check if application surface exists
                        var isRunning = surfaceManager.isAppRunning(appId)
                        console.log("Is app running?", isRunning)

                        if (isRunning) {
                            // Application is running, switch to it immediately
                            console.log("App is running - switching to surface")
                            surfaceManager.switchToApplication(appId)
                        } else {
                            // Application is not running, request launch and mark for auto-switch
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
                    width: 180
                    height: 80
                    color: "#80000000"
                    radius: 5

                    Column {
                        anchors.centerIn: parent
                        spacing: 3

                        Text {
                            text: "HeadUnit"
                            color: "#00ff00"
                            font.pixelSize: 12
                            font.bold: true
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

    // D-Bus communication functions using DBusManager
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
        console.log("=== HeadUnit Compositor Ready ===")
        console.log("Socket: wayland-1")
        console.log("Resolution: 1024x600")
        console.log("Left panel: 200px")
        console.log("Right panel: 824px")
        console.log("Starting on: HomeView")
        console.log("Text Input Manager enabled")
        console.log("=================================")

        // Launch GearSelector on startup
        console.log("Launching GearSelector")
        requestAppLaunch(1001)
    }
}
