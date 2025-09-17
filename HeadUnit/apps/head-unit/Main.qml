import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Window {
    id: root
    visible: true
    width: 1000
    height: 600
    color: "#111"

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ---------- TOP BAR ----------
        Rectangle {
            Layout.fillWidth: true
            height: 60
            color: "#222"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 360

                Text {
                    id: dateTime
                    text: Qt.formatTime(new Date(), "hh:mm")
                    color: "white"
                    font.pixelSize: 24
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    id: position
                    text: "Wolfsburg"
                    color: "lightgray"
                    font.pixelSize: 24
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    id: weather
                    text: "21°C ☀️"
                    color: "lightgray"
                    font.pixelSize: 24
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true } // spacer
            }
        }

        // ---------- MAIN CONTENT ----------
        StackView {
            id: stackView
            Layout.fillWidth: true
            Layout.fillHeight: true
            initialItem: Qt.resolvedUrl("qrc:/MediaPlayer.qml")
        }

        // ---------- BOTTOM NAVIGATION ----------
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            color: "#222"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 200
                Layout.alignment: Qt.AlignHCenter

                Button {
                    text: "Home"
                    palette.buttonText: "white"
                    onClicked: stackView.push("qrc:/Home.qml")
                }
                Button {
                    text: "Media"
                    palette.buttonText: "white"
                    onClicked: stackView.push("qrc:/media-player/MediaPlayer.qml")
                }
                Button {
                    text: "Ambient"
                    palette.buttonText: "white"
                    onClicked: stackView.push("qrc:/ambient-lighting/AmbientLighting.qml")
                }
                Button {
                    text: "Settings"
                    palette.buttonText: "white"
                    onClicked: stackView.push("qrc:/Settings.qml")
                }
            }
        }
    }
}
