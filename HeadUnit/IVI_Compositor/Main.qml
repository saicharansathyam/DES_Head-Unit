import QtQuick
import QtQuick.Controls
import QtWayland.Compositor
import QtWayland.Compositor.XdgShell
import QtWayland.Compositor.WlShell
import QtQuick.Window

WaylandCompositor {
    id: compositor

    // List to track surfaces
    property var surfaces: []

    // Handle xdg-shell surfaces
    XdgShell {
        onToplevelCreated: (toplevel, xdgSurface) => {
            console.log("XdgSurface created with title:", xdgSurface.toplevel.title)
            let surfaceItem = surfaceItemComponent.createObject(
                xdgSurface.toplevel.title === "GearSelector" ? leftArea : rightArea,
                {"shellSurface": xdgSurface}
            )
            if (!surfaceItem) {
                console.error("Failed to create ShellSurfaceItem for surface")
                return
            }
            surfaceItem.sizeFollowsSurface = true
            surfaces.push(surfaceItem)
        }
    }

    // Component to render Wayland surfaces
    Component {
        id: surfaceItemComponent
        ShellSurfaceItem {
            anchors.fill: parent
        }
    }

    WaylandOutput {
        sizeFollowsWindow: true
        window: Window {
            width: 1200
            height: 600
            visible: true
            title: "IVI Compositor"

            Rectangle {
                id: leftArea
                width: 200
                height: parent.height
                anchors.left: parent.left
                color: "cornflowerblue"
                Text {
                    anchors.centerIn: parent
                    text: "GearSelector Surface"
                    color: "white"
                }
            }
            Rectangle {
                id: rightArea
                width: 1000
                height: parent.height
                anchors.right: parent.right
                color: "burlywood"
                Text {
                    anchors.centerIn: parent
                    text: "MediaPlayer Surface"
                    color: "black"
                }
            }
        }
    }
}
