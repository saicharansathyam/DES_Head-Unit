import QtQuick 2.15
import QtQuick.Layouts 1.15

RowLayout {
    width: parent.width
    height: 50
    spacing: 20
    Rectangle { width: 1; height: 50; color: "transparent" } // Spacer

    Text { text: "Wolfsburg"; color: "white"; font.pixelSize: 20 }
    Text { text: Qt.formatTime(new Date(), "hh:mm"); color: "white"; font.pixelSize: 20 }
    Text { text: "21°C ☀️"; color: "white"; font.pixelSize: 20 }
}
