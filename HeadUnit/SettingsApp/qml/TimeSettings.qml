import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    color: "#0f172a"

    Component.onCompleted: {
        dbusHandler.refreshTime()
        dbusHandler.refreshTimezone()
        timeRefreshTimer.start()
    }

    // Timer to refresh time every second
    Timer {
        id: timeRefreshTimer
        interval: 1000
        running: false
        repeat: true
        onTriggered: dbusHandler.refreshTime()
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: 20
        contentHeight: contentColumn.height
        clip: true

        Column {
            id: contentColumn
            width: parent.width
            spacing: 20

            // Header
            Text {
                text: "Date & Time"
                font.pixelSize: 22
                font.bold: true
                color: theme.themeColor
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            // Current Time Display
            Rectangle {
                width: parent.width
                height: 100
                radius: 12
                color: "#020617"
                border.color: theme.accentColor
                border.width: 2

                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: dbusHandler.currentTime
                        font.pixelSize: 28
                        font.bold: true
                        color: theme.themeColor
                        anchors.horizontalCenter: parent.horizontalCenter
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    Text {
                        text: "Timezone: " + dbusHandler.timezone
                        font.pixelSize: 14
                        color: theme.accentColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            // Manual Time Adjustment Section
            Text {
                text: "Manual Time Adjustment"
                font.pixelSize: 18
                font.bold: true
                color: theme.accentColor
            }

            Row {
                spacing: 15
                anchors.horizontalCenter: parent.horizontalCenter

                // Year
                Column {
                    spacing: 4
                    Text {
                        text: "Year"
                        font.pixelSize: 12
                        color: "#94a3b8"
                    }
                    SpinBox {
                        id: yearSpinBox
                        from: 2020
                        to: 2099
                        value: new Date().getFullYear()
                        editable: true

                        contentItem: TextInput {
                            text: yearSpinBox.textFromValue(yearSpinBox.value, yearSpinBox.locale)
                            font.pixelSize: 14
                            color: "white"
                            horizontalAlignment: Qt.AlignHCenter
                            verticalAlignment: Qt.AlignVCenter
                            readOnly: !yearSpinBox.editable
                        }
                    }
                }

                // Month
                Column {
                    spacing: 4
                    Text {
                        text: "Month"
                        font.pixelSize: 12
                        color: "#94a3b8"
                    }
                    SpinBox {
                        id: monthSpinBox
                        from: 1
                        to: 12
                        value: new Date().getMonth() + 1
                        editable: true

                        contentItem: TextInput {
                            text: monthSpinBox.textFromValue(monthSpinBox.value, monthSpinBox.locale)
                            font.pixelSize: 14
                            color: "white"
                            horizontalAlignment: Qt.AlignHCenter
                            verticalAlignment: Qt.AlignVCenter
                            readOnly: !monthSpinBox.editable
                        }
                    }
                }

                // Day
                Column {
                    spacing: 4
                    Text {
                        text: "Day"
                        font.pixelSize: 12
                        color: "#94a3b8"
                    }
                    SpinBox {
                        id: daySpinBox
                        from: 1
                        to: 31
                        value: new Date().getDate()
                        editable: true

                        contentItem: TextInput {
                            text: daySpinBox.textFromValue(daySpinBox.value, daySpinBox.locale)
                            font.pixelSize: 14
                            color: "white"
                            horizontalAlignment: Qt.AlignHCenter
                            verticalAlignment: Qt.AlignVCenter
                            readOnly: !daySpinBox.editable
                        }
                    }
                }
            }

            Row {
                spacing: 15
                anchors.horizontalCenter: parent.horizontalCenter

                // Hour
                Column {
                    spacing: 4
                    Text {
                        text: "Hour"
                        font.pixelSize: 12
                        color: "#94a3b8"
                    }
                    SpinBox {
                        id: hourSpinBox
                        from: 0
                        to: 23
                        value: new Date().getHours()
                        editable: true

                        contentItem: TextInput {
                            text: hourSpinBox.textFromValue(hourSpinBox.value, hourSpinBox.locale)
                            font.pixelSize: 14
                            color: "white"
                            horizontalAlignment: Qt.AlignHCenter
                            verticalAlignment: Qt.AlignVCenter
                            readOnly: !hourSpinBox.editable
                        }
                    }
                }

                // Minute
                Column {
                    spacing: 4
                    Text {
                        text: "Minute"
                        font.pixelSize: 12
                        color: "#94a3b8"
                    }
                    SpinBox {
                        id: minuteSpinBox
                        from: 0
                        to: 59
                        value: new Date().getMinutes()
                        editable: true

                        contentItem: TextInput {
                            text: minuteSpinBox.textFromValue(minuteSpinBox.value, minuteSpinBox.locale)
                            font.pixelSize: 14
                            color: "white"
                            horizontalAlignment: Qt.AlignHCenter
                            verticalAlignment: Qt.AlignVCenter
                            readOnly: !minuteSpinBox.editable
                        }
                    }
                }

                // Second
                Column {
                    spacing: 4
                    Text {
                        text: "Second"
                        font.pixelSize: 12
                        color: "#94a3b8"
                    }
                    SpinBox {
                        id: secondSpinBox
                        from: 0
                        to: 59
                        value: new Date().getSeconds()
                        editable: true

                        contentItem: TextInput {
                            text: secondSpinBox.textFromValue(secondSpinBox.value, secondSpinBox.locale)
                            font.pixelSize: 14
                            color: "white"
                            horizontalAlignment: Qt.AlignHCenter
                            verticalAlignment: Qt.AlignVCenter
                            readOnly: !secondSpinBox.editable
                        }
                    }
                }
            }

            Button {
                text: "Set System Time"
                width: 200
                height: 40
                anchors.horizontalCenter: parent.horizontalCenter

                background: Rectangle {
                    color: parent.pressed ? theme.buttonPressedColor : theme.themeColor
                    radius: 8
                    border.color: theme.accentColor
                    border.width: 2
                    Behavior on color { ColorAnimation { duration: 200 } }
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
                    var success = dbusHandler.setSystemTime(
                        yearSpinBox.value,
                        monthSpinBox.value,
                        daySpinBox.value,
                        hourSpinBox.value,
                        minuteSpinBox.value,
                        secondSpinBox.value
                    )

                    if (success) {
                        statusText.text = "✓ Time updated successfully"
                        statusText.color = theme.themeColor
                    } else {
                        statusText.text = "✗ Failed to update time (requires sudo)"
                        statusText.color = "#f97373"
                    }
                    statusText.visible = true
                    statusTimer.start()
                }
            }

            Text {
                id: statusText
                text: ""
                font.pixelSize: 13
                anchors.horizontalCenter: parent.horizontalCenter
                visible: false

                Timer {
                    id: statusTimer
                    interval: 3000
                    onTriggered: statusText.visible = false
                }
            }

            // Timezone Section
            Text {
                text: "Timezone Settings"
                font.pixelSize: 18
                font.bold: true
                color: theme.accentColor
                topPadding: 10
            }

            Row {
                spacing: 15
                anchors.horizontalCenter: parent.horizontalCenter

                ComboBox {
                    id: timezoneComboBox
                    width: 250
                    model: [
                        "Europe/Berlin",
                        "Europe/London",
                        "Europe/Paris",
                        "America/New_York",
                        "America/Los_Angeles",
                        "America/Chicago",
                        "Asia/Tokyo",
                        "Asia/Shanghai",
                        "Asia/Dubai",
                        "Australia/Sydney",
                        "UTC"
                    ]
                    currentIndex: model.indexOf(dbusHandler.timezone)

                    background: Rectangle {
                        color: timezoneComboBox.pressed ? theme.buttonPressedColor : "#020617"
                        radius: 8
                        border.color: theme.accentColor
                        border.width: 1
                    }

                    contentItem: Text {
                        text: timezoneComboBox.displayText
                        font.pixelSize: 14
                        color: "white"
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 12
                    }
                }

                Button {
                    text: "Apply"
                    width: 100
                    height: 40

                    background: Rectangle {
                        color: parent.pressed ? theme.buttonPressedColor : theme.themeColor
                        radius: 8
                        border.color: theme.accentColor
                        border.width: 2
                        Behavior on color { ColorAnimation { duration: 200 } }
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
                        var success = dbusHandler.setTimezone(timezoneComboBox.currentText)
                        if (success) {
                            dbusHandler.refreshTimezone()
                            timezoneStatusText.text = "✓ Timezone updated"
                            timezoneStatusText.color = theme.themeColor
                        } else {
                            timezoneStatusText.text = "✗ Failed to update timezone"
                            timezoneStatusText.color = "#f97373"
                        }
                        timezoneStatusText.visible = true
                        timezoneStatusTimer.start()
                    }
                }
            }

            Text {
                id: timezoneStatusText
                text: ""
                font.pixelSize: 13
                anchors.horizontalCenter: parent.horizontalCenter
                visible: false

                Timer {
                    id: timezoneStatusTimer
                    interval: 3000
                    onTriggered: timezoneStatusText.visible = false
                }
            }

            // NTP Toggle
            Row {
                spacing: 15
                anchors.horizontalCenter: parent.horizontalCenter
                topPadding: 10

                Text {
                    text: "Automatic Time (NTP)"
                    font.pixelSize: 14
                    color: "#e5e7eb"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Switch {
                    id: ntpSwitch

                    onToggled: {
                        dbusHandler.setNTPEnabled(checked)
                    }

                    indicator: Rectangle {
                        implicitWidth: 48
                        implicitHeight: 26
                        radius: 13
                        color: ntpSwitch.checked ? theme.themeColor : "#334155"
                        border.color: ntpSwitch.checked ? theme.accentColor : "#475569"

                        Rectangle {
                            x: ntpSwitch.checked ? parent.width - width - 3 : 3
                            y: 3
                            width: 20
                            height: 20
                            radius: 10
                            color: "white"

                            Behavior on x {
                                NumberAnimation { duration: 200 }
                            }
                        }
                    }
                }
            }

            Text {
                text: "Note: Manual time adjustment requires administrator privileges"
                font.pixelSize: 11
                color: "#94a3b8"
                font.italic: true
                anchors.horizontalCenter: parent.horizontalCenter
                wrapMode: Text.WordWrap
                width: parent.width * 0.8
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
