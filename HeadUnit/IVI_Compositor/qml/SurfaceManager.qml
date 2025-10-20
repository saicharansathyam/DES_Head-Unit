import QtQuick
import QtWayland.Compositor

QtObject {
    id: surfaceManager

    property var compositor
    property var activeSurfaces: ({})
    property int currentRightApp: 1000  // Default to HomePage
    property int activeSurfaceCount: 0

    signal surfaceCreatedForLeft(var surface, var item)
    signal surfaceCreatedForRight(var surface, var item)
    signal surfaceDestroyed(int iviId)

    property Component shellSurfaceComponent: Component {
        ShellSurfaceItem {
            id: surfaceItem
            property int iviId: shellSurface ? shellSurface.iviId : 0

            // Set proper width based on panel
            width: iviId === 1001 ? 300 : 724
            height: 600

            // Note: sizeFollowsSurface doesn't exist - removed

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
                console.log("ShellSurfaceItem created for IVI-ID", iviId,
                           "Size:", width, "x", height)

                if (shellSurface) {
                    shellSurface.sendConfigure(Qt.size(width, height))
                }
            }

            onWidthChanged: {
                if (shellSurface) {
                    shellSurface.sendConfigure(Qt.size(width, height))
                }
            }

            onHeightChanged: {
                if (shellSurface) {
                    shellSurface.sendConfigure(Qt.size(width, height))
                }
            }
        }
    }

    // Check if application is running
    function isAppRunning(iviId) {
        return activeSurfaces.hasOwnProperty(iviId)
    }

    // Get application surface item
    function getAppSurfaceItem(iviId) {
        if (activeSurfaces[iviId]) {
            return activeSurfaces[iviId].item
        }
        return null
    }

    // Get application surface
    function getAppSurface(iviId) {
        if (activeSurfaces[iviId]) {
            return activeSurfaces[iviId].surface
        }
        return null
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
            surfaceCreatedForLeft(iviSurface, item)
        } else {
            surfaceCreatedForRight(iviSurface, item)

            // Auto-switch to newly launched app if no app is currently shown
            if (currentRightApp === 0 || !activeSurfaces[currentRightApp]) {
                console.log("Auto-switching to newly launched app:", iviId)
                currentRightApp = iviId
            } else {
                // Switch to the newly launched app
                console.log("Switching to newly launched app:", iviId)
                switchToApplication(iviId)
            }
        }
    }

    function switchToApplication(targetAppId) {
        console.log("SurfaceManager: Switching to app:", targetAppId)

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

        // Hide current app
        if (activeSurfaces[currentRightApp]) {
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
            targetItem.visible = true
            targetItem.focus = true
            targetItem.forceActiveFocus()

            // Ensure proper size is sent
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

            // If the destroyed app was the current one, switch to another
            if (iviId === currentRightApp) {
                console.log("Current app destroyed, switching to fallback")

                // Try HomePage first
                if (activeSurfaces[1000]) {
                    switchToApplication(1000)
                } else {
                    // Otherwise find first available
                    var firstApp = findFirstAvailableApp()
                    if (firstApp !== 0) {
                        switchToApplication(firstApp)
                    } else {
                        currentRightApp = 0
                        console.log("No apps available")
                    }
                }
            }

            surfaceDestroyed(iviId)
        }
    }

    function findFirstAvailableApp() {
        // Priority order: HomePage, MediaPlayer, others
        var priority = [1000, 1002, 1003, 1004, 1005]

        for (var i = 0; i < priority.length; i++) {
            var iviId = priority[i]
            if (activeSurfaces[iviId]) {
                console.log("Found fallback app:", iviId)
                return iviId
            }
        }

        // If priority apps not found, return any available app
        for (var id in activeSurfaces) {
            var appId = parseInt(id)
            if (appId !== 1001 && appId !== 0) {
                console.log("Found any available app:", appId)
                return appId
            }
        }

        return 0
    }

    // Get list of running applications
    function getRunningApps() {
        var running = []
        for (var id in activeSurfaces) {
            var appId = parseInt(id)
            if (appId !== 1001) {  // Exclude GearSelector
                running.push(appId)
            }
        }
        return running
    }
}
