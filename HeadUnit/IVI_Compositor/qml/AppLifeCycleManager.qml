import QtQuick

QtObject {
    id: appLifecycle

    property var surfaceManager

    // Application launch configurations
    property var appConfigs: ({
        1001: {
            name: "GearSelector",
            path: "./applications/GearSelector",
            autoStart: true,
            persistent: true
        },
        1002: {
            name: "MediaPlayer",
            path: "./applications/MediaPlayer",
            autoStart: true,
            persistent: false
        },
        1003: {
            name: "ThemeColor",
            path: "./applications/ThemeColor",
            autoStart: false,
            persistent: false
        },
        1004: {
            name: "Navigation",
            path: "./applications/Navigation",
            autoStart: false,
            persistent: false
        },
        1005: {
            name: "YouTube",
            path: "./applications/YouTube",
            autoStart: false,
            persistent: false
        }
    })

    // Application states
    property var appStates: ({
        1001: "stopped",
        1002: "stopped",
        1003: "stopped",
        1004: "stopped",
        1005: "stopped"
    })

    // Launch initial applications
    function launchInitialApplications() {
        console.log("AppLifecycle: Initial applications should be launched via shell script")
        console.log("AppLifecycle: Compositor is ready to accept client connections")

        // Mark auto-start apps as expected
        for (var id in appConfigs) {
            var config = appConfigs[id]
            if (config.autoStart) {
                console.log("AppLifecycle: Expecting", config.name, "to connect with IVI-ID", id)
                appStates[id] = "expected"
            }
        }
    }

    // Handle surface created - called by SurfaceManager
    function handleSurfaceCreated(iviId) {
        console.log("AppLifecycle: Surface created for IVI-ID", iviId)
        appStates[iviId] = "running"
    }

    // Handle surface destroyed event
    function handleSurfaceDestroyed(iviId) {
        console.log("AppLifecycle: Handling surface destroyed for", iviId)

        var config = appConfigs[iviId]
        if (!config) {
            return
        }

        appStates[iviId] = "crashed"

        // Log crash for persistent applications
        if (config.persistent) {
            console.warn("AppLifecycle: Persistent application crashed:", config.name)
            console.warn("AppLifecycle: Please restart via shell script or systemd")
        }
    }

    // Get application state
    function getAppState(iviId) {
        return appStates[iviId] || "unknown"
    }

    // Get application config
    function getAppConfig(iviId) {
        return appConfigs[iviId] || null
    }

    // Check if app is running
    function isAppRunning(iviId) {
        return appStates[iviId] === "running"
    }

    // List all expected applications
    function listExpectedApps() {
        console.log("=== Expected Applications ===")
        for (var id in appConfigs) {
            var config = appConfigs[id]
            console.log("IVI-ID", id, ":", config.name,
                       "- Auto-start:", config.autoStart,
                       "- State:", appStates[id])
        }
        console.log("============================")
    }
}
