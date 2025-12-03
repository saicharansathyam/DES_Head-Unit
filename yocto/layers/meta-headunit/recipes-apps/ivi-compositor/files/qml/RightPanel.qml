import QtQuick
import QtWayland.Compositor

Rectangle {
    id: rightPanel

    color: "#1a1a1a"

    signal applicationSwitchRequested(int appId)

    // Main content area (above AppSwitcher)
    Item {
        id: contentArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: appSwitcher.top

        // HomeView as default view
        HomeView {
            id: homeView
            anchors.fill: parent
            visible: true  // Start visible
            z: 5

            onApplicationRequested: function(appId) {
                console.log("RightPanel: Application requested from HomeView:", appId)
                applicationSwitchRequested(appId)
            }
        }

        // Container for application surfaces (overlays HomeView)
        Item {
            id: surfaceContainer
            anchors.fill: parent
            z: 10
            visible: false  // Start hidden
        }
    }

    // AppSwitcher at bottom (always visible)
    AppSwitcher {
        id: appSwitcher
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 80

        onSwitchToApp: function(appId) {
            console.log("RightPanel: App switch requested from AppSwitcher:", appId)
            applicationSwitchRequested(appId)
        }
    }

    // Function to add surface to right panel
    function addSurface(surfaceItem) {
        console.log("RightPanel: Adding surface", surfaceItem.iviId)

        surfaceItem.parent = surfaceContainer
        surfaceItem.anchors.fill = surfaceContainer
        surfaceItem.z = 10

        console.log("RightPanel: Surface added")
    }

    // Function to show HomeView and hide all surfaces
    function showHome() {
        console.log("RightPanel: Showing HomeView")

        // Hide surface container
        surfaceContainer.visible = false

        // Show HomeView
        homeView.visible = true

        console.log("RightPanel: HomeView is now visible")
    }

    // Function to show a specific surface and hide HomeView
    function showSurface() {
        console.log("RightPanel: Showing surface container")

        // Hide HomeView
        homeView.visible = false

        // Show surface container
        surfaceContainer.visible = true

        console.log("RightPanel: Surface container is now visible")
    }

    Component.onCompleted: {
        console.log("RightPanel initialized")
        console.log("HomeView visible:", homeView.visible)
        console.log("SurfaceContainer visible:", surfaceContainer.visible)
    }
}
