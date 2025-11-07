import QtQuick
import QtQuick.Controls

Rectangle {
    id: youtubeView
    color: "#1a1a1a"
    
    Text {
        anchors.centerIn: parent
        text: "YouTube Playback\nNot Available\n\n(QtWebEngine disabled)"
        color: "#888888"
        font.pixelSize: 24
        horizontalAlignment: Text.AlignHCenter
    }
}
