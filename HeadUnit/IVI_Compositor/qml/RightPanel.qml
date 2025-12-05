import QtQuick
import QtWayland.Compositor
import QtQuick.VirtualKeyboard

Rectangle {
    id: rightPanel

    color: "#1a1a1a"

    signal applicationSwitchRequested(int appId)

    // Main content area (above AppSwitcher, adjusted for keyboard)
    Item {
        id: contentArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: appSwitcher.top

        // Content viewport - adjusts when keyboard appears
        Item {
            id: contentViewport
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: inputPanel.active ? inputPanel.height : 0

            Behavior on anchors.bottomMargin {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.InOutQuad
                }
            }

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

        /*// Virtual Keyboard with background
        Item {
            id: keyboardContainer
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: inputPanel.height
            z: 1000
            visible: inputPanel.active

            // Background
            Rectangle {
                anchors.fill: parent
                color: "#2d2d2d"
                opacity: 0.98

                // Top border
                Rectangle {
                    anchors.top: parent.top
                    width: parent.width
                    height: 2
                    color: theme.accentColor
                }
            }

            // The actual InputPanel
            InputPanel {
                id: inputPanel
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                // Make it respond to the compositor's window
                active: Qt.inputMethod.visible

                onActiveChanged: {
                    console.log("InputPanel active changed:", active)
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.InOutQuad
                }
            }
        }*/
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
        console.log("RightPanel initialized with Virtual Keyboard support")
        console.log("HomeView visible:", homeView.visible)
        console.log("SurfaceContainer visible:", surfaceContainer.visible)
    }
}
