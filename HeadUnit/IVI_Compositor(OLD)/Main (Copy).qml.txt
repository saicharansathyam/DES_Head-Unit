import QtQuick
import QtQuick.Controls
import QtWayland.Compositor
import QtWayland.Compositor.XdgShell
import IVI_Compositor 1.0

WaylandCompositor {
    id: compositor
    socketName: "wayland-1"

    property var items: []
    property int navBarHeight: 50
    property int statusBarHeight: 24
    property int gearSelectorWidth: 200

    // Surface item component with proper scaling for 1024x600
    Component {
        id: surfaceItemComponent
        WaylandQuickItem {
            id: wqi
            focusOnClick: true
            touchEventsEnabled: true
            anchors.fill: parent
            clip: true

            property var buf: (surface && surface.size) ? surface.size : Qt.size(200, 550)
            property real scaleX: parent ? parent.width / Math.max(1, buf.width) : 1
            property real scaleY: parent ? parent.height / Math.max(1, buf.height) : 1
            property real uniformScale: Math.min(scaleX, scaleY, 1.0)

            width: buf.width
            height: buf.height
            scale: uniformScale
            transformOrigin: Item.Center
            anchors.centerIn: parent
        }
    }

    // Place surfaces based on application type
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
            return true;
        } else {
            // All other applications (MediaPlayer, ThemeColor, etc.)
            item.parent = appContainer;
            appPlaceholder.visible = false;
            return true;
        }
    }

    function placeItemByWidth(item) {
        const wantLeft = item.width <= leftPanel.width + 20;
        const p = wantLeft ? leftPanel : appContainer;
        if (item.parent !== p) {
            item.parent = p;
        }
        if (p === leftPanel) leftPlaceholder.visible = false;
        if (p === appContainer) appPlaceholder.visible = false;
    }

    // XDG Shell support
    XdgShell {
        id: xdg
        onToplevelCreated: {
            var item = surfaceItemComponent.createObject(appContainer, {
                surface: xdgSurface.surface
            });
            if (!item)
                return;

            compositor.items.push(item);

            if (!placeItemByTitle(item, toplevel.title || "", toplevel)) {
                var tries = 0;
                var timer = Qt.createQmlObject(
                    'import QtQuick; Timer { interval: 120; repeat: true }',
                    compositor
                );
                timer.triggered.connect(function() {
                    tries++;
                    if (placeItemByTitle(item, toplevel.title || "", toplevel)) {
                        timer.stop();
                        timer.destroy();
                        return;
                    }
                    if (tries >= 10) {
                        placeItemByWidth(item);
                        timer.stop();
                        timer.destroy();
                    }
                });
                timer.start();
            }
        }
    }

    // Main output
    WaylandOutput {
        id: output
        sizeFollowsWindow: true

        window: Window {
            id: mainWindow
            width: 1024
            height: 600
            visible: true
            color: "#0a0e1a"
            title: "IVI Compositor - HeadUnit"

            Column {
                anchors.fill: parent
                spacing: 0

                // Navigation Bar
                Rectangle {
                    id: navBar
                    width: parent.width
                    height: compositor.navBarHeight
                    color: "#1a1f2e"

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        color: "#2d3548"
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 0


                        // Center section - Location
                        Item {
                            width: parent.width * 0.4
                            height: parent.height

                            Row {
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text: "📍"
                                    font.pixelSize: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: "Wolfsburg, DE"
                                    color: "#94a3b8"
                                    font.pixelSize: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }

                        // Right section - Time
                        Item {
                            width: parent.width * 0.3
                            height: parent.height

                            Row {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 12

                                Text {
                                    id: timeText
                                    text: Qt.formatTime(new Date(), "hh:mm:ss")
                                    color: "#e2e8f0"
                                    font.pixelSize: 16
                                    font.bold: true
                                    anchors.verticalCenter: parent.verticalCenter

                                    Timer {
                                        interval: 1000
                                        running: true
                                        repeat: true
                                        onTriggered: timeText.text = Qt.formatTime(new Date(), "hh:mm:ss")
                                    }
                                }

                                Rectangle {
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: "#10b981"
                                    anchors.verticalCenter: parent.verticalCenter

                                    SequentialAnimation on opacity {
                                        running: true
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 0.3; duration: 1000 }
                                        NumberAnimation { to: 1.0; duration: 1000 }
                                    }
                                }
                            }
                        }
                    }
                }

                // Main content area
                Row {
                    width: parent.width
                    height: parent.height - compositor.navBarHeight - compositor.statusBarHeight
                    spacing: 0

                    // Left panel - GearSelector
                    Rectangle {
                        id: leftPanel
                        width: compositor.gearSelectorWidth
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
                                spacing: 12

                                Rectangle {
                                    width: 64
                                    height: 64
                                    radius: 32
                                    color: "#1f2937"
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Text {
                                        anchors.centerIn: parent
                                        text: "⚙"
                                        color: "#4b5563"
                                        font.pixelSize: 32
                                    }
                                }

                                Text {
                                    text: "GearSelector"
                                    color: "#6b7280"
                                    font.pixelSize: 14
                                    font.bold: true
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    text: "Waiting..."
                                    color: "#4b5563"
                                    font.pixelSize: 11
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }
                    }

                    // Divider
                    Rectangle {
                        width: 2
                        height: parent.height
                        color: "#1e293b"
                    }

                    // Right panel - Applications area
                    Rectangle {
                        id: appContainer
                        width: parent.width - leftPanel.width - 2
                        height: parent.height
                        color: "#0f172a"
                        clip: true

                        Rectangle {
                            id: appPlaceholder
                            anchors.fill: parent
                            visible: true
                            color: "transparent"

                            Column {
                                anchors.centerIn: parent
                                spacing: 20

                                Rectangle {
                                    width: 96
                                    height: 96
                                    radius: 48
                                    color: "#1e293b"
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Text {
                                        anchors.centerIn: parent
                                        text: "🚗"
                                        font.pixelSize: 48
                                    }
                                }

                                Text {
                                    text: "Application Area"
                                    color: "#94a3b8"
                                    font.pixelSize: 18
                                    font.bold: true
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    text: "MediaPlayer • ThemeColor • Navigation"
                                    color: "#64748b"
                                    font.pixelSize: 12
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    text: "Waiting for applications..."
                                    color: "#475569"
                                    font.pixelSize: 11
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
