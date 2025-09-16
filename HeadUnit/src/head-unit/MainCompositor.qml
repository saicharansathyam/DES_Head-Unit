import QtQuick
import QtQuick.Controls

Window {
    visible: true
    width: 1200
    height: 600
    color: "black"

    // Topbar
    Rectangle {
        id: topbar
        anchors.top: parent.top
        width: parent.width
        height: 60
        color: "#222"

        Row {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 30

            Text { id:dateTime; text: Qt.formatTime(new Date(), "hh:mm"); color: "white"; font.pixelSize: 24}
            Text { id:position; text: "Wolfsburg"; color: "lightgray"; font.pixelSize: 24}
            Text { id:weather; text: "21°C ☀️"; color: "lightgray"; font.pixelSize: 24}

            // App Switcher Buttons
            Row {
                id:appSwitcher
                spacing: 15
                anchors.right: parent.right
                anchors.margins: 10
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter

                Button { text: "Home"; onClicked: stackView.replace("Dashboard.qml"); palette.buttonText: "white"; font.pixelSize: 20 }
                Button { text: "Media"; onClicked: stackView.replace("MediaPlayer.qml"); palette.buttonText: "white"; font.pixelSize: 20 }
                Button { text: "Ambient Lighting"; onClicked: stackView.replace("AmbientLighting.qml"); palette.buttonText: "white"; font.pixelSize: 20 }
                Button { text: "Settings"; onClicked: stackView.replace("Settings.qml"); palette.buttonText: "white"; font.pixelSize: 20 }
            }
        }
    }

    // Gear Selector Sidebar
    Rectangle {
        id: gearSelector
        anchors.top: topbar.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: 80
        color: "#333"

        Column {
            anchors.centerIn: parent
            spacing: 100
            Button { text: "P"; font.pixelSize: 30; palette.buttonText: "white" }
            Button { text: "R"; font.pixelSize: 30; palette.buttonText: "white" }
            Button { text: "N"; font.pixelSize: 30; palette.buttonText: "white" }
            Button { text: "D"; font.pixelSize: 30; palette.buttonText: "white" }
        }
    }

    // Central App Area
    Rectangle {
        id: appArea
        anchors.top: topbar.bottom
        anchors.bottom: parent.bottom
        anchors.left: gearSelector.right
        anchors.right: parent.right
        color: "black"

        StackView {
            id: stackView
            anchors.fill: parent
            initialItem: "Dashboard.qml"
        }
    }
}
