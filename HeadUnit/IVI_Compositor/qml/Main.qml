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

            // Notify lifecycle manager via D-Bus
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

                // Left panel - GearSelector
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

                        // Check if this is the currently displayed app
                        if (surfaceManager.currentRightApp === appId) {
                            console.log("Already displaying", appName)
                            return
                        }

                        // Check if application surface exists
                        var isRunning = surfaceManager.isAppRunning(appId)
                        console.log("Is app running?", isRunning)

                        if (isRunning) {
                            // Application is running, switch to it
                            console.log("App is running - switching to surface")
                            var success = surfaceManager.switchToApplication(appId)

                            if (success) {
                                console.log("Successfully switched to", appName)
                            } else {
                                console.error("Failed to switch to", appName)
                            }
                        } else {
                            // Application is not running, request launch
                            console.log("App not running - requesting launch")
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

    // D-Bus communication helper functions
    function notifyAppConnected(iviId) {
        dbusHelper.callMethod("AppConnected", iviId)
    }

    function notifyAppDisconnected(iviId) {
        dbusHelper.callMethod("AppDisconnected", iviId)
    }

    function requestAppLaunch(iviId) {
        dbusHelper.callMethod("LaunchApp", iviId)
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

    // D-Bus helper object
    QtObject {
        id: dbusHelper

        function callMethod(method, param) {
            var cmd = "dbus-send --session --type=method_call " +
                     "--dest=com.headunit.AppLifecycle " +
                     "/com/headunit/AppLifecycle " +
                     "com.headunit.AppLifecycle." + method +
                     " int32:" + param

            console.log("D-Bus call:", cmd)
        }
    }

    Component.onCompleted: {
        console.log("=== HeadUnit Compositor Ready ===")
        console.log("Socket: wayland-0")
        console.log("Resolution: 1024x600")
        console.log("Left panel: 300px")
        console.log("Right panel: 724px")
        console.log("=================================")
    }
}
