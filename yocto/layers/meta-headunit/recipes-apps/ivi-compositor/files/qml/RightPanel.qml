import QtQuick
import QtWayland.Compositor

Rectangle {
    id: rightPanel

    color: "#1a1a1a"

    signal applicationSwitchRequested(int appId)

    // Container for application surfaces
    Item {
        id: surfaceContainer
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: appSwitcher.top

        // Placeholder when no app is active
        Text {
            anchors.centerIn: parent
            text: "No Application Active"
            color: "#808080"
            font.pixelSize: 20
            visible: surfaceContainer.children.length === 0
        }
    }

    // Application switcher at bottom
    AppSwitcher {
        id: appSwitcher
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 80

        onSwitchToApp: function(appId) {
            applicationSwitchRequested(appId)
        }
    }

    // Function to add surface to right panel
    function addSurface(surfaceItem) {
        console.log("Adding surface to right panel:", surfaceItem.shellSurface.iviId)

        surfaceItem.parent = surfaceContainer
        surfaceItem.anchors.fill = surfaceContainer
        surfaceItem.z = 10
    }
}

