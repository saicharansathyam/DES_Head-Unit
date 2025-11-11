import QtQuick
import QtQuick.Controls
import QtLocation
import QtPositioning

Item {
    id: mapTileRoot

    signal navigationClicked()

    Rectangle {
        id: mapContainer
        anchors.fill: parent
        radius: 12
        color: "#081028"
        border.color: "#264653"
        border.width: 2
        clip: true

        MouseArea {
            anchors.fill: parent
            onClicked: {
                console.log("MapTile: Navigation clicked")
                navigationClicked()
            }
            hoverEnabled: true

            onEntered: mapContainer.border.color = "#3a7ca5"
            onExited: mapContainer.border.color = "#264653"
        }

        Plugin {
            id: mapPlugin
            name: "osm"

            PluginParameter {
                name: "osm.mapping.cache.directory"
                value: "/tmp/osm_cache"
            }
        }

        Map {
            id: map
            anchors.fill: parent
            anchors.margins: 2
            plugin: mapPlugin
            center: QtPositioning.coordinate(52.42445159395511, 10.79219202248994) // SEA_ME
            zoomLevel: 16

            // In Qt 6.x, use these properties instead of gesture
            copyrightsVisible: false

            // Disable all gestures by setting properties
            property bool gestureEnabled: false

            MapQuickItem {
                id: vehicleIcon
                coordinate: QtPositioning.coordinate(52.42445159395511, 10.79219202248994)

                sourceItem: Rectangle {
                    width: 30
                    height: 30
                    radius: 15
                    color: "#ff4444"
                    border.color: "#ffffff"
                    border.width: 3

                    // Pulsing animation
                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        NumberAnimation { to: 1.2; duration: 1000 }
                        NumberAnimation { to: 1.0; duration: 1000 }
                    }

                    // Inner dot
                    Rectangle {
                        anchors.centerIn: parent
                        width: 8
                        height: 8
                        radius: 4
                        color: "#ffffff"
                    }
                }

                anchorPoint.x: sourceItem.width / 2
                anchorPoint.y: sourceItem.height / 2
            }

            // Prevent all interactions
            MouseArea {
                anchors.fill: parent
                propagateComposedEvents: false
                preventStealing: true
            }
        }

        // Overlay label
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 40
            color: "#cc081028"
            radius: 12

            Text {
                anchors.centerIn: parent
                text: "Navigation"
                color: "#e6eef8"
                font.pixelSize: 16
                font.bold: true
            }
        }
    }
}
