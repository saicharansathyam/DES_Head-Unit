import QtQuick 2.15

Item {

    id: root
    // runtime-exposed reference to the inner placeholder (assigned on component completion)
    // exposed runtime reference to the inner placeholder Rectangle so the
    // compositor can parent GearSelector surfaces into it. Initialize to
    // null and assign in Component.onCompleted to avoid alias/parse-time
    // ordering issues.
    property Item leftPanelRef: null;
    // Do not bind width/height to the parent's size here; the instance
    // (in Main.qml) should set `width` and `height`. Provide sensible
    // fallbacks at component completion if the instance didn't set them.

    // Left panel - GearSelector
    Rectangle {
        id: leftPanel
        anchors.fill: parent
        color: "#111827"

        Rectangle {
            id: leftPlaceholder
            anchors.fill: parent
            visible: true
            color: "transparent"

            Column {
                anchors.centerIn: parent
                spacing: 12

                Rectangle {
                    width: 64
                    height: 64
                    radius: 32
                    color: "#1f2937"
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "⚙"
                        color: "#4b5563"
                        font.pixelSize: 32
                    }
                }

                Text {
                    text: "GearSelector"
                    color: "#6b7280"
                    font.pixelSize: 14
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "Waiting..."
                    color: "#4b5563"
                    font.pixelSize: 11
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    Component.onCompleted: {
        // assign the runtime ref so external QML can access the inner placeholder
        leftPanelRef = leftPlaceholder;
        // fallback sizes if the instance didn't provide width/height
        try {
            if (!root.width || root.width === 0) root.width = 200;
            if (!root.height || root.height === 0) root.height = 600;
        } catch(e) {}
    }

}
