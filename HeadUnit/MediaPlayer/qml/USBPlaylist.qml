import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property var mediaFiles: []
    property int currentTrackIndex: -1
    property color accentColor: "#3b82f6"
    property color secondaryColor: "#334155"

    signal mediaFileSelected(int index)
    signal refreshRequested()

    Rectangle {
        anchors.fill: parent
        color: "#0f172a"
        border.color: "#334155"
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Header with count and refresh
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: secondaryColor

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Label {
                        text: "Playlist"
                        color: "white"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Rectangle {
                        Layout.preferredWidth: 45
                        Layout.preferredHeight: 22
                        color: accentColor
                        radius: 11

                        Label {
                            anchors.centerIn: parent
                            text: mediaFiles.length.toString()
                            color: "white"
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        Layout.preferredWidth: 30
                        Layout.preferredHeight: 30
                        text: "⟳"
                        font.pixelSize: 14

                        background: Rectangle {
                            color: parent.pressed ? Qt.darker(accentColor, 1.2) :
                                   parent.hovered ? Qt.lighter(accentColor, 1.1) : accentColor
                            radius: 4
                        }

                        contentItem: Text {
                            text: parent.text
                            font: parent.font
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: root.refreshRequested()
                    }
                }
            }

            // Playlist view
            ListView {
                id: playlistView
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: mediaFiles
                clip: true
                spacing: 1

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    width: 8
                }

                delegate: Rectangle {
                    width: playlistView.width - 8
                    height: 55
                    color: index === currentTrackIndex ? accentColor :
                           mouseArea.pressed ? Qt.darker(secondaryColor, 1.3) :
                           mouseArea.containsMouse ? Qt.lighter(secondaryColor, 1.1) :
                           index % 2 === 0 ? secondaryColor : Qt.darker(secondaryColor, 1.05)

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Rectangle {
                            width: 30
                            height: 30
                            radius: 15
                            color: index === currentTrackIndex ? "white" : accentColor
                            Layout.alignment: Qt.AlignVCenter

                            Label {
                                anchors.centerIn: parent
                                text: (index + 1).toString()
                                color: index === currentTrackIndex ? accentColor : "white"
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: 3

                            Label {
                                text: modelData
                                color: "white"
                                font.pixelSize: 11
                                font.bold: index === currentTrackIndex
                                elide: Text.ElideMiddle
                                width: parent.width
                            }

                            Label {
                                text: getFileExtension(modelData).toUpperCase()
                                color: index === currentTrackIndex ? "#e0e0e0" : "#9ca3af"
                                font.pixelSize: 9
                            }
                        }

                        Text {
                            text: index === currentTrackIndex ? "♪" : "▶"
                            color: index === currentTrackIndex ? "white" : accentColor
                            font.pixelSize: 18
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            root.mediaFileSelected(index)
                        }
                    }
                }

                // Empty state
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.9
                    height: 180
                    color: "transparent"
                    visible: mediaFiles.length === 0

                    Column {
                        anchors.centerIn: parent
                        spacing: 20

                        Text {
                            text: "🎵"
                            font.pixelSize: 50
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Label {
                            text: "No Media Files"
                            color: "#9ca3af"
                            font.pixelSize: 16
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Label {
                            text: "Insert a USB drive with media files\nor use the refresh button"
                            color: "#6b7280"
                            font.pixelSize: 11
                            anchors.horizontalCenter: parent.horizontalCenter
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            width: 220
                        }
                    }
                }
            }
        }
    }

    function getFileExtension(fileName) {
        var parts = fileName.split('.')
        return parts.length > 1 ? parts[parts.length - 1] : ""
    }
}
