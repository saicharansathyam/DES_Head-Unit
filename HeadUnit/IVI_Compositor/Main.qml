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

    // Optional: track all items
    property var items: []

    //
    // ---- View for a client surface (with proper scaling) ----
    //
    Component {
        id: surfaceItemComponent

        WaylandQuickItem {
            id: wqi
            // pass: surface: when creating
            focusOnClick: true
            touchEventsEnabled: true
            anchors.fill: parent
            clip: true

            // live buffer size (fallback fits sidebar)
            property var buf: (surface && surface.size) ? surface.size : Qt.size(200, 600)

            // Calculate scaling factor to fit content within parent while maintaining aspect ratio
            property real scaleX: parent ? parent.width / Math.max(1, buf.width) : 1
            property real scaleY: parent ? parent.height / Math.max(1, buf.height) : 1
            property real uniformScale: Math.min(scaleX, scaleY, 1.0) // Don't scale up, only down

            // Set size to original buffer size
            width: buf.width
            height: buf.height

            // Apply uniform scaling
            scale: uniformScale

            // Center the scaled item
            transformOrigin: Item.Center
            anchors.centerIn: parent
        }
    }

    //
    // ---- Helper: place item by title (GearSelector → left, MediaPlayer → right) ----
    //
    function placeItemByTitle(item, title, toplevelOrShell) {
        if (!title || title.length === 0)
            return false;

        if (title.indexOf("GearSelector") !== -1) {
            // clamp GearSelector to sidebar and move left
            if (toplevelOrShell && toplevelOrShell.setMinSize) {
                var sz = Qt.size(leftPanel.width, leftPanel.height);
                toplevelOrShell.setMinSize(sz);
                toplevelOrShell.setMaxSize(sz);
                if (toplevelOrShell.sendConfigure)
                    toplevelOrShell.sendConfigure(sz, []);
            }
            item.parent = leftPanel;
            leftPlaceholder.visible = false;
            return true;
        } else if (title.indexOf("MediaPlayer") !== -1) {
            item.parent = rightPanel;
            rightPlaceholder.visible = false;
            return true;
        }
        return false;
    }

    //
    // ---- Fallback: guess pane by buffer width if we never get a title ----
    //
    function placeItemByWidth(item) {
        const wantLeft = item.width <= leftPanel.width + 20; // 20px tolerance
        const p = wantLeft ? leftPanel : rightPanel;
        if (item.parent !== p) {
            item.parent = p;
        }
        if (p === leftPanel) leftPlaceholder.visible = false;
        if (p === rightPanel) rightPlaceholder.visible = false;
    }

    //
    // ---- XDG shell (Qt default) ----
    //
    XdgShell {
        id: xdg

        onToplevelCreated: {
            // 'toplevel' and 'xdgSurface' are available by name
            var item = surfaceItemComponent.createObject(rightPanel, { surface: xdgSurface.surface });
            if (!item)
                return;

            compositor.items.push(item);

            // try route immediately by title
            if (!placeItemByTitle(item, toplevel.title || "", toplevel)) {
                // retry a few times until the title shows up, then fall back to width
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
                    if (tries >= 10) { // ~1.2s total
                        placeItemByWidth(item);
                        timer.stop(); timer.destroy();
                    }
                });
                timer.start();
            }
        }
    }

    //
    // ---- Legacy WL-shell (only if some client uses it) ----
    //
    WlShell {
        id: wlshell

        onWlShellSurfaceCreated: function(wlShellSurface) {
            // Use proper parameter name instead of arguments[0]
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

    //
    // ---- Output / main window ----
    //
    WaylandOutput {
        id: output
        sizeFollowsWindow: true

        window: Window {
            id: mainWindow
            width: 1024  // CHANGED FROM 1200 to match 1024x600 display
            height: 600
            visible: true
            color: "#0f172a"
            title: "IVI Compositor - HeadUnit"

            Row {
                anchors.fill: parent

                // Left sidebar (GearSelector)
                Rectangle {
                    id: leftPanel
                    width: 200
                    height: parent.height
                    color: "#111827"
                    clip: true

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

                // Divider
                Rectangle { width: 2; height: parent.height; color: "#1e293b" }

                // Right pane (MediaPlayer)
                Rectangle {
                    id: rightPanel
                    width: parent.width - leftPanel.width - 2
                    height: parent.height
                    color: "#1e293b"
                    clip: true

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

            // Bottom status
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