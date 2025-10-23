import QtQuick
import QtQuick.Controls

Item {
    id: root

    property string currentSource: "usb"
    property bool usbAvailable: false
    property bool compact: false
    property color accentColor: "#3b82f6"
    property color secondaryColor: "#334155"

    signal sourceSelected(string sourceType)

    Rectangle {
        anchors.fill: parent
        color: secondaryColor
        radius: compact ? 4 : 8
        border.color: "#64748b"
        border.width: 1

        Row {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                width: parent.width / 2
                height: parent.height
                color: root.currentSource === "usb" ? accentColor : "transparent"
                radius: compact ? 4 : 8
                opacity: usbAvailable ? 1.0 : 0.5

                Behavior on color { ColorAnimation { duration: 200 } }

                MouseArea {
                    anchors.fill: parent
                    enabled: usbAvailable
                    onClicked: root.sourceSelected("usb")
                }

                Row {
                    anchors.centerIn: parent
                    spacing: compact ? 4 : 8

                    Text {
                        text: usbAvailable ? "💾" : "⊘"
                        font.pixelSize: compact ? 14 : 18
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "USB"
                        color: "white"
                        font.pixelSize: compact ? 10 : 14
                        font.bold: root.currentSource === "usb"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Rectangle {
                width: parent.width / 2
                height: parent.height
                color: root.currentSource === "youtube" ? accentColor : "transparent"
                radius: compact ? 4 : 8

                Behavior on color { ColorAnimation { duration: 200 } }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.sourceSelected("youtube")
                }

                Row {
                    anchors.centerIn: parent
                    spacing: compact ? 4 : 8

                    Text {
                        text: "📺"
                        font.pixelSize: compact ? 14 : 18
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "YouTube"
                        color: "white"
                        font.pixelSize: compact ? 10 : 14
                        font.bold: root.currentSource === "youtube"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}
