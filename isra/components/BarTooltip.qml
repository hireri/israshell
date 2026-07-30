import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.style

PanelWindow {
    id: root

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:tooltip"
    color: "transparent"
    mask: Region {}

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
    property var panelWindow: null

    default property alias content: contentHolder.data
    readonly property bool hasCustomContent: contentHolder.children.length > 0

    property point targetPos: Qt.point(0, 0)
    property int yOffset: 8
    property int padding: 10
    property real edgeMargin: 12

    readonly property bool blurEnabled: Config.blurAllowed(root.visible)
    BackgroundEffect.blurRegion: blurEnabled ? tooltipBlurRegion : null

    Region {
        id: tooltipBlurRegion
        x: tooltipContent.x
        y: tooltipContent.y
        width: tooltipContent.width
        height: tooltipContent.height
        radius: tooltipContent.radius
    }

    Rectangle {
        id: tooltipContent

        readonly property real barHeight: root.panelWindow ? root.panelWindow.implicitHeight : 0

        implicitWidth: (root.hasCustomContent ? contentHolder.implicitWidth : tooltipText.implicitWidth) + root.padding * 2
        implicitHeight: (root.hasCustomContent ? contentHolder.implicitHeight : tooltipText.implicitHeight) + root.padding * 2
        width: implicitWidth
        height: implicitHeight

        y: Config.bar.position === 1
            ? (root.height - barHeight - height - root.yOffset)
            : (barHeight + root.yOffset)

        x: {
            const raw = (root.targetPos.x - (root.screen ? root.screen.x : 0)) - (width / 2);
            return Math.round(Math.max(root.edgeMargin, Math.min(raw, root.width - width - root.edgeMargin)));
        }
        opacity: 0
        scale: 0.9
        color: Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)
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
