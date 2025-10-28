import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.VirtualKeyboard

ApplicationWindow {
    id: root
    width: 824
    height: 550
    visible: true
    title: "MediaPlayer"

    readonly property color primaryColor: "#1e293b"
    readonly property color secondaryColor: "#334155"
    readonly property color accentColor: "#3b82f6"
    readonly property color errorColor: "#ef4444"
    readonly property color successColor: "#10b981"

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: primaryColor }
            GradientStop { position: 1.0; color: "#0f172a" }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Header with dropdown source selector
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                color: Qt.darker(primaryColor, 1.2)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 12

                    Label {
                        text: "Source:"
                        color: "white"
                        font.pixelSize: 14
                        font.bold: true
                    }

                    ComboBox {
                        id: sourceComboBox
                        Layout.preferredWidth: 200
                        Layout.preferredHeight: 35

                        model: ["💾 USB", "📺 YouTube"]
                        currentIndex: mpHandler.sourceType === "youtube" ? 1 : 0

                        background: Rectangle {
                            color: "#1e293b"
                            radius: 6
                            border.color: sourceComboBox.pressed ? accentColor : "#64748b"
                            border.width: 2
                        }

                        contentItem: Text {
                            leftPadding: 12
                            rightPadding: sourceComboBox.indicator.width + sourceComboBox.spacing
                            text: sourceComboBox.displayText
                            font.pixelSize: 14
                            color: "white"
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        delegate: ItemDelegate {
                            width: sourceComboBox.width
                            contentItem: Text {
                                text: sourceComboBox.model[index]
                                color: sourceComboBox.highlightedIndex === index ? accentColor : "white"
                                font.pixelSize: 14
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 12
                            }
                            highlighted: sourceComboBox.highlightedIndex === index

                            background: Rectangle {
                                color: highlighted ? Qt.lighter(secondaryColor, 1.2) : secondaryColor
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

                                ScrollIndicator.vertical: ScrollIndicator { }
                            }

                            background: Rectangle {
                                color: secondaryColor
                                border.color: accentColor
                                border.width: 1
                                radius: 6
                            }
                        }

                        onActivated: function(index) {
                            if (index === 0) {
                                mpHandler.sourceType = "usb"
                            } else {
                                mpHandler.sourceType = "youtube"
                            }
                        }
                    }

                    Label {
                        text: mpHandler.usbDevices.length > 0 ? "USB Available" : "No USB"
                        color: mpHandler.usbDevices.length > 0 ? successColor : "#9ca3af"
                        font.pixelSize: 11
                        visible: mpHandler.sourceType === "usb"
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: mpHandler.serviceConnected ? successColor : errorColor
                        Layout.alignment: Qt.AlignVCenter

                        SequentialAnimation on opacity {
                            running: mpHandler.serviceConnected
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.3; duration: 1000 }
                            NumberAnimation { to: 1.0; duration: 1000 }
                        }
                    }
                }
            }

            // Main content area
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // YouTube Mode
                Loader {
                    id: mediaDisplayLoader
                    anchors.fill: parent
                    visible: mpHandler.sourceType === "youtube"
                    source: visible ? "qrc:/qml/MediaDisplay.qml" : ""

                    onLoaded: {
                        item.sourceType = "youtube"
                        item.source = Qt.binding(function() { return mpHandler.source })
                        item.isPlaying = Qt.binding(function() { return mpHandler.playing })
                        item.currentFileName = ""
                        item.currentTrackIndex = -1
                    }
                }

                // USB Mode
                RowLayout {
                    anchors.fill: parent
                    spacing: 0
                    visible: mpHandler.sourceType === "usb"

                    Loader {
                        id: usbPlaylistLoader
                        Layout.preferredWidth: parent.width * 0.4
                        Layout.fillHeight: true
                        source: parent.visible ? "qrc:/qml/USBPlaylist.qml" : ""

                        onLoaded: {
                            item.mediaFiles = Qt.binding(function() { return mpHandler.mediaFiles })
                            item.currentTrackIndex = Qt.binding(function() { return mpHandler.currentTrackIndex })
                            item.accentColor = Qt.binding(function() { return root.accentColor })
                            item.secondaryColor = Qt.binding(function() { return root.secondaryColor })

                            item.mediaFileSelected.connect(function(idx) {
                                mpHandler.selectMediaFile(idx)
                            })
                            item.refreshRequested.connect(function() {
                                mpHandler.refreshUsbDevices()
                            })
                        }
                    }

                    Loader {
                        id: usbMediaDisplayLoader
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        source: parent.visible ? "qrc:/qml/MediaDisplay.qml" : ""

                        onLoaded: {
                            item.sourceType = "usb"
                            item.source = Qt.binding(function() { return mpHandler.source })
                            item.isPlaying = Qt.binding(function() { return mpHandler.playing })
                            item.currentFileName = Qt.binding(function() { return mpHandler.currentFileName })
                            item.currentTrackIndex = Qt.binding(function() { return mpHandler.currentTrackIndex })
                            item.accentColor = Qt.binding(function() { return root.accentColor })
                            item.secondaryColor = Qt.binding(function() { return root.secondaryColor })
                        }
                    }
                }
            }

            // Error display
            Rectangle {
                Layout.fillWidth: true
                height: errorLabel.text ? 35 : 0
                color: errorColor
                visible: height > 0

                Behavior on height { NumberAnimation { duration: 200 } }

                Label {
                    id: errorLabel
                    anchors.centerIn: parent
                    color: "white"
                    font.pixelSize: 12
                    text: ""

                    Connections {
                        target: mpHandler
                        function onMediaError(error) {
                            errorLabel.text = error
                            errorTimer.restart()
                        }
                    }

                    Timer {
                        id: errorTimer
                        interval: 5000
                        onTriggered: errorLabel.text = ""
                    }
                }
            }

            // Progress bar (USB only)
            Loader {
                id: progressBarLoader
                Layout.fillWidth: true
                Layout.preferredHeight: 45
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                visible: mpHandler.sourceType === "usb"
                source: visible ? "qrc:/qml/ProgressBar.qml" : ""

                onLoaded: {
                    item.position = Qt.binding(function() { return mpHandler.position })
                    item.duration = Qt.binding(function() { return mpHandler.duration })
                    item.accentColor = Qt.binding(function() { return root.accentColor })
                    item.secondaryColor = Qt.binding(function() { return root.secondaryColor })
                    item.seekRequested.connect(function(pos) {
                        mpHandler.seek(pos)
                    })
                }
            }

            // Control bar (USB only)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                color: primaryColor
                visible: mpHandler.sourceType === "usb"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Loader {
                        id: volumeControlLoader
                        Layout.fillHeight: true
                        Layout.preferredWidth: 160
                        source: parent.parent.visible ? "qrc:/qml/VolumeControl.qml" : ""

                        onLoaded: {
                            item.volume = Qt.binding(function() { return mpHandler.volume })
                            item.accentColor = Qt.binding(function() { return root.accentColor })
                            item.secondaryColor = Qt.binding(function() { return root.secondaryColor })
                            item.volumeChangeRequested.connect(function(vol) {
                                mpHandler.volume = vol
                            })
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Loader {
                        id: mediaControlsLoader
                        Layout.alignment: Qt.AlignCenter
                        source: parent.parent.visible ? "qrc:/qml/MediaControls.qml" : ""

                        onLoaded: {
                            item.isPlaying = Qt.binding(function() { return mpHandler.playing })
                            item.accentColor = Qt.binding(function() { return root.accentColor })
                            item.secondaryColor = Qt.binding(function() { return root.secondaryColor })

                            item.playClicked.connect(function() { mpHandler.play() })
                            item.pauseClicked.connect(function() { mpHandler.pause() })
                            item.stopClicked.connect(function() { mpHandler.stop() })
                            item.previousClicked.connect(function() { mpHandler.previous() })
                            item.nextClicked.connect(function() { mpHandler.next() })
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Item { Layout.preferredWidth: 160 }
                }
            }
        }
    }

    // Virtual Keyboard InputPanel
    InputPanel {
        id: inputPanel
        z: 1000
        width: parent.width
        y: inputPanel.active ? parent.height - inputPanel.height : parent.height
        anchors.horizontalCenter: parent.horizontalCenter

        Behavior on y {
            NumberAnimation {
                duration: 250
                easing.type: Easing.InOutQuad
            }
        }

        // Make keyboard visible when YouTube is active and input is focused
        states: State {
            name: "visible"
            when: inputPanel.active
            PropertyChanges {
                target: inputPanel
                y: root.height - inputPanel.height
            }
        }
    }

    // Monitor USB device changes
    Connections {
        target: mpHandler

        function onUsbDevicesChanged() {
            if (mpHandler.usbDevices.length === 0 && mpHandler.sourceType === "usb") {
                sourceComboBox.currentIndex = 1
                mpHandler.sourceType = "youtube"
            }
        }
    }
}
