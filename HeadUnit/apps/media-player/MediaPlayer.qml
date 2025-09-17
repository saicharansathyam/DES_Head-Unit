import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    width: 1000; height: 400
    color: "#111"

    Column {
        id: rootColumn
        anchors.centerIn: parent
        spacing: 30

        property var mediaController: MediaController

        Button { text: "Track 1"; onClicked: rootColumn.mediaController.playTrack1() }
        Button { text: "Track 2"; onClicked: rootColumn.mediaController.playTrack2() }
        Button { text: "Track 3"; onClicked: rootColumn.mediaController.playTrack3() }

        Text {
            text: "Playing: " + rootColumn.mediaController.currentTrack
            color: "white"
            font.pixelSize: 24
        }
    }
}
