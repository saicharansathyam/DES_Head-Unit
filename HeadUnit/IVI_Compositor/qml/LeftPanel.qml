import QtQuick
import QtWayland.Compositor

Rectangle {
    id: leftPanel

    color: "#2d2d2d"

    // Border separator
    Rectangle {
        anchors.right: parent.right
        width: 2
        height: parent.height
        color: "#404040"
    }

    // Container for GearSelector surface
    Item {
        id: gearSelectorContainer
        anchors.fill: parent
        anchors.margins: 0
    }

    // Function to add GearSelector surface
    function addSurface(surfaceItem) {
        console.log("Adding surface to left panel")

        surfaceItem.parent = gearSelectorContainer
        surfaceItem.anchors.fill = gearSelectorContainer
        surfaceItem.anchors.topMargin = header.height
        surfaceItem.visible = true
        surfaceItem.z = 10
    }

    // Placeholder when no surface is present
    Text {
        anchors.centerIn: parent
        text: "Waiting for\nGearSelector..."
        color: "#808080"
        font.pixelSize: 16
        horizontalAlignment: Text.AlignHCenter
        visible: gearSelectorContainer.children.length === 0
    }
}

