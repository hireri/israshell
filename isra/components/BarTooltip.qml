import QtQuick
import Quickshell
import qs.style

Window {
    id: root
    width: tooltipContent.implicitWidth + 1
    height: tooltipContent.implicitHeight + 1
    color: "transparent"
    flags: Qt.ToolTip | Qt.FramelessWindowHint | Qt.WindowTransparentForInput

    property bool open: false

    visible: false

    onOpenChanged: {
        if (open) {
            closeTimer.stop();
            visible = true;
            tooltipContent.opacity = 1;
            tooltipContent.scale = 1.0;
        } else {
            tooltipContent.opacity = 0;
            tooltipContent.scale = 0.95;
            closeTimer.restart();
        }
    }

    Timer {
        id: closeTimer
        interval: 220
        onTriggered: root.visible = false
    }

    property string tipTitle: ""

    default property alias content: contentHolder.data
    readonly property bool hasCustomContent: contentHolder.children.length > 0

    property point targetPos: Qt.point(0, 0)
    property int yOffset: 8
    property int padding: 10

    x: targetPos.x - (width / 2)
    y: Config.bar.position === 1 ? targetPos.y - height - yOffset : targetPos.y + yOffset

    Rectangle {
        id: tooltipContent
        opacity: 0
        scale: 0.9
        implicitWidth: (root.hasCustomContent ? contentHolder.implicitWidth : tooltipText.implicitWidth) + root.padding * 2
        implicitHeight: (root.hasCustomContent ? contentHolder.implicitHeight : tooltipText.implicitHeight) + root.padding * 2
        width: implicitWidth
        height: implicitHeight
        color: Colors.md3.surface_container_high
        radius: 8
        border.width: 1
        border.color: Qt.alpha(Colors.md3.outline, 0.5)

        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        Text {
            id: tooltipText
            anchors.centerIn: parent
            text: root.tipTitle
            color: Colors.md3.on_surface
            font.pixelSize: 11
            visible: !root.hasCustomContent
        }

        Item {
            id: contentHolder
            anchors.fill: parent
            anchors.margins: root.padding
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
            visible: root.hasCustomContent
        }
    }
}
