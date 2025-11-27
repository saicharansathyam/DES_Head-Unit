import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    color: "#0f172a"

    Component.onCompleted: {
        // Get current WiFi status on load
        updateCurrentWiFi()
    }

    function updateCurrentWiFi() {
        currentWiFiText.text = dbusHandler.getCurrentWiFi()
    }

    Connections {
        target: dbusHandler

        function onWifiNetworksFound(networks) {
            // Parse network data: "SSID:SIGNAL:SECURITY"
            wifiListModel.clear()
            for (var i = 0; i < networks.length; i++) {
                var parts = networks[i].split(':')
                if (parts.length >= 3) {
                    wifiListModel.append({
                        "ssid": parts[0],
                        "signal": parseInt(parts[1]) || 0,
                        "security": parts[2],
                        "connected": false
                    })
                }
            }
            scanButton.text = "Scan for Networks"
            scanButton.enabled = true
        }

        function onWifiConnected(ssid) {
            statusText.text = "✓ Connected to " + ssid
            statusText.color = theme.themeColor
            statusText.visible = true
            statusTimer.restart()
            updateCurrentWiFi()
        }

        function onWifiDisconnected() {
            statusText.text = "Disconnected from WiFi"
            statusText.color = "#94a3b8"
            statusText.visible = true
            statusTimer.restart()
            updateCurrentWiFi()
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
                text: "Wi-Fi"
                font.pixelSize: 22
                font.bold: true
                color: theme.themeColor
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            // Status Card
            Rectangle {
                width: parent.width
                height: 80
                radius: 12
                color: "#020617"
                border.color: theme.accentColor
                border.width: 2

                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    Row {
                        spacing: 8
                        anchors.horizontalCenter: parent.horizontalCenter

                        Text {
                            text: "📶"
                            font.pixelSize: 24
                        }

                        Text {
                            id: currentWiFiText
                            text: "Not Connected"
                            font.pixelSize: 16
                            font.bold: true
                            color: theme.themeColor
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Button {
                        text: "Disconnect"
                        width: 120
                        height: 30
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: currentWiFiText.text !== "Not Connected"

                        background: Rectangle {
                            color: parent.pressed ? "#7f1d1d" : "#991b1b"
                            radius: 6
                            border.color: "#dc2626"
                            border.width: 1
                        }

                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 12
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            dbusHandler.disconnectWiFi()
                            currentWiFiText.text = "Not Connected"
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
                text: "Scan for Networks"
                width: parent.width * 0.6
                height: 44
                anchors.horizontalCenter: parent.horizontalCenter

                background: Rectangle {
                    color: {
                        if (!scanButton.enabled) return "#334155"
                        return scanButton.pressed ? theme.buttonPressedColor : theme.themeColor
                    }
                    radius: 10
                    border.color: theme.accentColor
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
                    wifiListModel.clear()
                    scanButton.text = "Scanning..."
                    scanButton.enabled = false
                    dbusHandler.scanWiFi()
                }
            }

            // Networks List Header
            Text {
                text: "Available Networks"
                font.pixelSize: 16
                font.bold: true
                color: theme.accentColor
                visible: wifiListView.count > 0
            }

            // Networks List
            ListView {
                id: wifiListView
                width: parent.width
                height: Math.min(contentHeight, 280)
                clip: true
                spacing: 8

                model: ListModel {
                    id: wifiListModel
                }

                delegate: Rectangle {
                    width: wifiListView.width
                    height: 60
                    radius: 10
                    color: mouseArea.pressed ? theme.buttonPressedColor : "#020617"
                    border.color: theme.accentColor
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Row {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        // Signal Strength Icon
                        Text {
                            text: {
                                if (model.signal >= 75) return "📶"
                                if (model.signal >= 50) return "📶"
                                if (model.signal >= 25) return "📡"
                                return "📶"
                            }
                            font.pixelSize: 24
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Network Info
                        Column {
                            width: parent.width - 100
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Text {
                                text: model.ssid
                                font.pixelSize: 15
                                font.bold: true
                                color: "#e5e7eb"
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Row {
                                spacing: 10

                                Text {
                                    text: model.security === "" || model.security === "none" ? "Open" : "🔒 Secured"
                                    font.pixelSize: 12
                                    color: "#94a3b8"
                                }

                                Text {
                                    text: "Signal: " + model.signal + "%"
                                    font.pixelSize: 12
                                    color: theme.accentColor
                                }
                            }
                        }

                        // Connect Icon
                        Text {
                            text: "→"
                            font.pixelSize: 20
                            color: theme.themeColor
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        onClicked: {
                            selectedSSID = model.ssid
                            selectedSecurity = model.security

                            if (model.security === "" || model.security === "none") {
                                // Open network - connect directly
                                dbusHandler.connectToWiFi(model.ssid, "")
                                statusText.text = "Connecting to " + model.ssid + "..."
                                statusText.color = "#94a3b8"
                                statusText.visible = true
                            } else {
                                // Secured network - show password dialog
                                wifiPasswordDialog.open()
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
                visible: wifiListView.count === 0

                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: "📡"
                        font.pixelSize: 32
                        anchors.horizontalCenter: parent.horizontalCenter
                        opacity: 0.5
                    }

                    Text {
                        text: "No networks found"
                        font.pixelSize: 14
                        color: "#64748b"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: "Tap 'Scan for Networks' to search"
                        font.pixelSize: 12
                        color: "#475569"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }

    // Password Dialog
    Popup {
        id: wifiPasswordDialog
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        anchors.centerIn: parent
        width: 360
        height: 240

        property string selectedSSID: ""
        property string selectedSecurity: ""

        background: Rectangle {
            color: "#1e293b"
            radius: 12
            border.color: theme.accentColor
            border.width: 2
        }

        Column {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 18

            Text {
                text: "Connect to Wi-Fi"
                font.pixelSize: 18
                font.bold: true
                color: theme.themeColor
            }

            Text {
                text: selectedSSID
                font.pixelSize: 15
                color: "#e5e7eb"
                elide: Text.ElideRight
                width: parent.width
            }

            TextField {
                id: passwordInput
                width: parent.width
                height: 44
                placeholderText: "Enter password"
                echoMode: showPasswordCheckbox.checked ? TextInput.Normal : TextInput.Password
                font.pixelSize: 14

                background: Rectangle {
                    color: "#0f172a"
                    radius: 8
                    border.color: passwordInput.activeFocus ? theme.accentColor : "#334155"
                    border.width: 2
                }

                color: "white"
                leftPadding: 12
                rightPadding: 12
            }

            CheckBox {
                id: showPasswordCheckbox
                text: "Show password"

                contentItem: Text {
                    text: showPasswordCheckbox.text
                    font.pixelSize: 12
                    color: "#94a3b8"
                    leftPadding: showPasswordCheckbox.indicator.width + 8
                    verticalAlignment: Text.AlignVCenter
                }

                indicator: Rectangle {
                    width: 18
                    height: 18
                    radius: 4
                    border.color: theme.accentColor
                    border.width: 2
                    color: showPasswordCheckbox.checked ? theme.themeColor : "transparent"

                    Text {
                        text: "✓"
                        font.pixelSize: 12
                        color: "white"
                        anchors.centerIn: parent
                        visible: showPasswordCheckbox.checked
                    }
                }
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

                    onClicked: {
                        wifiPasswordDialog.close()
                        passwordInput.text = ""
                    }
                }

                Button {
                    text: "Connect"
                    width: 120
                    height: 40
                    enabled: passwordInput.text.length > 0

                    background: Rectangle {
                        color: {
                            if (!parent.enabled) return "#334155"
                            return parent.pressed ? theme.buttonPressedColor : theme.themeColor
                        }
                        radius: 8
                        border.color: parent.enabled ? theme.accentColor : "#475569"
                        border.width: 2
                    }

                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 14
                        font.bold: true
                        color: parent.enabled ? "white" : "#64748b"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        wifiPasswordDialog.close()
                        dbusHandler.connectToWiFi(selectedSSID, passwordInput.text)
                        statusText.text = "Connecting to " + selectedSSID + "..."
                        statusText.color = "#94a3b8"
                        statusText.visible = true
                        passwordInput.text = ""
                    }
                }
            }
        }
    }
}
