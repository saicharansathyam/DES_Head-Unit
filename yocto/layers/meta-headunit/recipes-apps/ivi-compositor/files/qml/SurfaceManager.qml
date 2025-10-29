// SurfaceManager.qml
import QtQuick
import QtWayland.Compositor

QtObject {
    id: surfaceManager

    // Properties
    property var compositor
    property var activeSurfaces: ({})  // IVI-ID → {surface, item}
    property int currentRightApp: 0    // Currently visible app on right panel
    property int activeSurfaceCount: 0
    property int pendingActivation: 0  // App waiting to be activated once surface created

    // Signals
    signal surfaceCreatedForLeft(var surface, var item)
    signal surfaceCreatedForRight(var surface, var item)
    signal surfaceDestroyed(int iviId)

    // Shell Surface Component
    property Component shellSurfaceComponent: Component {
        ShellSurfaceItem {
            id: surfaceItem
            property int iviId: shellSurface ? shellSurface.iviId : 0

            // Set initial size based on IVI-ID to avoid -1 values
            Component.onCompleted: {
                // Configure size BEFORE any other operations
                if (iviId === 1001) {
                    // GearSelector: Fits in left panel
                    width = 200
                    height = 440
                    console.log("Created GearSelector surface item - Size:", width, "x", height)
                } else {
                    // All other apps: Right panel size
                    width = 824
                    height = 550
                    console.log("Created app surface item for IVI-ID:", iviId, "- Size:", width, "x", height)
                }

                // Initial visibility: hide until explicitly shown
                visible = false

                // Send configure event to client
                if (shellSurface) {
                    console.log("Sending configure to IVI-ID:", iviId, "Size:", width, "x", height)
                    shellSurface.sendConfigure(Qt.size(width, height))
                }
            }

            // Handle surface destruction
            onSurfaceDestroyed: {
                console.log("Surface destroyed for IVI-ID:", iviId)
                surfaceManager.removeSurface(iviId)
            }

            // Auto-resize when surface updates (handle client resize requests)
            Connections {
                target: surfaceItem.surface

                function onSizeChanged() {
                    if (surfaceItem.iviId !== 1001) {
                        // Right panel apps
                        if (surfaceItem.surface.bufferSize.width > 0 &&
                            surfaceItem.surface.bufferSize.height > 0) {
                            console.log("Surface buffer size changed for IVI-ID:",
                                      surfaceItem.iviId,
                                      surfaceItem.surface.bufferSize)

                            // Only update if significantly different to avoid flicker
                            var newWidth = Math.min(surfaceItem.surface.bufferSize.width, 824)
                            var newHeight = Math.min(surfaceItem.surface.bufferSize.height, 550)

                            if (Math.abs(surfaceItem.width - newWidth) > 5 ||
                                Math.abs(surfaceItem.height - newHeight) > 5) {
                                surfaceItem.width = newWidth
                                surfaceItem.height = newHeight
                            }
                        }
                    }
                }
            }

            // Smooth fade animations
            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }

            Behavior on visible {
                NumberAnimation {
                    duration: 100
                    onRunningChanged: {
                        if (!running && !visible) {
                            opacity = 0
                        } else if (!running && visible) {
                            opacity = 1
                        }
                    }
                }
            }
        }
    }

    // PUBLIC METHODS

    /**
     * Handle new IVI surface creation
     * Called from Main.qml when IviApplication.onIviSurfaceCreated fires
     */
    function handleNewSurface(iviSurface) {
        var iviId = iviSurface.iviId
        console.log("=== SurfaceManager: Processing New Surface ===")
        console.log("IVI-ID:", iviId)
        console.log("App Name:", getAppName(iviId))

        // Check if surface already exists (shouldn't happen, but be safe)
        if (activeSurfaces[iviId]) {
            console.warn("Surface already exists for IVI-ID:", iviId, "- destroying old one")
            removeSurface(iviId)
        }

        // Create ShellSurfaceItem
        var item = shellSurfaceComponent.createObject(surfaceManager, {
            "shellSurface": iviSurface
        })

        if (!item) {
            console.error("CRITICAL: Failed to create ShellSurfaceItem for IVI-ID:", iviId)
            return
        }

        // Register surface
        activeSurfaces[iviId] = {
            surface: iviSurface,
            item: item
        }

        activeSurfaceCount = Object.keys(activeSurfaces).length
        console.log("Active surfaces count:", activeSurfaceCount)

        // Route to appropriate panel
        if (iviId === 1001) {
            // GearSelector → Left Panel
            console.log("Routing to LEFT panel (GearSelector)")
            surfaceCreatedForLeft(iviSurface, item)
            item.visible = true  // Always visible in left panel
            item.focus = true
        } else {
            // All other apps → Right Panel
            console.log("Routing to RIGHT panel")
            surfaceCreatedForRight(iviSurface, item)

            // Handle visibility and activation
            if (pendingActivation === iviId) {
                // This surface was requested to be activated
                console.log("Activating pending surface:", iviId)
                Qt.callLater(function() {
                    switchToApplication(iviId)
                })
            } else if (currentRightApp === 0 || !activeSurfaces[currentRightApp]) {
                // First app or current app doesn't exist - auto-switch
                console.log("Auto-switching to new app (first app or replacing missing app)")
                switchToApplication(iviId)
            } else if (currentRightApp === iviId) {
                // The current app just re-connected (shouldn't normally happen)
                console.log("Current app reconnected - showing it")
                item.visible = true
                item.focus = true
            } else {
                // App launched but not currently active - keep hidden
                console.log("App launched in background - keeping hidden")
                item.visible = false
            }
        }

        console.log("===========================================")
    }

    /**
     * Remove surface from management
     */
    function removeSurface(iviId) {
        console.log("Removing surface for IVI-ID:", iviId)

        if (!activeSurfaces[iviId]) {
            console.warn("Cannot remove - surface not found:", iviId)
            return
        }

        var surfaceData = activeSurfaces[iviId]

        // Destroy the item
        if (surfaceData.item) {
            surfaceData.item.destroy()
        }

        // Remove from registry
        delete activeSurfaces[iviId]
        activeSurfaceCount = Object.keys(activeSurfaces).length

        // Emit signal
        surfaceDestroyed(iviId)

        // If this was the current app, switch to another
        if (currentRightApp === iviId) {
            console.log("Current app was destroyed - finding alternative")

            // Try to find another running app
            var alternativeFound = false
            for (var id in activeSurfaces) {
                var numericId = parseInt(id)
                if (numericId !== 1001) {  // Skip GearSelector
                    console.log("Switching to alternative app:", numericId)
                    switchToApplication(numericId)
                    alternativeFound = true
                    break
                }
            }

            if (!alternativeFound) {
                console.log("No alternative apps - clearing current app")
                currentRightApp = 0
            }
        }

        console.log("Surface removed. Active surfaces:", activeSurfaceCount)
    }

    /**
     * Switch to specific application (context switch)
     * Handles both visibility and focus management
     */
    function switchToApplication(targetAppId) {
        console.log("=== SurfaceManager: Switch to Application ===")
        console.log("Target IVI-ID:", targetAppId)
        console.log("Target App:", getAppName(targetAppId))
        console.log("Current App:", currentRightApp, "(" + getAppName(currentRightApp) + ")")

        // Don't switch to GearSelector (it's in left panel)
        if (targetAppId === 1001) {
            console.warn("Cannot switch to GearSelector (left panel app)")
            return false
        }

        // Check if already showing this app
        if (currentRightApp === targetAppId) {
            console.log("Already displaying this app")

            // Even if visible, ensure proper focus
            var currItem = activeSurfaces[targetAppId]?.item
            if (currItem) {
                currItem.forceActiveFocus()

                // Ensure compositor keyboard focus
                if (compositor && compositor.defaultSeat && currItem.shellSurface) {
                    compositor.defaultSeat.setKeyboardFocus(currItem.shellSurface.surface)
                }
            }

            console.log("===========================================")
            return true
        }

        // Check if target surface exists
        if (!activeSurfaces[targetAppId]) {
            console.warn("Target app not running - marking as pending activation")
            pendingActivation = targetAppId
            console.log("===========================================")
            return false
        }

        // Hide current app
        if (currentRightApp !== 0 && activeSurfaces[currentRightApp]) {
            var currentItem = activeSurfaces[currentRightApp].item
            if (currentItem) {
                console.log("Hiding current app:", currentRightApp)
                currentItem.visible = false
                currentItem.opacity = 0
                currentItem.focus = false
            }
        }

        // Show target app
        var targetItem = activeSurfaces[targetAppId].item
        if (!targetItem) {
            console.error("Target surface item is null!")
            console.log("===========================================")
            return false
        }

        console.log("Showing target app:", targetAppId)
        targetItem.visible = true
        targetItem.opacity = 1
        targetItem.focus = true
        targetItem.forceActiveFocus()

        // Send configure to ensure correct size
        if (targetItem.shellSurface) {
            console.log("Reconfiguring surface size:", targetItem.width, "x", targetItem.height)
            targetItem.shellSurface.sendConfigure(Qt.size(targetItem.width, targetItem.height))
        }

        // // Set compositor keyboard focus
        // if (compositor && compositor.defaultSeat && targetItem.shellSurface) {
        //     console.log("Setting keyboard focus to target app")
        //     compositor.defaultSeat.setKeyboardFocus(targetItem.shellSurface.surface)
        // }

        // Update current app
        currentRightApp = targetAppId
        pendingActivation = 0  // Clear any pending activation

        console.log("Switch complete. Current app:", currentRightApp,
                   "(" + getAppName(currentRightApp) + ")")
        console.log("===========================================")
        return true
    }

    /**
     * Check if an application is currently running (has active surface)
     */
    function isAppRunning(iviId) {
        return activeSurfaces.hasOwnProperty(iviId)
    }

    /**
     * Get surface item for specific IVI-ID
     */
    function getSurfaceItem(iviId) {
        return activeSurfaces[iviId]?.item || null
    }

    /**
     * Get surface for specific IVI-ID
     */
    function getSurface(iviId) {
        return activeSurfaces[iviId]?.surface || null
    }

    /**
     * List all active application IDs
     */
    function getActiveApplications() {
        var apps = []
        for (var id in activeSurfaces) {
            apps.push(parseInt(id))
        }
        return apps
    }

    /**
     * Hide all applications in right panel (e.g., for showing compositor UI)
     */
    function hideAllRightPanelApps() {
        console.log("Hiding all right panel apps")

        for (var id in activeSurfaces) {
            var numericId = parseInt(id)
            if (numericId !== 1001) {  // Skip GearSelector
                var item = activeSurfaces[id].item
                if (item) {
                    item.visible = false
                    item.focus = false
                }
            }
        }
    }

    /**
     * Restore previously active app (after hiding all)
     */
    function restoreActiveApp() {
        if (currentRightApp !== 0) {
            console.log("Restoring active app:", currentRightApp)
            switchToApplication(currentRightApp)
        }
    }

    // HELPER FUNCTIONS

    /**
     * Get human-readable app name from IVI-ID
     */
    function getAppName(iviId) {
        var names = {
            1000: "HomePage",
            1001: "GearSelector",
            1002: "MediaPlayer",
            1003: "ThemeColor",
            1004: "Navigation",
            1005: "Settings"
        }
        return names[iviId] || "Unknown(" + iviId + ")"
    }

    /**
     * Debug: Print current state
     */
    function printState() {
        console.log("=== SurfaceManager State ===")
        console.log("Active surfaces:", activeSurfaceCount)
        console.log("Current right app:", currentRightApp, "(" + getAppName(currentRightApp) + ")")
        console.log("Pending activation:", pendingActivation, "(" + getAppName(pendingActivation) + ")")

        console.log("Surface registry:")
        for (var id in activeSurfaces) {
            var item = activeSurfaces[id].item
            console.log("  IVI-ID:", id,
                       "| Name:", getAppName(parseInt(id)),
                       "| Visible:", item ? item.visible : "null",
                       "| Size:", item ? (item.width + "x" + item.height) : "null")
        }
        console.log("============================")
    }

    // Component lifecycle
    Component.onCompleted: {
        console.log("SurfaceManager initialized")
    }

    // Monitor changes for debugging
    onActiveSurfaceCountChanged: {
        console.log("Active surface count changed:", activeSurfaceCount)
    }

    onCurrentRightAppChanged: {
        console.log("Current right app changed to:", currentRightApp,
                   "(" + getAppName(currentRightApp) + ")")
    }
}
