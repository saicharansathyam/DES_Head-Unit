import QtQuick
import QtWayland.Compositor

QtObject {
    id: surfaceManager

    property var compositor
    property var activeSurfaces: ({})
    property int currentRightApp: 0  // Start at 0 = HomeView
    property int activeSurfaceCount: 0
    property int pendingLaunchAppId: 0  // NEW: Track app being launched for auto-switch

    signal surfaceCreatedForLeft(var surface, var item)
    signal surfaceCreatedForRight(var surface, var item)
    signal surfaceDestroyed(int iviId)

    property Component shellSurfaceComponent: Component {
        ShellSurfaceItem {
            id: surfaceItem
            property int iviId: shellSurface ? shellSurface.iviId : 0

            // FIXED: Use property bindings to avoid -1 width issue
            width: {
                if (iviId === 1001) return 200
                return 824
            }

            height: {
                if (iviId === 1001) return 415
                return 470  // 550 - 80 for AppSwitcher
            }

            visible: {
                if (iviId === 1001) return true  // GearSelector always visible
                return iviId === surfaceManager.currentRightApp
            }

            Behavior on opacity {
                NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
            }

            opacity: visible ? 1.0 : 0.0
            enabled: visible
            focus: visible

            onSurfaceDestroyed: {
                console.log("Surface destroyed:", iviId)
                surfaceManager.handleSurfaceDestroyed(iviId)
                destroy()
            }

            Component.onCompleted: {
                console.log("ShellSurfaceItem completed for IVI-ID", iviId, "Size:", width, "x", height)

                if (shellSurface && width > 0 && height > 0) {
                    shellSurface.sendConfigure(Qt.size(width, height))
                }
            }

            onWidthChanged: {
                if (shellSurface && width > 0 && height > 0) {
                    console.log("Width changed for IVI-ID", iviId, "to", width)
                    shellSurface.sendConfigure(Qt.size(width, height))
                }
            }

            onHeightChanged: {
                if (shellSurface && height > 0 && width > 0) {
                    console.log("Height changed for IVI-ID", iviId, "to", height)
                    shellSurface.sendConfigure(Qt.size(width, height))
                }
            }
        }
    }

    function isAppRunning(iviId) {
        return activeSurfaces.hasOwnProperty(iviId)
    }

    function getAppSurfaceItem(iviId) {
        if (activeSurfaces[iviId]) {
            return activeSurfaces[iviId].item
        }
        return null
    }

    function getAppSurface(iviId) {
        if (activeSurfaces[iviId]) {
            return activeSurfaces[iviId].surface
        }
        return null
    }

    // NEW: Mark an app as pending launch for auto-switch
    function setPendingLaunch(iviId) {
        console.log("SurfaceManager: Setting pending launch for app:", iviId)
        pendingLaunchAppId = iviId
    }

    function handleNewSurface(iviSurface) {
        var iviId = iviSurface.iviId
        console.log("SurfaceManager: New surface", iviId)

        var item = shellSurfaceComponent.createObject(surfaceManager, {
            "shellSurface": iviSurface
        })

        if (!item) {
            console.error("Failed to create ShellSurfaceItem")
            return
        }

        activeSurfaces[iviId] = {
            surface: iviSurface,
            item: item
        }

        activeSurfaceCount = Object.keys(activeSurfaces).length

        if (iviId === 1001) {
            // GearSelector goes to left panel
            surfaceCreatedForLeft(iviSurface, item)
        } else {
            // Other apps go to right panel
            surfaceCreatedForRight(iviSurface, item)

            // NEW: Auto-switch if this was the pending app
            if (iviId === pendingLaunchAppId) {
                console.log("SurfaceManager: Pending app", iviId, "surface created - auto-switching")
                Qt.callLater(function() {
                    switchToApplication(iviId)
                })
                pendingLaunchAppId = 0  // Clear pending
            } else {
                console.log("Surface ready for app", iviId, "- staying on current view")
            }
        }
    }

    function switchToApplication(targetAppId) {
        console.log("SurfaceManager: Switching to app:", targetAppId)

        // Special case: 0 means return to HomeView
        if (targetAppId === 0) {
            console.log("Switching to HomeView")

            // Hide all app surfaces
            for (var id in activeSurfaces) {
                var appId = parseInt(id)
                if (appId !== 1001 && activeSurfaces[id].item) {
                    activeSurfaces[id].item.visible = false
                    activeSurfaces[id].item.focus = false
                }
            }

            // Tell RightPanel to show HomeView
            if (compositor && compositor.defaultOutput && compositor.defaultOutput.window) {
                var rightPanel = compositor.defaultOutput.window.rightPanel
                if (rightPanel) {
                    rightPanel.showHome()
                }
            }

            currentRightApp = 0
            console.log("Now showing: HomeView")
            return true
        }

        // Check if already showing this app
        if (currentRightApp === targetAppId) {
            console.log("Already showing app:", targetAppId)
            return true
        }

        // Check if app is running
        if (!activeSurfaces[targetAppId]) {
            console.warn("Cannot switch - app not running:", targetAppId)
            return false
        }

        // Hide current app (if not Home)
        if (currentRightApp !== 0 && activeSurfaces[currentRightApp]) {
            var currentItem = activeSurfaces[currentRightApp].item
            if (currentItem) {
                console.log("Hiding current app:", currentRightApp)
                currentItem.visible = false
                currentItem.focus = false
            }
        }

        // Show target app
        var targetItem = activeSurfaces[targetAppId].item
        if (targetItem) {
            console.log("Showing target app:", targetAppId)

            // Tell RightPanel to show surface container
            if (compositor && compositor.defaultOutput && compositor.defaultOutput.window) {
                var rightPanelWin = compositor.defaultOutput.window.rightPanel
                if (rightPanelWin) {
                    rightPanelWin.showSurface()
                }
            }

            targetItem.visible = true
            targetItem.focus = true
            targetItem.forceActiveFocus()

            if (targetItem.shellSurface) {
                targetItem.shellSurface.sendConfigure(
                    Qt.size(targetItem.width, targetItem.height)
                )
            }
        }

        currentRightApp = targetAppId
        console.log("Switch complete. Current app is now:", currentRightApp)
        return true
    }

    function handleSurfaceDestroyed(iviId) {
        if (activeSurfaces[iviId]) {
            console.log("SurfaceManager: Handling surface destruction for", iviId)

            delete activeSurfaces[iviId]
            activeSurfaceCount = Object.keys(activeSurfaces).length

            // If the destroyed app was the current one, return to Home
            if (iviId === currentRightApp) {
                console.log("Current app destroyed, returning to HomeView")
                switchToApplication(0)
            }

            // Clear pending if it was this app
            if (iviId === pendingLaunchAppId) {
                pendingLaunchAppId = 0
            }

            surfaceDestroyed(iviId)
        }
    }

    function findFirstAvailableApp() {
        var priority = [1002, 1003, 1004, 1005]

        for (var i = 0; i < priority.length; i++) {
            var iviId = priority[i]
            if (activeSurfaces[iviId]) {
                console.log("Found fallback app:", iviId)
                return iviId
            }
        }

        for (var id in activeSurfaces) {
            var appId = parseInt(id)
            if (appId !== 1001 && appId !== 0) {
                console.log("Found any available app:", appId)
                return appId
            }
        }

        return 0
    }

    function getRunningApps() {
        var running = []
        for (var id in activeSurfaces) {
            var appId = parseInt(id)
            if (appId !== 1001) {
                running.push(appId)
            }
        }
        return running
    }
}
