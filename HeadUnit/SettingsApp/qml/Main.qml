import QtQuick
import QtQuick.Window
import QtQuick.Controls

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 824
    height: 470
    title: "Settings"

    color: "#0f172a"

    Rectangle {
        anchors.fill: parent
        color: "#0f172a"

        Row {
            anchors.fill: parent

            SettingsMenu {
                id: settingsMenu
                width: 200
                height: parent.height

                onMenuItemClicked: function(page) {
                    contentLoader.source = page + ".qml"
                }
            }

            Rectangle {
                width: parent.width - settingsMenu.width
                height: parent.height
                color: "#1e293b"

                Loader {
                    id: contentLoader
                    anchors.fill: parent
                    anchors.margins: 20
                    source: "WiFiSettings.qml"  // default
                }
            }
        }
    }
}
