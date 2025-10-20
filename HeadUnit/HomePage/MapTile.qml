import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtLocation
import QtPositioning


Item{
    // Navigation tile
    Rectangle {
        id: root
        height: 500
        width: 500
        radius: 12
        color: "#081028"
        border.color: "#264653"

        MouseArea {
            anchors.fill: parent
            onClicked: launchApp("Navigation")
            hoverEnabled: true
        }

        Plugin {
            id: mapPlugin
            name: "osm"
        }

        Map{
            id: map
            anchors.fill: parent
            plugin: mapPlugin
            center: QtPositioning.coordinate(52.42445159395511, 10.79219202248994) // SEA_ME
            zoomLevel: 20
            property geoCoordinate startCentroid

            MapQuickItem {
                id: vehicleIcon
                coordinate: QtPositioning.coordinate(52.5200, 13.4050) // Starting position
                sourceItem: Image {
                    source: "images/car_icon.png" // Your custom image file
                    width: 40
                    height: 40
                    // Center the image's anchor point
                    x: -width / 2
                    y: -height / 2
                }
                // Align the center of the image with the map coordinate
                anchorPoint.x: sourceItem.width / 2
                anchorPoint.y: sourceItem.height / 2
            }
        }
    }
}
