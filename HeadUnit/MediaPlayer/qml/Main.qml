import QtQuick
import QtQuick.Controls
import QtQuick.VirtualKeyboard

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 824
    height: 470
    title: "Media Player"
    color: "#0f172a"

    property string currentSource: "USB"
    property bool showPlaylist: false  // Toggle between MediaDisplay and Playlist

    Rectangle {
        anchors.fill: parent
        color: "#0f172a"

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            // Header with dropdown source selector and playlist button
            Row {
                width: parent.width
                height: 50
                spacing: 15

                // Source Selector Dropdown
                ComboBox {
                    id: sourceComboBox
                    width: 180
                    height: 40
                    anchors.verticalCenter: parent.verticalCenter

                    model: ["USB", "Bluetooth", "YouTube"]
                    currentIndex: 0

                    delegate: ItemDelegate {
                        width: sourceComboBox.width
                        contentItem: Row {
                            spacing: 8
                            leftPadding: 12

                            Text {
                                text: {
                                    if (modelData === "USB") return "💾"
                                    if (modelData === "Bluetooth") return "📡"
                                    if (modelData === "YouTube") return "▶"
                                    return ""
                                }
                                font.pixelSize: 18
                                color: highlighted ? "white" : "#94a3b8"
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: modelData
                                font.pixelSize: 14
                                color: highlighted ? "white" : "#94a3b8"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        highlighted: sourceComboBox.highlightedIndex === index
                        background: Rectangle {
                            color: highlighted ? theme.themeColor : "#1e293b"
                        }
                    }

                    background: Rectangle {
                        color: sourceComboBox.pressed ? theme.buttonPressedColor : theme.themeColor
                        radius: 8
                        border.width: 1
                        border.color: theme.accentColor

                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    contentItem: Row {
                        spacing: 8
                        leftPadding: 12

                        Text {
                            text: {
                                if (sourceComboBox.currentText === "USB") return "💾"
                                if (sourceComboBox.currentText === "Bluetooth") return "📡"
                                if (sourceComboBox.currentText === "YouTube") return "▶"
                                return ""
                            }
                            font.pixelSize: 18
                            color: "white"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: sourceComboBox.currentText
                            font.pixelSize: 14
                            font.bold: true
                            color: "white"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    popup: Popup {
                        y: sourceComboBox.height
                        width: sourceComboBox.width
                        implicitHeight: contentItem.implicitHeight
                        padding: 1

                        contentItem: ListView {
                            clip: true
                            implicitHeight: contentHeight
                            model: sourceComboBox.popup.visible ? sourceComboBox.delegateModel : null
                            currentIndex: sourceComboBox.highlightedIndex
                        }

                        background: Rectangle {
                            color: "#1e293b"
                            border.color: theme.accentColor
                            radius: 8
                        }
                    }

                    onCurrentTextChanged: {
                        currentSource = currentText
                        showPlaylist = false  // Reset to MediaDisplay on source change
                        console.log("Source changed to:", currentSource)
                    }
                }

                Rectangle {
                    width: 100
                    height: 35
                    radius: 17.5
                    color: mpHandler.isPlaying ? theme.themeColor : "#334155"
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on color { ColorAnimation { duration: 300 } }

                    Text {
                        anchors.centerIn: parent
                        text: mpHandler.isPlaying ? "PLAYING" : "PAUSED"
                        color: "white"
                        font.pixelSize: 12
                        font.bold: true
                    }
                }

                // Playlist Toggle Button (only for USB)
                Button {
                    id: playlistButton
                    width: 50
                    height: 40
                    visible: currentSource === "USB"
                    anchors.verticalCenter: parent.verticalCenter

                    background: Rectangle {
                        color: {
                            if (parent.pressed) return theme.buttonPressedColor
                            if (showPlaylist) return theme.themeColor
                            if (parent.hovered) return theme.buttonHoverColor
                            return "#1e293b"
                        }
                        radius: 8
                        border.width: showPlaylist ? 2 : 1
                        border.color: showPlaylist ? theme.accentColor : "#334155"

                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    contentItem: Text {
                        text: "♫"
                        font.pixelSize: 24
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        showPlaylist = !showPlaylist
                        console.log("Playlist view:", showPlaylist)
                    }
                }
            }

            // Context Switcher: MediaDisplay/Playlist or YouTubeView
            Loader {
                id: contextLoader
                width: parent.width
                height: parent.height - 40

                sourceComponent: currentSource === "YouTube" ? youtubeContext :
                                (showPlaylist && currentSource === "USB" ? playlistContext : mediaDisplayContext)

                Component {
                    id: mediaDisplayContext

                    // MediaDisplay with integrated ProgressBar and Controls
                    Column {
                        width: parent.width
                        spacing: 15

                        MediaDisplay {
                            id: mediaDisplay
                            width: parent.width
                            height: 180
                        }

                        MediaProgressBar {
                            id: mprogressBar
                            width: parent.width
                            height: 50
                        }

                        MediaControls {
                            id: mediaControls
                            width: parent.width
                            height: 90
                        }
                    }
                }

                Component {
                    id: playlistContext

                    // USB Playlist View
                    USBPlaylist {
                        width: parent.width
                        height: parent.height

                        // Signal from USBPlaylist when song is selected
                        onSongSelected: {
                            showPlaylist = false  // Switch back to MediaDisplay
                            console.log("Song selected, returning to MediaDisplay")
                        }
                    }
                }

                Component {
                    id: youtubeContext

                    // Full YouTube View
                    Loader {
                        anchors.fill: parent
                        source: "qrc:/qml/YouTubeView.qml"
                        onStatusChanged: {
                            if (status === Loader.Error) {
                                console.log("Error loading YouTube")
                            } else if (status === Loader.Ready) {
                                console.log("YouTube loaded successfully")
                            }
                        }
                    }
                }
            }
        }
    }

    // Virtual Keyboard - appears at bottom when text input is focused
    InputPanel {
        id: inputPanel
        z: 99
        x: 0
        y: mainWindow.height - inputPanel.height
        width: mainWindow.width
        visible: active
    }
}
