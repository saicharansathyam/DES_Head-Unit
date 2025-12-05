import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    color: "#0f172a"

    property bool bluetoothEnabled: false

    Component.onCompleted: {
        // Initial state check could be added here
    }

    Connections {
        target: dbusHandler

        function onBluetoothDevicesChanged() {
            console.log("Bluetooth devices changed, count:", dbusHandler.bluetoothDevices.length)
            bluetoothListModel.clear()

            // Populate the list model from dbusHandler.bluetoothDevices
            for (var i = 0; i < dbusHandler.bluetoothDevices.length; i++) {
                var device = dbusHandler.bluetoothDevices[i]
                bluetoothListModel.append({
                    "name": device.name,
                    "address": device.address,
                    "paired": device.paired,
                    "connected": device.connected,
                    "rssi": device.rssi
                })
            }

            scanButton.text = "Scan for Devices"
            scanButton.enabled = bluetoothEnabled
        }

        function onBluetoothDevicePaired(address) {
            statusText.text = "✓ Device paired successfully"
            statusText.color = theme.themeColor
            statusText.visible = true
            statusTimer.restart()

            // Update the device in the list
            for (var i = 0; i < bluetoothListModel.count; i++) {
                if (bluetoothListModel.get(i).address === address) {
                    bluetoothListModel.setProperty(i, "paired", true)
                    break
                }
            }
        }

        function onBluetoothDeviceConnected(address) {
            statusText.text = "✓ Device connected"
            statusText.color = theme.themeColor
            statusText.visible = true
            statusTimer.restart()

            // Update the device in the list
            for (var i = 0; i < bluetoothListModel.count; i++) {
                if (bluetoothListModel.get(i).address === address) {
                    bluetoothListModel.setProperty(i, "connected", true)
                    break
                }
            }
        }
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: 20
        contentHeight: contentColumn.height
        clip: true

        Column {
            id: contentColumn
            width: parent.width
            spacing: 16

            // Header
            Text {
                text: "Bluetooth"
                font.pixelSize: 22
                font.bold: true
                color: theme.themeColor
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            // Status Card with Toggle
            Rectangle {
                width: parent.width
                height: 100
                radius: 12
                color: "#020617"
                border.color: theme.accentColor
                border.width: 2

                Column {
                    anchors.centerIn: parent
                    spacing: 12

                    Row {
                        spacing: 12
                        anchors.horizontalCenter: parent.horizontalCenter

                        Text {
                            text: "📡"
                            font.pixelSize: 28
                        }

                        Text {
                            text: bluetoothEnabled ? "Enabled" : "Disabled"
                            font.pixelSize: 18
                            font.bold: true
                            color: bluetoothEnabled ? theme.themeColor : "#64748b"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Switch {
                        id: bluetoothToggle
                        anchors.horizontalCenter: parent.horizontalCenter
                        checked: bluetoothEnabled

                        onToggled: {
                            bluetoothEnabled = checked
                            dbusHandler.setBluetoothEnabled(checked)

                            if (!checked) {
                                bluetoothListModel.clear()
                            }
                        }

                        indicator: Rectangle {
                            implicitWidth: 52
                            implicitHeight: 28
                            radius: 14
                            color: bluetoothToggle.checked ? theme.themeColor : "#334155"
                            border.color: bluetoothToggle.checked ? theme.accentColor : "#475569"
                            border.width: 2

                            Behavior on color { ColorAnimation { duration: 200 } }

                            Rectangle {
                                x: bluetoothToggle.checked ? parent.width - width - 3 : 3
                                y: 3
                                width: 22
                                height: 22
                                radius: 11
                                color: "white"

                                Behavior on x {
                                    NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                                }
                            }
                        }
                    }
                }
            }

            // Status Message
            Text {
                id: statusText
                text: ""
                font.pixelSize: 13
                anchors.horizontalCenter: parent.horizontalCenter
                visible: false

                Timer {
                    id: statusTimer
                    interval: 4000
                    onTriggered: statusText.visible = false
                }
            }

            // Scan Button
            Button {
                id: scanButton
                text: "Scan for Devices"
                width: parent.width * 0.6
                height: 44
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: bluetoothEnabled

                background: Rectangle {
                    color: {
                        if (!scanButton.enabled) return "#334155"
                        return scanButton.pressed ? theme.buttonPressedColor : theme.themeColor
                    }
                    radius: 10
                    border.color: scanButton.enabled ? theme.accentColor : "#475569"
                    border.width: 2
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                contentItem: Text {
                    text: scanButton.text
                    font.pixelSize: 15
                    font.bold: true
                    color: scanButton.enabled ? "white" : "#64748b"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    bluetoothListModel.clear()
                    scanButton.text = "Scanning..."
                    scanButton.enabled = false
                    dbusHandler.scanBluetooth()

                    // Re-enable after scan timeout
                    scanTimer.start()
                }

                Timer {
                    id: scanTimer
                    interval: 12000
                    onTriggered: {
                        if (scanButton.text === "Scanning...") {
                            scanButton.text = "Scan for Devices"
                            scanButton.enabled = bluetoothEnabled
                        }
                    }
                }
            }

            // Warning when disabled
            Rectangle {
                width: parent.width
                height: 60
                radius: 8
                color: "#7f1d1d"
                border.color: "#dc2626"
                border.width: 1
                visible: !bluetoothEnabled

                Row {
                    anchors.centerIn: parent
                    spacing: 10

                    Text {
                        text: "⚠️"
                        font.pixelSize: 20
                    }

                    Text {
                        text: "Bluetooth is disabled. Enable it to scan for devices."
                        font.pixelSize: 13
                        color: "#fecaca"
                        wrapMode: Text.WordWrap
                        width: parent.parent.width - 60
                    }
                }
            }

            // Devices List Header
            Text {
                text: "Available Devices (" + bluetoothListView.count + ")"
                font.pixelSize: 16
                font.bold: true
                color: theme.accentColor
                visible: bluetoothListView.count > 0
            }

            // Devices List
            ListView {
                id: bluetoothListView
                width: parent.width
                height: Math.min(contentHeight, 280)
                clip: true
                spacing: 8

                model: ListModel {
                    id: bluetoothListModel
                }

                delegate: Rectangle {
                    width: bluetoothListView.width
                    height: 70
                    radius: 10
                    color: mouseArea.pressed ? theme.buttonPressedColor : "#020617"
                    border.color: model.paired ? theme.themeColor : theme.accentColor
                    border.width: model.paired ? 2 : 1

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Row {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        // Device Icon
                        Rectangle {
                            width: 46
                            height: 46
                            radius: 23
                            color: theme.themeColor
                            opacity: 0.2
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: "📱"
                                font.pixelSize: 24
                                anchors.centerIn: parent
                            }
                        }

                        // Device Info
                        Column {
                            width: parent.width - 100
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6

                            Text {
                                text: model.name || "Unknown Device"
                                font.pixelSize: 15
                                font.bold: true
                                color: "#e5e7eb"
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: model.address || ""
                                font.pixelSize: 11
                                color: "#64748b"
                                font.family: "monospace"
                            }

                            Row {
                                spacing: 8

                                Rectangle {
                                    width: pairedLabel.width + 12
                                    height: 18
                                    radius: 9
                                    color: theme.themeColor
                                    opacity: 0.3
                                    visible: model.paired

                                    Text {
                                        id: pairedLabel
                                        text: "Paired"
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: theme.themeColor
                                        anchors.centerIn: parent
                                    }
                                }

                                Rectangle {
                                    width: connectedLabel.width + 12
                                    height: 18
                                    radius: 9
                                    color: "#10b981"
                                    visible: model.connected

                                    Text {
                                        id: connectedLabel
                                        text: "Connected"
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: "white"
                                        anchors.centerIn: parent
                                    }
                                }
                            }
                        }

                        // Action Icon
                        Text {
                            text: model.paired ? "✓" : "→"
                            font.pixelSize: 20
                            color: model.paired ? theme.themeColor : "#94a3b8"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        onClicked: {
                            if (!model.paired) {
                                pairingDeviceAddress = model.address
                                pairingDeviceName = model.name
                                pairConfirmPopup.open()
                            } else if (!model.connected) {
                                dbusHandler.connectDevice(model.address)
                                statusText.text = "Connecting to " + model.name + "..."
                                statusText.color = "#94a3b8"
                                statusText.visible = true
                            }
                        }
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    width: 8

                    contentItem: Rectangle {
                        radius: 4
                        color: theme.accentColor
                        opacity: parent.pressed ? 0.8 : 0.5
                    }
                }
            }

            // Empty State
            Item {
                width: parent.width
                height: 100
                visible: bluetoothListView.count === 0 && bluetoothEnabled

                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: "🔍"
                        font.pixelSize: 32
                        anchors.horizontalCenter: parent.horizontalCenter
                        opacity: 0.5
                    }

                    Text {
                        text: "No devices found"
                        font.pixelSize: 14
                        color: "#64748b"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: "Tap 'Scan for Devices' to search"
                        font.pixelSize: 12
                        color: "#475569"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }

    // Pairing Confirmation Dialog
    property string pairingDeviceAddress: ""
    property string pairingDeviceName: ""

    Popup {
        id: pairConfirmPopup
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        anchors.centerIn: parent
        width: 340
        height: 200

        background: Rectangle {
            color: "#1e293b"
            radius: 12
            border.color: theme.accentColor
            border.width: 2
        }

        Column {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 20

            Text {
                text: "Pair Bluetooth Device"
                font.pixelSize: 18
                font.bold: true
                color: theme.themeColor
            }

            Column {
                spacing: 8
                width: parent.width

                Text {
                    text: pairingDeviceName
                    font.pixelSize: 15
                    font.bold: true
                    color: "#e5e7eb"
                }

                Text {
                    text: pairingDeviceAddress
                    font.pixelSize: 12
                    color: "#94a3b8"
                    font.family: "monospace"
                }
            }

            Text {
                text: "Do you want to pair with this device?"
                font.pixelSize: 13
                color: "#cbd5e1"
                wrapMode: Text.WordWrap
                width: parent.width
            }

            Row {
                spacing: 12
                anchors.horizontalCenter: parent.horizontalCenter

                Button {
                    text: "Cancel"
                    width: 120
                    height: 40

                    background: Rectangle {
                        color: parent.pressed ? "#1e293b" : "#0f172a"
                        radius: 8
                        border.color: "#334155"
                        border.width: 2
                    }

                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 14
                        color: "#94a3b8"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: pairConfirmPopup.close()
                }

                Button {
                    text: "Pair"
                    width: 120
                    height: 40

                    background: Rectangle {
                        color: parent.pressed ? theme.buttonPressedColor : theme.themeColor
                        radius: 8
                        border.color: theme.accentColor
                        border.width: 2
                    }

                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 14
                        font.bold: true
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        pairConfirmPopup.close()
                        dbusHandler.pairDevice(pairingDeviceAddress)
                        statusText.text = "Pairing with " + pairingDeviceName + "..."
                        statusText.color = "#94a3b8"
                        statusText.visible = true
                    }
                }
            }
        }
    }
}
