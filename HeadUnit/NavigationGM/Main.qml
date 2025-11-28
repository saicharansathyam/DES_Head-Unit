import QtQuick
import QtQuick.Controls
import QtQuick.VirtualKeyboard

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 824
    height: 470
    title: "Navigation"
    color: "#ffffff"

    Rectangle {
        anchors.fill: parent
        color: "#ffffff"
        focus: true

        Column {
            anchors.fill: parent
            anchors.margins: 0
            spacing: 0

            // Search bar
            SearchBar {
                id: searchBar
                width: parent.width
                height: 70
            }

            // Map view
            MapView {
                id: mapView
                width: parent.width
                height: parent.height - searchBar.height

                onLocationSearched: function(query) {
                    searchBar.inputText = query;
                }

                onNavigateTo: function(lat, lon, address) {
                    searchBar.inputText = address;
                }
            }
        }
    }

    // Virtual Keyboard - appears at bottom when text input is focused
    InputPanel {
        id: inputPanel
        z: 99
        x: 0
        y: mainWindow.height - inputPanel.height
        width: mainWindow.width
        visible: active
    }
}

