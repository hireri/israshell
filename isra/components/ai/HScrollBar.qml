pragma ComponentBehavior: Bound

import QtQuick
import qs.style

Item {
    id: root

    required property real contentX
    required property real contentWidth
    required property real viewWidth

    signal seek(real newContentX)

    height: 4
    visible: root.contentWidth > root.viewWidth + 1

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Qt.alpha(Colors.md3.on_surface_variant, 0.12)
    }

    Rectangle {
        id: thumb
        height: parent.height
        radius: height / 2
        color: Qt.alpha(Colors.md3.on_surface_variant, dragMa.pressed || dragMa.containsMouse ? 0.7 : 0.4)
        width: Math.max(24, root.width * (root.viewWidth / Math.max(root.contentWidth, 1)))
        x: {
            const range = Math.max(root.contentWidth - root.viewWidth, 1);
            return (root.contentX / range) * (root.width - width);
        }

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
    }

    MouseArea {
        id: dragMa
        anchors.fill: parent
        anchors.topMargin: -6
        anchors.bottomMargin: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        function _seek(mouseX: real): void {
            const span = Math.max(root.width - thumb.width, 1);
            const pos = Math.max(0, Math.min(span, mouseX - thumb.width / 2));
            const range = Math.max(root.contentWidth - root.viewWidth, 1);
            root.seek((pos / span) * range);
        }

        onPressed: mouse => _seek(mouse.x)
        onPositionChanged: mouse => {
            if (pressed)
                _seek(mouse.x);
        }
    }
}
