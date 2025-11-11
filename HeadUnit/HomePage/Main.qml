import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: root
    width: 824
    height: 550
    visible: true
    title: qsTr("Home")

    // Integration hooks:
    // 1) If the host (compositor or app) exposes a context property named
    //    "launcher" with a method launch(appId), this QML will call it.
    // 2) Otherwise this QML emits the requestLaunch signal which the
    //    surrounding environment can listen to and act on (e.g. compositor)
    signal requestLaunch(string appId)

    // Helper wrapper so clicks go through integration if available
    function launchApp(appId) {
        console.debug("HomePage: launchApp ->", appId);
        try {
            if (typeof launcher !== 'undefined' && launcher && typeof launcher.launch === 'function') {
                launcher.launch(appId);
                return;
            }
        } catch (e) { console.debug('launcher call failed', e); }
        // Fallback: emit signal for external handler
        requestLaunch(appId);
    }

    Rectangle {
        anchors.fill: parent
        color: "#0a0e1a"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            // Tiles row
            RowLayout {
                Layout.fillWidth: true
                spacing: 20

                MapTile{
                    Layout.preferredHeight: 500
                    Layout.preferredWidth: 500
                }


                // Flexible spacer
                Item {
                    Layout.fillHeight: true
                }

                ColumnLayout{
                    Layout.fillWidth: true
                    spacing: 16

                    // Media Player tile
                    Rectangle {
                        id: mediaTile
                        Layout.preferredWidth: 240
                        Layout.preferredHeight: 240
                        radius: 12
                        color: "#081028"
                        border.color: "#264653"

                        MouseArea {
                            anchors.fill: parent
                            onClicked: launchApp("MediaPlayer")
                            hoverEnabled: true
                        }

                        Image {
                            source: "qrc:/images/play.png"
                            width: 64
                            height: 64
                            fillMode: Image.PreserveAspectFit
                        }
                    }

                    // Theme selector tile
                    Rectangle {
                        id: themeTile
                        Layout.preferredWidth: 240
                        Layout.preferredHeight: 240
                        radius: 12
                        color: "#081028"
                        border.color: "#264653"

                        MouseArea {
                            anchors.fill: parent
                            onClicked: launchApp("ThemeColor")
                            hoverEnabled: true
                        }
                        Text { text: qsTr("Theme Selector"); color: "#e6eef8"; font.pixelSize: 18; horizontalAlignment: Text.AlignHCenter; anchors.centerIn: parent}
                    }
                }
            }
        }
    }
}
