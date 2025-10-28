import QtQuick

QtObject {
    id: globalState

    // Shared state properties
    property string currentGear: "P"
    property string themeColor: "#FF0000"
    property int vehicleSpeed: 0
    property bool engineRunning: false
    property int ambientTemperature: 22

    // Application-specific state
    property string currentMediaTrack: ""
    property bool mediaPlaying: false
    property string navigationDestination: ""

    // Custom signals (NOT named like property change signals)
    signal gearUpdated(string gear)
    signal themeUpdated(string color)
    signal speedUpdated(int speed)
    signal engineStateUpdated(bool running)

    // Handle state changes using property change handlers
    onCurrentGearChanged: {
        console.log("GlobalState: Gear changed to", currentGear)
        gearUpdated(currentGear)
    }

    onThemeColorChanged: {
        console.log("GlobalState: Theme color changed to", themeColor)
        themeUpdated(themeColor)
    }

    onVehicleSpeedChanged: {
        console.log("GlobalState: Speed changed to", vehicleSpeed)
        speedUpdated(vehicleSpeed)
    }

    onEngineRunningChanged: {
        console.log("GlobalState: Engine", engineRunning ? "started" : "stopped")
        engineStateUpdated(engineRunning)
    }

    // Helper functions
    function updateGear(gear) {
        currentGear = gear
    }

    function updateThemeColor(color) {
        themeColor = color
    }

    function updateSpeed(speed) {
        vehicleSpeed = speed
    }

    function setEngineState(running) {
        engineRunning = running
    }

    // Debug function
    function printState() {
        console.log("=== Global State ===")
        console.log("Gear:", currentGear)
        console.log("Theme Color:", themeColor)
        console.log("Speed:", vehicleSpeed, "km/h")
        console.log("Engine:", engineRunning ? "ON" : "OFF")
        console.log("Temperature:", ambientTemperature, "°C")
        console.log("==================")
    }
}
