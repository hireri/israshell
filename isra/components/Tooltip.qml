import QtQuick
import Quickshell
import qs.style
import "tooltipWarmth.js" as Warmth

Item {
    id: root

    property bool open: false
    property string text: ""
    property Item anchorItem: null
    property bool suppressed: false
    property int showDelay: 400
    property bool above: false
    property int gap: 8
    property int padding: 10
    property real edgeMargin: 12

    default property alias content: contentHolder.data
    readonly property bool hasCustomContent: contentHolder.children.length > 0

    readonly property Item host: (QsWindow.window as QsWindow)?.contentItem ?? null
    readonly property bool shown: root._shown && !root.suppressed
    readonly property real tipWidth: tip.width
    readonly property real tipHeight: tip.height

    property real tipX: Math.round(Math.max(root.edgeMargin, Math.min(root._anchor.x + root._anchor.width / 2 - root.tipWidth / 2, (root.host?.width ?? 0) - root.tipWidth - root.edgeMargin)))
    property real tipY: root.above ? root._anchor.y - root.tipHeight - root.gap : root._anchor.y + root._anchor.height + root.gap

    property bool _shown: false
    property rect _anchor

    width: 0
    height: 0

    function show(anchor, text) {
        root.anchorItem = anchor;
        root.text = text ?? "";
        if (root.shown)
            root._place();
        root.open = true;
    }

    function hide() {
        root.open = false;
    }

    function _place() {
        if (!root.anchorItem || !root.host)
            return;
        const p = root.anchorItem.mapToItem(root.host, 0, 0);
        root._anchor = Qt.rect(p.x, p.y, root.anchorItem.width, root.anchorItem.height);
    }

    function _reveal() {
        if (root.suppressed)
            return;
        root._place();
        root._shown = true;
    }

    onOpenChanged: {
        if (root.open) {
            closeTimer.stop();
            if (root.showDelay > 0 && !Warmth.warm())
                showTimer.restart();
            else
                root._reveal();
        } else {
            showTimer.stop();
            closeTimer.restart();
        }
    }

    on_ShownChanged: Warmth.shownChanged(root._shown)

    onSuppressedChanged: {
        if (root.suppressed) {
            showTimer.stop();
            closeTimer.stop();
            root._shown = false;
        }
    }

    Timer {
        id: showTimer
        interval: root.showDelay
        onTriggered: root._reveal()
    }

    Timer {
        id: closeTimer
        interval: 220
        onTriggered: root._shown = false
    }

    Rectangle {
        id: tip

        parent: root.host
        z: 100
        visible: root.shown
        x: root.tipX
        y: root.tipY

        implicitWidth: (root.hasCustomContent ? contentHolder.implicitWidth : label.implicitWidth) + root.padding * 2
        implicitHeight: (root.hasCustomContent ? contentHolder.implicitHeight : label.implicitHeight) + root.padding * 2
        width: implicitWidth
        height: implicitHeight

        opacity: root.open && root._shown ? 1 : 0
        scale: root.open && root._shown ? 1 : 0.9
        color: Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)
        radius: 8
        border.width: 1
        border.color: Qt.alpha(Colors.md3.outline, 0.5)

        Behavior on opacity {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        Text {
            id: label
            anchors.centerIn: parent
            text: root.text
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
