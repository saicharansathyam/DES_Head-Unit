import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    color: "#0f172a"

    property string pairingDeviceId: ""
    property string pairingDeviceName: ""

    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        Text {
            text: "Bluetooth"
            font.pixelSize: 22
            font.bold: true
            color: theme.themeColor
        }

        Text {
            text: bluetoothManager.isEnabled ? "Enabled" : "Disabled"
            font.pixelSize: 14
            color: bluetoothManager.isEnabled ? theme.themeColor : "#f97373"
        }

        Button {
            id: scanButton
            text: bluetoothManager.isScanning ? "Scanning..." : "Scan for Devices"
            enabled: !bluetoothManager.isScanning
            width: parent.width * 0.5
            onClicked: bluetoothManager.startScan()
        }

        ListView {
            width: parent.width
            height: 300
            model: bluetoothManager.availableDevices

            delegate: Rectangle {
                width: parent.width
                height: 48
                radius: 8
                color: ListView.isCurrentItem ? theme.themeColor : "#020617"
                border.color: ListView.isCurrentItem ? theme.accentColor : "#1f2933"
                border.width: ListView.isCurrentItem ? 2 : 1

                Row {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Text {
                        text: model.name
                        color: "#e5e7eb"
                        font.pixelSize: 14
                    }

                    Item { width: 1; anchors.horizontalCenter: parent.horizontalCenter }

                    Text {
                        text: model.connected ? "Connected" : ""
                        color: theme.themeColor
                        font.pixelSize: 12
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (requiresPairing) {
                            pairingDeviceId = deviceId
                            pairingDeviceName = name
                            pairConfirmPopup.open()
                        } else if (!connected) {
                            bluetoothManager.connectDevice(deviceId)
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: pairConfirmPopup
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        x: (root.width - width) / 2
        y: (root.height - height) / 2

        Rectangle {
            width: 320
            height: 160
            color: "#263544"
            radius: 8

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 15

                Text {
                    text: "Pair with " + pairingDeviceName + "?"
                    font.pixelSize: 16
                    color: "white"
                }

                Text {
                    text: "Do you want to pair with this device?"
                    font.pixelSize: 14
                    color: "white"
                }

                Row {
                    spacing: 20
                    anchors.horizontalCenter: parent.horizontalCenter

                    Button {
                        text: "Cancel"
                        onClicked: pairConfirmPopup.close()
                    }

                    Button {
                        text: "Pair"
                        onClicked: {
                            pairConfirmPopup.close()
                            bluetoothManager.pairDevice(pairingDeviceId)
                        }
                    }
                }
            }
        }
    }
}
