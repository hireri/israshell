import QtQuick
import qs.style

Item {
    id: root

    property bool open: false
    property string tipTitle: ""
    property var panelWindow: null

    default property alias content: contentHolder.data
    readonly property bool hasCustomContent: contentHolder.children.length > 0

    property point targetPos: Qt.point(0, 0)
    property int yOffset: 8
    property int padding: 10
    property real edgeMargin: 12

    width: 0
    height: 0

    property bool _shown: false
    onOpenChanged: {
        if (open) {
            closeTimer.stop();
            _shown = true;
        } else {
            closeTimer.restart();
        }
    }

    Timer {
        id: closeTimer
        interval: 220
        onTriggered: root._shown = false
    }

    Rectangle {
        id: tooltipContent

        parent: root.panelWindow?.contentItem ?? null
        z: 100
        visible: root._shown

        readonly property real barHeight: root.panelWindow?.barHeight ?? 0

        implicitWidth: (root.hasCustomContent ? contentHolder.implicitWidth : tooltipText.implicitWidth) + root.padding * 2
        implicitHeight: (root.hasCustomContent ? contentHolder.implicitHeight : tooltipText.implicitHeight) + root.padding * 2
        width: implicitWidth
        height: implicitHeight

        y: Config.bar.position === 1
            ? ((root.panelWindow?.height ?? 0) - barHeight - height - root.yOffset)
            : (barHeight + root.yOffset)

        x: {
            const winW = root.panelWindow?.width ?? 0;
            const raw = (root.targetPos.x - (root.panelWindow?.screen?.x ?? 0)) - (width / 2);
            return Math.round(Math.max(root.edgeMargin, Math.min(raw, winW - width - root.edgeMargin)));
        }

        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.9
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
