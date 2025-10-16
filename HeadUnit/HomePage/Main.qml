import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtLocation
import QtPositioning

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

                // Navigation tile
                Rectangle {
                    id: navTile
                    Layout.preferredWidth: 500
                    Layout.preferredHeight: 500
                    radius: 12
                    color: "#081028"
                    border.color: "#264653"

                    MouseArea {
                        anchors.fill: parent
                        onClicked: launchApp("Navigation")
                        hoverEnabled: true
                    }

                    Plugin {
                        id: mapPlugin
                        name: "osm"
                    }

                    Map{
                        id: map
                        anchors.fill: parent
                        plugin: mapPlugin
                        center: QtPositioning.coordinate(52.42445159395511, 10.79219202248994) // SEA_ME
                        zoomLevel: 20
                        property geoCoordinate startCentroid
                    }
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
                        Column {
                            anchors.centerIn: parent
                            spacing: 12
                            Image {
                                source: "../MediaPlayer/icons/play.svg"
                                width: 64
                                height: 64
                                fillMode: Image.PreserveAspectFit
                            }
                            Text { text: qsTr("Media Player"); color: "#e6eef8"; font.pixelSize: 18; horizontalAlignment: Text.AlignHCenter }
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
                        Column {
                            anchors.centerIn: parent
                            spacing: 12
                            Rectangle { width: 64; height: 64; radius: 8; color: "#1f2937" }
                            Text { text: qsTr("Theme Selector"); color: "#e6eef8"; font.pixelSize: 18; horizontalAlignment: Text.AlignHCenter }
                        }
                    }
                }
            }
        }
    }
}
