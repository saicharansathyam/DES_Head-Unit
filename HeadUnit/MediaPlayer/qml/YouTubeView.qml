import QtQuick
import QtQuick.Controls
import QtWebView

Item {
    id: root

    property color accentColor: "#3b82f6"
    property color secondaryColor: "#334155"

    Rectangle {
        anchors.fill: parent
        color: "#000000"

        // YouTube using QtWebView
        WebView {
            id: youtubeView
            anchors.fill: parent
            url: "https://www.youtube.com"

            onLoadingChanged: function(loadRequest) {
                if (loadRequest.status === WebView.LoadSucceededStatus) {
                    console.log("YouTube loaded successfully")
                    loadingIndicator.visible = false

                    // Inject JavaScript to detect focus on input fields
                    youtubeView.runJavaScript(
                        "(function() {" +
                        "  document.addEventListener('focusin', function(e) {" +
                        "    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA' || " +
                        "        e.target.contentEditable === 'true') {" +
                        "      console.log('Input field focused');" +
                        "      Qt.inputMethod.show();" +
                        "    }" +
                        "  });" +
                        "  document.addEventListener('focusout', function(e) {" +
                        "    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA' || " +
                        "        e.target.contentEditable === 'true') {" +
                        "      console.log('Input field unfocused');" +
                        "      Qt.inputMethod.hide();" +
                        "    }" +
                        "  });" +
                        "})();"
                    )
                } else if (loadRequest.status === WebView.LoadFailedStatus) {
                    console.error("Failed to load YouTube:", loadRequest.errorString)
                    errorDisplay.visible = true
                    loadingIndicator.visible = false
                } else if (loadRequest.status === WebView.LoadStartedStatus) {
                    console.log("Loading YouTube...")
                    loadingIndicator.visible = true
                    errorDisplay.visible = false
                }
            }

            onLoadProgressChanged: {
                loadingIndicator.progress = loadProgress
            }

            Component.onCompleted: {
                console.log("YouTubeView (QtWebView) initialized")
            }
        }

        // Loading indicator
        Rectangle {
            id: loadingIndicator
            anchors.centerIn: parent
            width: 120
            height: 120
            radius: 12
            color: root.secondaryColor
            opacity: 0.95
            visible: true

            property int progress: 0

            Column {
                anchors.centerIn: parent
                spacing: 18

                // Animated loading spinner
                Item {
                    width: 60
                    height: 60
                    anchors.horizontalCenter: parent.horizontalCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: "transparent"
                        border.width: 4
                        border.color: root.accentColor
                        opacity: 0.3
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: "transparent"
                        border.width: 4
                        border.color: root.accentColor

                        Rectangle {
                            width: 10
                            height: 10
                            radius: 5
                            color: root.accentColor
                            x: parent.width / 2 - width / 2
                            y: 0
                        }

                        RotationAnimation on rotation {
                            loops: Animation.Infinite
                            from: 0
                            to: 360
                            duration: 1200
                        }
                    }
                }

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8

                    Label {
                        text: "Loading YouTube..."
                        color: "white"
                        font.pixelSize: 13
                        font.bold: true
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Label {
                        text: loadingIndicator.progress + "%"
                        color: root.accentColor
                        font.pixelSize: 11
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }

        // Error display
        Rectangle {
            id: errorDisplay
            anchors.centerIn: parent
            width: parent.width * 0.7
            height: 200
            radius: 10
            color: root.secondaryColor
            border.color: "#ef4444"
            border.width: 2
            visible: false

            Column {
                anchors.centerIn: parent
                spacing: 20
                width: parent.width - 40

                Text {
                    text: "⚠️"
                    font.pixelSize: 40
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Label {
                    text: "YouTube Load Error"
                    color: "white"
                    font.pixelSize: 16
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Label {
                    text: "Could not connect to YouTube"
                    color: "#9ca3af"
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                }

                Button {
                    text: "Retry"
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 120
                    height: 40

                    background: Rectangle {
                        color: parent.pressed ? Qt.darker(root.accentColor, 1.2) : root.accentColor
                        radius: 6
                    }

                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 13
                        font.bold: true
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        errorDisplay.visible = false
                        youtubeView.reload()
                    }
                }
            }
        }
    }
}
