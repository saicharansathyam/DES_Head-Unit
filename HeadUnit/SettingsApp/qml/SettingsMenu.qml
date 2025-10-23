import QtQuick
import QtQuick.Controls

Rectangle {
    id: menu
    color: "#1f1f1f"

    property string currentContext: "wifi"

    signal contextSelected(string context)

    Column {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 5

        // Header
        Text {
            text: "SETTINGS"
            color: "#00ff00"
            font.pixelSize: 18
            font.bold: true
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            width: parent.width
            height: 2
            color: "#404040"
        }

        // Menu items
        MenuButton {
            text: "WiFi"
            icon: "📶"
            isActive: currentContext === "wifi"
            onClicked: contextSelected("wifi")
        }

        MenuButton {
            text: "Bluetooth"
            icon: "🔵"
            isActive: currentContext === "bluetooth"
            onClicked: contextSelected("bluetooth")
        }

        MenuButton {
            text: "Sound"
            icon: "🔊"
            isActive: currentContext === "sound"
            onClicked: contextSelected("sound")
        }

        Item {
            width: parent.width
            height: 20
        }

        // Status info
        Rectangle {
            width: parent.width
            height: 100
            color: "#2a2a2a"
            radius: 5

            Column {
                anchors.centerIn: parent
                spacing: 5

                Text {
                    text: "Status"
                    color: "#00ff00"
                    font.pixelSize: 12
                    font.bold: true
                }

                Text {
                    text: wifiManager.isConnected ? "WiFi: Connected" : "WiFi: Disconnected"
                    color: wifiManager.isConnected ? "#00ff00" : "#ff6600"
                    font.pixelSize: 10
                }

                Text {
                    text: bluetoothManager.isEnabled ? "BT: Enabled" : "BT: Disabled"
                    color: bluetoothManager.isEnabled ? "#00ff00" : "#ff6600"
                    font.pixelSize: 10
                }

                Text {
                    text: "Vol: " + settingsManager.systemVolume + "%"
                    color: "#ffffff"
                    font.pixelSize: 10
                }
            }
        }
    }
}

