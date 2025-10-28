import QtQuick
import QtQuick.Window
import QtWayland.Compositor.IviApplication

Window {
    id: mainWindow
    width: 824
    height: 600
    visible: true
    title: "Settings Application"

    color: "#2a2a2a"

    // Main container
    Rectangle {
        id: container
        anchors.fill: parent
        color: "#2a2a2a"

        // Left side menu
        SettingsMenu {
            id: settingsMenu
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 200

            currentContext: settingsManager.currentContext

            onContextSelected: function(context) {
                settingsManager.switchContext(context)
            }
        }

        // Right side content area
        Rectangle {
            id: contentArea
            anchors.left: settingsMenu.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: 2
            color: "#1a1a1a"

            // Context switcher
            Loader {
                id: contentLoader
                anchors.fill: parent
                anchors.margins: 20

                source: {
                    switch(settingsManager.currentContext) {
                        case "wifi":
                            return "WiFiSettings.qml"
                        case "bluetooth":
                            return "BluetoothSettings.qml"
                        case "sound":
                            return "SoundSettings.qml"
                        default:
                            return "WiFiSettings.qml"
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        console.log("Settings Application UI loaded")
        console.log("Current context:", settingsManager.currentContext)
    }
}

