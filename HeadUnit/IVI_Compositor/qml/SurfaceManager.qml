import QtQuick
import QtWayland.Compositor

QtObject {
    id: surfaceManager

    property var compositor
    property var activeSurfaces: ({})
    property int currentRightApp: 1000
    property int activeSurfaceCount: 0

    signal surfaceCreatedForLeft(var surface, var item)
    signal surfaceCreatedForRight(var surface, var item)
    signal surfaceDestroyed(int iviId)

    property Component shellSurfaceComponent: Component {
        ShellSurfaceItem {
            id: surfaceItem
            property int iviId: shellSurface ? shellSurface.iviId : 0

            // IMPORTANT: Set explicit initial size to avoid -1 values
            Component.onCompleted: {
                // Set size based on IVI-ID BEFORE any other operations
                if (iviId === 1001) {
                    width = 200
                    height = 440
                } else {
                    width = 824
                    height = 550
                }

                console.log("ShellSurfaceItem: Initial size set for IVI-ID", iviId, ":", width, "x", height)

                // Now send configure to client
                if (shellSurface) {
                    shellSurface.sendConfigure(Qt.size(width, height))
                }
            }

            visible: {
                if (iviId === 1001) return true
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

            onWidthChanged: {
                if (shellSurface && width > 0) {
                    console.log("Width changed for IVI-ID", iviId, "to", width)
                    shellSurface.sendConfigure(Qt.size(width, height))
                }
            }

            onHeightChanged: {
                if (shellSurface && height > 0) {
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

            if (currentRightApp === 0 || !activeSurfaces[currentRightApp]) {
                console.log("Auto-switching to newly launched app:", iviId)
                currentRightApp = iviId
            } else {
                console.log("Switching to newly launched app:", iviId)
                switchToApplication(iviId)
            }
        }
    }

    function switchToApplication(targetAppId) {
        console.log("SurfaceManager: Switching to app:", targetAppId)

        if (currentRightApp === targetAppId) {
            console.log("Already showing app:", targetAppId)
            return true
        }

        if (!activeSurfaces[targetAppId]) {
            console.warn("Cannot switch - app not running:", targetAppId)
            return false
        }

        if (activeSurfaces[currentRightApp]) {
            var currentItem = activeSurfaces[currentRightApp].item
            if (currentItem) {
                console.log("Hiding current app:", currentRightApp)
                currentItem.visible = false
                currentItem.focus = false
            }
        }

        var targetItem = activeSurfaces[targetAppId].item
        if (targetItem) {
            console.log("Showing target app:", targetAppId)
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

            if (iviId === currentRightApp) {
                console.log("Current app destroyed, switching to fallback")

                if (activeSurfaces[1000]) {
                    switchToApplication(1000)
                } else {
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
        var priority = [1000, 1002, 1003, 1004, 1005]

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
