// Main.qml
import QtQuick
import QtQuick.Window
import QtWayland.Compositor
import QtWayland.Compositor.IviApplication

WaylandCompositor {
    id: waylandCompositor
    socketName: "wayland-1"

    // IVI Application extension
    IviApplication {
        id: iviApplication

        onIviSurfaceCreated: function(iviSurface) {
            console.log("IVI Surface created with ID:", iviSurface.iviId)
            surfaceManager.handleNewSurface(iviSurface)

            // Notify AFM via native D-Bus (not shell script)
            dbusManager.notifyAppConnected(iviSurface.iviId)
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
            dbusManager.notifyAppDisconnected(iviId)
        }
    }

    // Connect to AFM signals
    Connections {
        target: dbusManager

        function onAppLaunched(iviId, runId) {
            console.log("[Compositor] AFM launched app:", iviId, "RunID:", runId)
            // Surface will arrive via IVI protocol
        }

        function onAppTerminated(iviId) {
            console.log("[Compositor] AFM terminated app:", iviId)
            // Surface destruction handled by surfaceManager
        }

        function onAppStateChanged(iviId, state) {
            console.log("[Compositor] App state changed:", iviId, "->", state)

            // If app became "active", bring to foreground
            if (state === "active" && surfaceManager.isAppRunning(iviId)) {
                console.log("[Compositor] Activating app surface:", iviId)
                surfaceManager.switchToApplication(iviId)
            }
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

                // Right panel - Switchable apps
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

                        if (surfaceManager.currentRightApp === appId) {
                            console.log("Already displaying", appName)
                            return
                        }

                        var isRunning = surfaceManager.isAppRunning(appId)
                        console.log("Is app running?", isRunning)

                        if (isRunning) {
                            console.log("App is running - activating via AFM")
                            // Request activation through AFM for proper window management
                            dbusManager.activateApp(appId)
                            // AFM will signal back with appStateChanged("active")
                            // which will trigger surfaceManager.switchToApplication
                        } else {
                            console.log("App not running - requesting launch via AFM")
                            dbusManager.launchApp(appId)
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
                    height: 100
                    color: "#80000000"
                    radius: 5
                    visible: dbusManager.afmConnected

                    Column {
                        anchors.centerIn: parent
                        spacing: 3

                        Text {
                            text: "HeadUnit"
                            color: dbusManager.afmConnected ? "#00ff00" : "#ff0000"
                            font.pixelSize: 12
                            font.bold: true
                        }

                        Text {
                            text: "AFM: " + (dbusManager.afmConnected ? "Connected" : "Disconnected")
                            color: "white"
                            font.pixelSize: 9
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

    // Helper functions
    function getAppName(iviId) {
        var names = {
            1000: "HomePage",
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
        console.log("Left panel: 200px (Clock + Temp + Gear)")
        console.log("Right panel: 824px")
        console.log("AFM Connected:", dbusManager.afmConnected)
        console.log("=================================")
    }
}
