import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtWayland.Compositor

Window {
    width: 1200
    height: 600
    visible: true
    title: qsTr("IVI Compositor")

    WaylandCompositor {
        id: compositor
        socketName: "wayland-ivi"
    }

    Rectangle {
        anchors.fill: parent
        color: "#222"

        RowLayout {
            anchors.fill: parent

            WaylandQuickItem {
                id: gearSelectorItem
                width: 200
                height: parent.height
                surface: iviCompositor.gearSelectorSurface
            }

            WaylandQuickItem {
                id: mediaPlayerItem
                width: parent.width - gearSelectorItem.width
                height: parent.height
                surface: iviCompositor.mediaPlayerSurface
            }
        }
    }
}
