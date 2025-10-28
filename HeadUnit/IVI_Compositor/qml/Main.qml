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
                            console.log("App is running - switching to surface")
                            var success = surfaceManager.switchToApplication(appId)

                            if (success) {
                                console.log("Successfully switched to", appName)
                            } else {
                                console.error("Failed to switch to", appName)
                            }
                        } else {
                            console.log("App not running - requesting launch via D-Bus")
                            requestAppLaunch(appId)
                            console.log("Launch requested for", appName)
                        }

                        console.log("=================================")
                    }
                }

                // Status overlay (updated position to avoid Clock)
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

    // Public function to update temperature from external source
    function updateTemperature(temp) {
        if (output.window.leftPanel) {
            output.window.leftPanel.setTemperature(temp)
        }
    }

    // Public function to set time format
    function setTimeFormat(is24Hour) {
        if (output.window.leftPanel) {
            output.window.leftPanel.setTimeFormat(is24Hour)
        }
    }

    // D-Bus communication functions
    function notifyAppConnected(iviId) {
        console.log("Notifying app connected:", iviId)
        if (typeof scriptExecutor !== 'undefined') {
            scriptExecutor.executeDBusCall("AppConnected", iviId)
        }
    }

    function notifyAppDisconnected(iviId) {
        console.log("Notifying app disconnected:", iviId)
        if (typeof scriptExecutor !== 'undefined') {
            scriptExecutor.executeDBusCall("AppDisconnected", iviId)
        }
    }

    function requestAppLaunch(iviId) {
        console.log("Requesting app launch:", iviId)
        if (typeof scriptExecutor !== 'undefined') {
            scriptExecutor.executeDBusCall("LaunchApp", iviId)
        }
    }

    function getAppName(iviId) {
        var names = {
            1000: "HomePage",
            1001: "GearSelector",
            1002: "MediaPlayer",
            1003: "ThemeColor",
            1004: "Navigation",
            1005: "YouTube"
        }
        return names[iviId] || "None"
    }

    Component.onCompleted: {
        console.log("=== HeadUnit Compositor Ready ===")
        console.log("Socket: wayland-1")
        console.log("Resolution: 1024x600")
        console.log("Left panel: 200px (Clock + Temp + Gear)")
        console.log("Right panel: 824px")
        console.log("=================================")
    }
}
