import QtQuick
import QtQuick.Controls

Rectangle {
    id: searchBar
    width: parent.width
    height: 70
    color: "#f5f5f5"
    border.width: 1
    border.color: "#e0e0e0"

    signal searchTriggered(string query)
    signal inputFocusChanged(bool focused)

    property string inputText: searchInput.text
    property bool keyboardVisible: false

    // Search icon
    Text {
        x: 15
        y: (parent.height - height) / 2
        width: 40
        text: "🔍"
        font.pixelSize: 28
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    // Input background box
    Rectangle {
        x: 60
        y: 10
        width: parent.width - 115
        height: parent.height - 20
        border.width: searchInput.focus ? 2 : 1
        border.color: searchInput.focus ? "#4a90e2" : "#cccccc"
        color: "#ffffff"
        radius: 4

        // Text input field
        TextField {
            id: searchInput
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            placeholderText: "Search location..."
            font.pixelSize: 16
            color: "#333333"
            background: Rectangle {
                color: "transparent"
            }

            onFocusChanged: {
                searchBar.inputFocusChanged(focus);
            }

            onAccepted: {
                searchBar.searchTriggered(text);
            }
        }
    }

    // Search/Enter button
    Rectangle {
        x: parent.width - 50
        y: 10
        width: 40
        height: parent.height - 20
        radius: 4
        color: "#27ae60"

        Text {
            anchors.centerIn: parent
            text: "⏎"
            font.pixelSize: 20
            color: "#ffffff"
            font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                searchBar.searchTriggered(searchInput.text);
                searchInput.focus = false;
            }
            onPressed: parent.color = Qt.darker("#27ae60", 1.2);
            onReleased: parent.color = "#27ae60";
        }
    }
}
