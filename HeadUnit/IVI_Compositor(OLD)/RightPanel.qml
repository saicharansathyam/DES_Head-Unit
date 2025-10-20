import QtQuick 2.15

Item{

    id: root
    // ensure the WindowApp instance fills the space the parent gives it
    width: parent ? parent.width : 800
    height: parent ? parent.height : 600

    // Expose the internal container and bar heights so parent files
    // (like Main.qml) can reference them via the WindowApp instance.
    // Use a typed property to reference the internal Item.
    property Item appContainerRef: appContainer
    property Item areaPlacerHolderRef: areaPlaceholder
    // expose the placeholder content (used by Main.qml to hide placeholder content)
    property Item areaPlacerContentRef: areaPlaceholderContent
    // renamed to avoid name collision / binding-loop detection with compositor
    property int navBarH: 50
    property int statusBarH: 24

    Rectangle {
        id: appContainer
        anchors.fill: parent
        color: "#0f172a"

        // Stack the nav bar above the content area using a Column. Avoid using anchors
        // inside Column children; use explicit heights where appropriate.
        Column {
            id: containerColumn
            anchors.fill: parent
            spacing: 0

            // Navigation Bar
            Rectangle {
                id: navBar
                width: parent.width
                height: navBarH
                color: "#1a1f2e"

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: "#2d3548"
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 0

                    Item { width: parent.width * 0.4 }
                    Item { width: parent.width * 0.3 }
                }
            }

            // Content area - place app surfaces here
            Rectangle {
                id: areaPlaceholder
                width: parent.width
                height: parent.height - navBar.height
                visible: true
                color: "transparent"

                Column {
                    id: areaPlaceholderContent
                    anchors.centerIn: parent
                    spacing: 20

                    Rectangle {
                        width: 96
                        height: 96
                        radius: 48
                        color: "#1e293b"
                        anchors.horizontalCenter: parent.horizontalCenter

                        Text {
                            anchors.centerIn: parent
                            text: "\ud83d\ude97"
                            font.pixelSize: 48
                        }
                    }

                    Text {
                        text: "Application Area"
                        color: "#94a3b8"
                        font.pixelSize: 18
                        font.bold: true
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: "MediaPlayer \u2022 ThemeColor \u2022 Navigation"
                        color: "#64748b"
                        font.pixelSize: 12
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: "Waiting for applications..."
                        color: "#475569"
                        font.pixelSize: 11
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }

}
