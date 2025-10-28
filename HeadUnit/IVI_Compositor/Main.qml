import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtWayland.Compositor
import QtWayland.Compositor.XdgShell
import QtWayland.Compositor.WlShell
import IVI_Compositor 1.0

WaylandCompositor {
    id: compositor
    socketName: "wayland-1"
    
    property var items: []
    
    Component {
        id: surfaceItemComponent
        
        WaylandQuickItem {
            id: wqi
            
            // CRITICAL: Enable ALL input
            focusOnClick: true
            touchEventsEnabled: true
            inputEventsEnabled: true
            
            anchors.fill: parent
            clip: true
            
            property var buf: (surface && surface.size) ? surface.size : Qt.size(200, 600)
            property real scaleX: parent ? parent.width / Math.max(1, buf.width) : 1
            property real scaleY: parent ? parent.height / Math.max(1, buf.height) : 1
            property real uniformScale: Math.min(scaleX, scaleY, 1.0)
            
            width: buf.width
            height: buf.height
            scale: uniformScale
            transformOrigin: Item.Center
            anchors.centerIn: parent
            
            // CRITICAL: Grant focus when surface is ready
            Component.onCompleted: {
                if (surface) {
                    compositor.defaultSeat.keyboardFocus = surface
                }
            }
            
            onSurfaceChanged: {
                if (surface) {
                    console.log("Surface changed, granting focus")
                    compositor.defaultSeat.keyboardFocus = surface
                }
            }
            
            onSurfaceDestroyed: {
                var index = compositor.items.indexOf(wqi)
                if (index > -1) {
                    compositor.items.splice(index, 1)
                }
            }
        }
    }
    
    function placeItemByTitle(item, title, toplevelOrShell) {
        if (!title || title.length === 0)
            return false;
            
        if (title.indexOf("GearSelector") !== -1) {
            if (toplevelOrShell && toplevelOrShell.setMinSize) {
                var sz = Qt.size(leftPanel.width, leftPanel.height);
                toplevelOrShell.setMinSize(sz);
                toplevelOrShell.setMaxSize(sz);
                if (toplevelOrShell.sendConfigure)
                    toplevelOrShell.sendConfigure(sz, []);
            }
            item.parent = leftPanel;
            leftPlaceholder.visible = false;
            
            // CRITICAL: Grant focus when placed
            if (item.surface) {
                compositor.defaultSeat.keyboardFocus = item.surface
                console.log("GearSelector placed and focused")
            }
            return true;
        } else if (title.indexOf("MediaPlayer") !== -1) {
            item.parent = rightPanel;
            rightPlaceholder.visible = false;
            
            // CRITICAL: Grant focus when placed
            if (item.surface) {
                compositor.defaultSeat.keyboardFocus = item.surface
                console.log("MediaPlayer placed and focused")
            }
            return true;
        }
        return false;
    }
    
    function placeItemByWidth(item) {
        const wantLeft = item.width <= leftPanel.width + 20;
        const p = wantLeft ? leftPanel : rightPanel;
        if (item.parent !== p) {
            item.parent = p;
        }
        if (p === leftPanel) leftPlaceholder.visible = false;
        if (p === rightPanel) rightPlaceholder.visible = false;
    }
    
    XdgShell {
        id: xdg
        onToplevelCreated: function(toplevel, xdgSurface) {
            var item = surfaceItemComponent.createObject(rightPanel, { surface: xdgSurface.surface });
            if (!item)
                return;
                
            compositor.items.push(item);
            
            if (!placeItemByTitle(item, toplevel.title || "", toplevel)) {
                var tries = 0;
                var timer = Qt.createQmlObject(
                    'import QtQuick 2.15; Timer { interval: 120; repeat: true }',
                    compositor
                );
                timer.triggered.connect(function() {
                    tries++;
                    if (placeItemByTitle(item, toplevel.title || "", toplevel)) {
                        timer.stop(); timer.destroy();
                        return;
                    }
                    if (tries >= 10) {
                        placeItemByWidth(item);
                        timer.stop(); timer.destroy();
                    }
                });
                timer.start();
            }
        }
    }
    
    WlShell {
        id: wlshell
        onWlShellSurfaceCreated: function(wlShellSurface) {
            var s = wlShellSurface;
            var item = surfaceItemComponent.createObject(rightPanel, { surface: s.surface });
            if (!item)
                return;
                
            compositor.items.push(item);
            
            if (!placeItemByTitle(item, s.title || "", null)) {
                var tries = 0;
                var timer = Qt.createQmlObject(
                    'import QtQuick 2.15; Timer { interval: 120; repeat: true }',
                    compositor
                );
                timer.triggered.connect(function() {
                    tries++;
                    if (placeItemByTitle(item, s.title || "", null)) {
                        timer.stop(); timer.destroy();
                        return;
                    }
                    if (tries >= 10) {
                        placeItemByWidth(item);
                        timer.stop(); timer.destroy();
                    }
                });
                timer.start();
            }
        }
    }
    
    WaylandOutput {
        id: output
        sizeFollowsWindow: true
        
        window: Window {
            id: mainWindow
            width: 1024
            height: 600
            visible: true
            color: "#0f172a"
            title: "IVI Compositor - HeadUnit"
            
            Row {
                anchors.fill: parent
                
                // Left Panel - GearSelector
                Rectangle {
                    id: leftPanel
                    width: 200
                    height: parent.height
                    color: "#111827"
                    clip: true
                    
                    // CRITICAL: Don't block mouse/touch events
                    MouseArea {
                        anchors.fill: parent
                        propagateComposedEvents: true
                        onPressed: function(mouse) { mouse.accepted = false }
                        onReleased: function(mouse) { mouse.accepted = false }
                    }
                    
                    Rectangle {
                        id: leftPlaceholder
                        anchors.fill: parent
                        visible: true
                        color: "transparent"
                        
                        Column {
                            anchors.centerIn: parent
                            spacing: 10
                            Text { text: "GearSelector"; color: "#4b5563"; font.pixelSize: 14; font.bold: true }
                            Text { text: "Not Connected"; color: "#374151"; font.pixelSize: 10 }
                        }
                    }
                }
                
                Rectangle { width: 2; height: parent.height; color: "#1e293b" }
                
                // Right Panel - MediaPlayer
                Rectangle {
                    id: rightPanel
                    width: parent.width - leftPanel.width - 2
                    height: parent.height
                    color: "#1e293b"
                    clip: true
                    
                    // CRITICAL: Don't block mouse/touch events
                    MouseArea {
                        anchors.fill: parent
                        propagateComposedEvents: true
                        onPressed: function(mouse) { mouse.accepted = false }
                        onReleased: function(mouse) { mouse.accepted = false }
                    }
                    
                    Rectangle {
                        id: rightPlaceholder
                        anchors.fill: parent
                        visible: true
                        color: "transparent"
                        
                        Column {
                            anchors.centerIn: parent
                            spacing: 10
                            Text { text: "MediaPlayer"; color: "#64748b"; font.pixelSize: 18; font.bold: true }
                            Text { text: "Not Connected"; color: "#475569"; font.pixelSize: 12 }
                        }
                    }
                }
            }
            
            // Status bar
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 28
                color: "#0f172a"
                
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    spacing: 16
                    Text { text: "Clients: " + compositor.items.length; color: "#94a3b8"; font.pixelSize: 12 }
                    Text { text: "Socket: " + compositor.socketName; color: "#64748b"; font.pixelSize: 12 }
                }
            }
        }
    }
}