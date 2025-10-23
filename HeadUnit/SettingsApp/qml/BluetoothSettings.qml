import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: bluetoothSettings
    color: "transparent"

    Column {
        anchors.fill: parent
        spacing: 15

        // Header
        Row {
            width: parent.width
            height: 40
            spacing: 15

            Text {
                text: "Bluetooth Settings"
                color: "#00ff00"
                font.pixelSize: 24
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }

            // Enable/Disable switch
            Switch {
                id: bluetoothSwitch
                checked: bluetoothManager.isEnabled
                anchors.verticalCenter: parent.verticalCenter

                onToggled: bluetoothManager.setEnabled(checked)

                indicator: Rectangle {
                    implicitWidth: 50
                    implicitHeight: 25
                    radius: 13
                    color: bluetoothSwitch.checked ? "#00aa00" : "#404040"

                    Rectangle {
                        x: bluetoothSwitch.checked ? parent.width - width - 3 : 3
                        y: 3
                        width: 19
                        height: 19
                        radius: 10
                        color: "#ffffff"

                        Behavior on x {
                            NumberAnimation { duration: 200 }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
            }

            Button {
                text: bluetoothManager.isScanning ? "Stop Scan" : "Scan"
                width: 100
                height: 35
                enabled: bluetoothManager.isEnabled
                anchors.verticalCenter: parent.verticalCenter

                background: Rectangle {
                    color: parent.enabled ? (parent.pressed ? "#505050" : "#404040") : "#2a2a2a"
                    radius: 5
                }

                contentItem: Text {
                    text: parent.text
                    color: parent.enabled ? "#ffffff" : "#666666"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    if (bluetoothManager.isScanning) {
                        bluetoothManager.stopScan()
                    } else {
                        bluetoothManager.startScan()
                    }
                }
            }
        }

        // Paired devices
        Text {
            text: "Paired Devices"
            color: "#ffffff"
            font.pixelSize: 16
            font.bold: true
        }

        Rectangle {
            width: parent.width
            height: 180
            color: "#2a2a2a"
            radius: 8

            ListView {
                id: pairedList
                anchors.fill: parent
                anchors.margins: 10
                spacing: 5
                clip: true

                model: bluetoothManager.pairedDevices

                delegate: Rectangle {
                    width: pairedList.width
                    height: 50
                    color: "#1a1a1a"
                    radius: 5

                    Row {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 15

                        Text {
                            text: "🔗"
                            font.pixelSize: 20
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                text: modelData.name
                                color: "#ffffff"
                                font.pixelSize: 13
                                font.bold: true
                            }

                            Text {
                                text: modelData.address
                                color: "#888888"
                                font.pixelSize: 10
                            }
                        }

                        Item { width: parent.width - 300 }

                        Button {
                            text: "Connect"
                            width: 75
                            height: 30
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
                                font.pixelSize: 10
                            }

                            onClicked: bluetoothManager.connectDevice(modelData.address)
                        }

                        Button {
                            text: "Unpair"
                            width: 75
                            height: 30
                            anchors.verticalCenter: parent.verticalCenter

                            background: Rectangle {
                                color: parent.pressed ? "#803030" : "#ff4444"
                                radius: 4
                            }

                            contentItem: Text {
                                text: parent.text
                                color: "#ffffff"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 10
                            }

                            onClicked: bluetoothManager.unpairDevice(modelData.address)
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: "No paired devices"
                color: "#666666"
                font.pixelSize: 14
                visible: pairedList.count === 0
            }
        }

        // Available devices
        Text {
            text: "Available Devices"
            color: "#ffffff"
            font.pixelSize: 16
            font.bold: true
        }

        Rectangle {
            width: parent.width
            height: 250
            color: "#2a2a2a"
            radius: 8

            ListView {
                id: availableList
                anchors.fill: parent
                anchors.margins: 10
                spacing: 5
                clip: true

                model: bluetoothManager.availableDevices

                delegate: Rectangle {
                    width: availableList.width
                    height: 55
                    color: "#1a1a1a"
                    radius: 5

                    Row {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 15

                        Text {
                            text: "📱"
                            font.pixelSize: 20
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                text: modelData.name
                                color: "#ffffff"
                                font.pixelSize: 13
                                font.bold: true
                            }

                            Text {
                                text: modelData.address
                                color: "#888888"
                                font.pixelSize: 10
                            }
                        }

                        Item { width: parent.width - 250 }

                        Button {
                            text: "Pair"
                            width: 80
                            height: 35
                            anchors.verticalCenter: parent.verticalCenter

                            background: Rectangle {
                                color: parent.pressed ? "#305060" : "#0088cc"
                                radius: 4
                            }

                            contentItem: Text {
                                text: parent.text
                                color: "#ffffff"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 11
                            }

                            onClicked: bluetoothManager.pairDevice(modelData.address)
                        }
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 10
                visible: availableList.count === 0 && !bluetoothManager.isScanning

                Text {
                    text: bluetoothManager.isEnabled ?
                          "No devices found\nClick 'Scan' to search" :
                          "Bluetooth is disabled"
                    color: "#666666"
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            BusyIndicator {
                anchors.centerIn: parent
                running: bluetoothManager.isScanning
                visible: running
            }
        }
    }
}
