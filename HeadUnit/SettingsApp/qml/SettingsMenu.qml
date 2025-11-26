import QtQuick
import QtQuick.Controls

Rectangle {
    id: settingsMenu
    color: "#020617"

    signal menuItemClicked(string item)

    property string currentPage: "WiFiSettings"

    Column {
        anchors.fill: parent
        anchors.topMargin: 20
        spacing: 4

        Text {
            text: "Settings"
            font.pixelSize: 24
            font.bold: true
            color: theme.themeColor
            anchors.horizontalCenter: parent.horizontalCenter
        }

        MenuButton {
            textLabel: "Wi-Fi"
            iconText: "📶"
            selected: settingsMenu.currentPage === "WiFiSettings"
            onClicked: {
                settingsMenu.currentPage = "WiFiSettings"
                settingsMenu.menuItemClicked("WiFiSettings")
            }
        }

        MenuButton {
            textLabel: "Bluetooth"
            iconText: "📡"
            selected: settingsMenu.currentPage === "BluetoothSettings"
            onClicked: {
                settingsMenu.currentPage = "BluetoothSettings"
                settingsMenu.menuItemClicked("BluetoothSettings")
            }
        }

        MenuButton {
            textLabel: "Sound"
            iconText: "🔊"
            selected: settingsMenu.currentPage === "SoundSettings"
            onClicked: {
                settingsMenu.currentPage = "SoundSettings"
                settingsMenu.menuItemClicked("SoundSettings")
            }
        }
    }
}
