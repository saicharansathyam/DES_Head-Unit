import QtQuick
import QtLocation
import QtPositioning

Rectangle {
    id: mapView
    width: parent.width
    height: parent.height
    color: "#f0f0f0"

    // SEA:ME default coordinates
    property real centerLat: 52.42445210764194
    property real centerLon: 10.792190583222407
    property real zoomLevel: 15

    signal locationSearched(string query)
    signal navigateTo(real lat, real lon, string address)

    // Plugin for map (using OSM - OpenStreetMap)
    Plugin {
        id: mapPlugin
        name: "osm"

        PluginParameter {
            name: "osm.mapping.custom.host"
            value: "https://tile.openstreetmap.org/"
        }
    }

    // Map display
    Map {
        id: map
        anchors.fill: parent
        plugin: mapPlugin
        center: QtPositioning.coordinate(mapView.centerLat, mapView.centerLon)
        zoomLevel: mapView.zoomLevel
        copyrightsVisible: true
    }

    // Current location marker
    MapQuickItem {
        id: currentLocationMarker
        coordinate: map.center
        anchorPoint.x: image.width / 2
        anchorPoint.y: image.height / 2

        sourceItem: Rectangle {
            id: image
            width: 32
            height: 32
            radius: 16
            color: "#ff6b6b"
            border.color: "#c92a2a"
            border.width: 2

            Text {
                anchors.centerIn: parent
                text: "📍"
                font.pixelSize: 20
            }
        }
    }

    // Navigation route (placeholder - can be extended)
    MapPolyline {
        id: routeLine
        line.color: "#4a90e2"
        line.width: 3
        path: [
            QtPositioning.coordinate(mapView.centerLat, mapView.centerLon),
            QtPositioning.coordinate(mapView.centerLat + 0.01, mapView.centerLon + 0.01)
        ]
        visible: false
    }

    // Mouse area for clicking on map
    MouseArea {
        anchors.fill: parent
        onClicked: {
            var coord = map.toCoordinate(Qt.point(mouse.x, mouse.y));
            currentLocationMarker.coordinate = coord;
            mapView.navigateTo(coord.latitude, coord.longitude, 
                "Lat: " + coord.latitude.toFixed(4) + ", Lon: " + coord.longitude.toFixed(4));
        }
    }

    // Navigation controls
    Row {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 15
        spacing: 10
        z: 50

        // Zoom in button
        Rectangle {
            width: 40
            height: 40
            radius: 4
            color: "#ffffff"
            border.color: "#cccccc"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "+"
                font.pixelSize: 20
                font.bold: true
                color: "#333333"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    map.zoomLevel = Math.min(map.zoomLevel + 1, 21);
                    mapView.zoomLevel = map.zoomLevel;
                }
            }
        }

        // Zoom out button
        Rectangle {
            width: 40
            height: 40
            radius: 4
            color: "#ffffff"
            border.color: "#cccccc"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "−"
                font.pixelSize: 20
                font.bold: true
                color: "#333333"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    map.zoomLevel = Math.max(map.zoomLevel - 1, 2);
                    mapView.zoomLevel = map.zoomLevel;
                }
            }
        }

        // Center button
        Rectangle {
            width: 40
            height: 40
            radius: 4
            color: "#4a90e2"
            border.color: "#2c5aa0"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "⊙"
                font.pixelSize: 18
                color: "#ffffff"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    map.center = QtPositioning.coordinate(mapView.centerLat, mapView.centerLon);
                    currentLocationMarker.coordinate = map.center;
                }
            }
        }
    }

    // Coordinates display
    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 15
        width: 220
        height: 70
        color: "#e6ffffff"
        radius: 4
        border.color: "#cccccc"
        border.width: 1
        z: 50

        Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            Text {
                text: "Coordinates"
                font.pixelSize: 12
                font.bold: true
                color: "#333333"
            }

            Text {
                text: "Lat: " + currentLocationMarker.coordinate.latitude.toFixed(6)
                font.pixelSize: 11
                color: "#666666"
            }

            Text {
                text: "Lon: " + currentLocationMarker.coordinate.longitude.toFixed(6)
                font.pixelSize: 11
                color: "#666666"
            }

            Text {
                text: "Zoom: " + map.zoomLevel.toFixed(1) + "x"
                font.pixelSize: 11
                color: "#666666"
            }
        }
    }

    // Function to search for a location
    function searchLocation(query) {
        console.log("Searching for:", query);
        // This would integrate with a geocoding service
        // For now, just show the current location
        locationSearched(query);
    }

    // Function to show search result on map
    function showSearchResult(title, address) {
        console.log("Showing result:", title, address);
        routeLine.visible = false;
    }

    // Function to navigate to a location
    function navigateToLocation(lat, lon) {
        map.center = QtPositioning.coordinate(lat, lon);
        currentLocationMarker.coordinate = map.center;
        mapView.zoomLevel = 15;
        map.zoomLevel = 15;
        routeLine.visible = true;
    }

    Component.onCompleted: {
        console.log("MapView loaded with SEA:ME coordinates");
    }
}
