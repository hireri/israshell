import QtQuick
import qs.style

Rectangle {
    id: root

    property real value: 0
    property real shown: Math.max(0, Math.min(1, root.value || 0))
    property color fillColor: Colors.md3.primary

    implicitWidth: 120
    implicitHeight: 8
    radius: 4
    color: Config.dim(Colors.md3.surface_container_highest)
    clip: true

    Behavior on shown {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    Rectangle {
        height: parent.height
        width: parent.width * root.shown
        radius: root.radius
        color: root.fillColor

    }
}
