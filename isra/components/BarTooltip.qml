import QtQuick
import Quickshell
import qs.style

Window {
    id: root
    visible: false
    width: tooltipContent.width
    height: tooltipContent.height
    color: "transparent"
    flags: Qt.ToolTip | Qt.FramelessWindowHint | Qt.WindowTransparentForInput

    property string tipTitle: ""
    property point targetPos: Qt.point(0, 0)
    property int yOffset: 8

    x: targetPos.x - (width / 2)
    y: Config.bar.position === 1 ? targetPos.y - height - yOffset : targetPos.y + yOffset

    onVisibleChanged: {
        if (visible) {
            fadeIn.restart();
        } else {
            tooltipContent.opacity = 0;
            tooltipContent.scale = 0.9;
        }
    }

    ParallelAnimation {
        id: fadeIn
        NumberAnimation {
            target: tooltipContent
            property: "opacity"
            from: 0
            to: 1
            duration: 150
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: tooltipContent
            property: "scale"
            from: 0.9
            to: 1.0
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        id: tooltipContent
        opacity: 0
        scale: 0.9
        implicitWidth: tooltipText.implicitWidth + 16
        height: tooltipText.implicitHeight + 12
        color: Colors.md3.surface_container_highest
        radius: 8
        border.width: 1
        border.color: Qt.alpha(Colors.md3.outline, 0.5)

        Text {
            id: tooltipText
            anchors.centerIn: parent
            text: root.tipTitle
            color: Colors.md3.on_surface
            font.pixelSize: 11
        }
    }
}
