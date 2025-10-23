import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: wifiSettings
    color: "transparent"

    Column {
        anchors.fill: parent
        spacing: 15

        // Header
        Row {
            width: parent.width
            height: 40
            spacing: 10

            Text {
                text: "WiFi Settings"
                color: "#00ff00"
                font.pixelSize: 24
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
            }

            Button {
                text: "Scan"
                width: 100
                height: 35
                anchors.verticalCenter: parent.verticalCenter

                background: Rectangle {
                    color: parent.pressed ? "#505050" : "#404040"
                    radius: 5
                }

                contentItem: Text {
                    text: parent.text
                    color: "#ffffff"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: wifiManager.scanNetworks()
            }
        }

        // Current connection
        Rectangle {
            width: parent.width
            height: 80
            color: "#2a2a2a"
            radius: 8

            Column {
                anchors.centerIn: parent
                spacing: 5

                Text {
                    text: "Current Connection"
                    color: "#888888"
                    font.pixelSize: 12
                }

                Text {
                    text: wifiManager.currentNetwork
                    color: wifiManager.isConnected ? "#00ff00" : "#ff6600"
                    font.pixelSize: 16
                    font.bold: true
                }

                Button {
                    text: "Disconnect"
                    enabled: wifiManager.isConnected
                    anchors.horizontalCenter: parent.horizontalCenter

                    background: Rectangle {
                        color: parent.enabled ? (parent.pressed ? "#803030" : "#ff4444") : "#404040"
                        radius: 4
                    }

                    contentItem: Text {
                        text: parent.text
                        color: parent.enabled ? "#ffffff" : "#808080"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 11
                    }

                    onClicked: wifiManager.disconnectNetwork()
                }
            }
        }

        // Available networks
        Text {
            text: "Available Networks"
            color: "#ffffff"
            font.pixelSize: 16
            font.bold: true
        }

        Rectangle {
            width: parent.width
            height: 350
            color: "#2a2a2a"
            radius: 8

            ListView {
                id: networkList
                anchors.fill: parent
                anchors.margins: 10
                spacing: 5
                clip: true

                model: wifiManager.availableNetworks

                delegate: Rectangle {
                    width: networkList.width
                    height: 60
                    color: "#1a1a1a"
                    radius: 5

                    Row {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 15

                        // Signal strength
                        Text {
                            text: modelData.secured ? "🔒" : "📶"
                            font.pixelSize: 20
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Network info
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Text {
                                text: modelData.ssid
                                color: "#ffffff"
                                font.pixelSize: 14
                                font.bold: true
                            }

                            Text {
                                text: "Signal: " + modelData.strength + "%"
                                color: "#888888"
                                font.pixelSize: 11
                            }
                        }

                        Item { width: parent.width - 200 }

                        // Connect button
                        Button {
                            text: "Connect"
                            width: 80
                            height: 35
                            anchors.verticalCenter: parent.verticalCenter

                            background: Rectangle {
                                color: parent.pressed ? "#305030" : "#00aa00"
                                radius: 4
                            }

                            contentItem: Text {
                                text: parent.text
                                color: "#ffffff"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 11
                            }

                            onClicked: {
                                // Show password dialog if secured
                                if (modelData.secured) {
                                    passwordDialog.ssid = modelData.ssid
                                    passwordDialog.open()
                                } else {
                                    wifiManager.connectToNetwork(modelData.ssid, "")
                                }
                            }
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: "No networks found\nClick 'Scan' to search"
                color: "#666666"
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                visible: networkList.count === 0
            }
        }
    }

    // Password dialog
    Dialog {
        id: passwordDialog
        anchors.centerIn: parent
        width: 400
        height: 200
        modal: true

        property string ssid: ""

        title: "Enter Password for " + ssid

        background: Rectangle {
            color: "#2a2a2a"
            border.color: "#404040"
            border.width: 2
            radius: 8
        }

        contentItem: Column {
            spacing: 15
            padding: 20

            TextField {
                id: passwordField
                width: parent.width - 40
                placeholderText: "Password"
                echoMode: TextInput.Password

                background: Rectangle {
                    color: "#1a1a1a"
                    border.color: "#404040"
                    radius: 4
                }

                color: "#ffffff"
            }

            Row {
                spacing: 10
                anchors.horizontalCenter: parent.horizontalCenter

                Button {
                    text: "Cancel"
                    onClicked: passwordDialog.close()

                    background: Rectangle {
                        color: parent.pressed ? "#505050" : "#404040"
                        radius: 4
                    }

                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Button {
                    text: "Connect"
                    onClicked: {
                        wifiManager.connectToNetwork(passwordDialog.ssid, passwordField.text)
                        passwordDialog.close()
                        passwordField.text = ""
                    }

                    background: Rectangle {
                        color: parent.pressed ? "#305030" : "#00aa00"
                        radius: 4
                    }

                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }
}
