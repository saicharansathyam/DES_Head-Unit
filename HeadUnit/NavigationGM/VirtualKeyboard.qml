import QtQuick

Rectangle {
    id: keyboard
    width: parent.width
    height: 200
    color: "#2d2d2d"
    border.width: 1
    border.color: "#555555"

    signal keyPressed(string key)
    signal backspacePressed()
    signal enterPressed()
    signal spacePressed()

    property bool shift: false
    property int keyWidth: 35
    property int keyHeight: 40
    property int keySpacing: 5

    // Rows definition
    property var row1: ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
    property var row2: ["A", "S", "D", "F", "G", "H", "J", "K", "L"]
    property var row3: ["Z", "X", "C", "V", "B", "N", "M"]

    Column {
        anchors.fill: parent
        anchors.margins: 8
        spacing: keyboard.keySpacing

        // Row 1
        Row {
            spacing: keyboard.keySpacing
            Repeater {
                model: keyboard.row1
                KeyButton {
                    width: keyboard.keyWidth
                    height: keyboard.keyHeight
                    label: keyboard.shift ? modelData : modelData.toLowerCase()
                    onKeyClicked: keyboard.keyPressed(keyboard.shift ? modelData : modelData.toLowerCase())
                }
            }
        }

        // Row 2
        Row {
            spacing: keyboard.keySpacing
            x: 15

            Repeater {
                model: keyboard.row2
                KeyButton {
                    width: keyboard.keyWidth
                    height: keyboard.keyHeight
                    label: keyboard.shift ? modelData : modelData.toLowerCase()
                    onKeyClicked: keyboard.keyPressed(keyboard.shift ? modelData : modelData.toLowerCase())
                }
            }
        }

        // Row 3 with Shift and Backspace
        Row {
            spacing: keyboard.keySpacing

            // Shift button
            KeyButton {
                width: 60
                height: keyboard.keyHeight
                label: "Shift"
                backgroundColor: keyboard.shift ? "#4a90e2" : "#555555"
                onKeyClicked: keyboard.shift = !keyboard.shift;
            }

            Repeater {
                model: keyboard.row3
                KeyButton {
                    width: keyboard.keyWidth
                    height: keyboard.keyHeight
                    label: keyboard.shift ? modelData : modelData.toLowerCase()
                    onKeyClicked: {
                        keyboard.keyPressed(keyboard.shift ? modelData : modelData.toLowerCase());
                        if (keyboard.shift) keyboard.shift = false;
                    }
                }
            }

            // Backspace button
            KeyButton {
                width: 60
                height: keyboard.keyHeight
                label: "⌫"
                backgroundColor: "#e74c3c"
                onKeyClicked: keyboard.backspacePressed();
            }
        }

        // Number and special characters row
        Row {
            spacing: keyboard.keySpacing

            Repeater {
                model: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
                KeyButton {
                    width: keyboard.keyWidth
                    height: keyboard.keyHeight
                    label: modelData
                    onKeyClicked: keyboard.keyPressed(modelData);
                }
            }
        }

        // Space and Enter row
        Row {
            spacing: keyboard.keySpacing
            x: (parent.width - childrenRect.width) / 2

            // Common symbols
            KeyButton {
                width: keyboard.keyWidth
                height: keyboard.keyHeight
                label: "."
                onKeyClicked: keyboard.keyPressed(".");
            }

            KeyButton {
                width: keyboard.keyWidth
                height: keyboard.keyHeight
                label: ","
                onKeyClicked: keyboard.keyPressed(",");
            }

            KeyButton {
                width: keyboard.keyWidth
                height: keyboard.keyHeight
                label: "-"
                onKeyClicked: keyboard.keyPressed("-");
            }

            // Space button
            KeyButton {
                width: 150
                height: keyboard.keyHeight
                label: "Space"
                onKeyClicked: keyboard.spacePressed();
            }

            KeyButton {
                width: keyboard.keyWidth
                height: keyboard.keyHeight
                label: "@"
                onKeyClicked: keyboard.keyPressed("@");
            }

            // Enter button
            KeyButton {
                width: 80
                height: keyboard.keyHeight
                label: "Enter"
                backgroundColor: "#27ae60"
                onKeyClicked: keyboard.enterPressed();
            }
        }
    }
}
