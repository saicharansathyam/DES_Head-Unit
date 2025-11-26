import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    color: "#0f172a"

    property string selectedSSID: ""

    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        Text {
            text: "Wi-Fi"
            font.pixelSize: 22
            font.bold: true
            color: theme.themeColor
        }

        Row {
            spacing: 8

            Text {
                text: wifiManager.isConnected ? "Connected to" : "Not Connected"
                font.pixelSize: 14
                color: wifiManager.isConnected ? theme.themeColor : "#f97373"
            }

            Text {
                text: wifiManager.currentNetwork
                font.pixelSize: 14
                color: wifiManager.isConnected ? "#e5e7eb" : "#9ca3af"
                visible: wifiManager.isConnected
            }
        }

        Button {
            text: wifiManager.isScanning ? "Scanning..." : "Scan for Networks"
            enabled: !wifiManager.isScanning
            width: parent.width * 0.5
            onClicked: wifiManager.scanNetworks()
        }

        ListView {
            width: parent.width
            height: 300
            model: wifiManager.networks

            delegate: Rectangle {
                width: parent.width
                height: 50
                radius: 8
                color: ListView.isCurrentItem ? theme.themeColor : "#020617"
                border.color: ListView.isCurrentItem ? theme.accentColor : "#1f2933"
                border.width: ListView.isCurrentItem ? 2 : 1

                Row {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Text {
                        text: ssid
                        color: "#e5e7eb"
                        font.pixelSize: 14
                    }

                    Item { width: 1; anchors.horizontalCenter: parent.horizontalCenter }

                    Text {
                        text: connected ? "Connected" : ""
                        color: theme.themeColor
                        font.pixelSize: 12
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        selectedSSID = ssid
                        if (security === "none")
                            wifiManager.connectToNetwork(ssid, "")
                        else
                            wifiPasswordDialog.open()
                    }
                }
            }
        }
    }

    Popup {
        id: wifiPasswordDialog
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        x: (root.width - width) / 2
        y: (root.height - height) / 2

        Rectangle {
            width: 320
            height: 180
            color: "#263544"
            radius: 8

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 15

                Text {
                    text: "Enter Wi-Fi Password"
                    font.pixelSize: 18
                    color: "white"
                }

                TextField {
                    id: passwordInput
                    echoMode: TextInput.Password
                    width: parent.width - 40
                    placeholderText: "Password"
                }

                Row {
                    spacing: 25
                    anchors.horizontalCenter: parent.horizontalCenter

                    Button {
                        text: "Cancel"
                        onClicked: wifiPasswordDialog.close()
                    }

                    Button {
                        text: "Connect"
                        enabled: passwordInput.text.length > 0
                        onClicked: {
                            wifiPasswordDialog.close()
                            wifiManager.connectToNetwork(selectedSSID, passwordInput.text)
                            passwordInput.text = ""
                        }
                    }
                }
            }
        }
    }
}
