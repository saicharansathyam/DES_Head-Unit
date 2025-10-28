import QtQuick
import QtWayland.Compositor
import QtWayland.Compositor.XdgShell

WaylandCompositor {
    id: comp
    
    WaylandOutput {
        sizeFollowsWindow: true
        window: Window {
            id: win
            width: 800
            height: 480
            visible: true
            color: "black"
            
            Text {
                text: "Touch Test | Waiting for client..."
                color: "white"
                font.pixelSize: 20
                anchors.centerIn: parent
                visible: shellSurfaces.count === 0
            }
            
            Repeater {
                model: shellSurfaces
                
                ShellSurfaceItem {
                    shellSurface: modelData
                    anchors.fill: parent
                    touchEventsEnabled: true
                    inputEventsEnabled: true
                    
                    onSurfaceDestroyed: {
                        shellSurfaces.remove(index)
                    }
                }
            }
        }
    }

    ListModel { id: shellSurfaces }

    XdgShell {
        onToplevelCreated: function(toplevel, xdgSurface) {
            console.log("Client connected")
            shellSurfaces.append({shellSurface: xdgSurface})
            // DON'T call sendFullscreen - let Qt handle it
        }
    }
    
    Component.onCompleted: {
        console.log("Compositor ready")
    }
}
