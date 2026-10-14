import QtQuick
import Quickshell
import qs.style
import "tooltipWarmth.js" as Warmth

Item {
    id: root

    property bool open: false
    property string text: ""
    property Item anchorItem: root.parent
    property bool autoHover: true
    property bool suppressed: false
    property int showDelay: 400
    property bool above: false
    property string side: ""
    property bool flat: root.embedded
    property int gap: 8
    property int padding: 10
    property real edgeMargin: 12
    property real maxWidth: 280

    default property alias content: contentHolder.data
    readonly property bool hasCustomContent: contentHolder.children.length > 0

    readonly property Item host: (QsWindow.window as QsWindow)?.contentItem ?? null
    readonly property bool embedded: (QsWindow.window as FloatingWindow) !== null
    readonly property bool _want: root.open || (root._hovered && (root.text !== "" || root.hasCustomContent))
    readonly property bool shown: root._shown && !root.suppressed
    readonly property real tipWidth: (tipLoader.item as Item)?.width ?? 0
    readonly property real tipHeight: (tipLoader.item as Item)?.height ?? 0

    readonly property real _hostW: root.host?.width ?? 0
    readonly property real _hostH: root.host?.height ?? 0
    readonly property real _beside: root.side === "left" ? root._anchor.x - root.tipWidth - root.gap : root._anchor.x + root._anchor.width + root.gap
    readonly property real _below: root._anchor.y + root._anchor.height + root.gap
    readonly property real _aboveY: root._anchor.y - root.tipHeight - root.gap
    readonly property bool _preferAbove: root.side === "top" || root.above || (root.side === "" && root._anchor.y + root._anchor.height / 2 > root._hostH / 2)
    readonly property bool _fitsBelow: root._below + root.tipHeight <= root._hostH - root.edgeMargin
    readonly property bool _fitsAbove: root._aboveY >= root.edgeMargin

    property real tipX: Math.round(root._sideways ? root._beside : Math.max(root.edgeMargin, Math.min(root._anchor.x + root._anchor.width / 2 - root.tipWidth / 2, root._hostW - root.tipWidth - root.edgeMargin)))
    property real tipY: root._sideways ? Math.round(Math.max(root.edgeMargin, Math.min(root._anchor.y + (root._anchor.height - root.tipHeight) / 2, root._hostH - root.tipHeight - root.edgeMargin))) : (root._preferAbove ? (root._fitsAbove || !root._fitsBelow ? root._aboveY : root._below) : (root._fitsBelow || !root._fitsAbove ? root._below : root._aboveY))
    readonly property bool _sideways: root.side === "left" || root.side === "right"

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

    on_WantChanged: {
        if (root._want) {
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

    property bool _hovered: false
    property HoverHandler _hover: null

    function _attachHover() {
        if (root._hover) {
            root._hover.destroy();
            root._hover = null;
            root._hovered = false;
        }
        if (root.autoHover && root.anchorItem) {
            root._hover = hoverComp.createObject(root.anchorItem);
            root._hover.hoveredChanged.connect(() => root._hovered = root._hover.hovered);
        }
    }

    onAnchorItemChanged: root._attachHover()
    onAutoHoverChanged: root._attachHover()
    Component.onCompleted: root._attachHover()
    Component.onDestruction: if (root._hover) root._hover.destroy()

    Component {
        id: hoverComp
        HoverHandler {
            blocking: false
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

    Item {
        id: contentHolder
        parent: root.hasCustomContent && tipLoader.item ? (tipLoader.item as Item) : root
        anchors.fill: parent
        anchors.margins: root.padding
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
        visible: root.hasCustomContent
    }

    Loader {
        id: tipLoader
        active: root._shown || root.hasCustomContent
        sourceComponent: tipComponent
    }

    Component {
        id: tipComponent

        Rectangle {
            id: tip

            property bool ready: false
            Component.onCompleted: Qt.callLater(() => tip.ready = true)

            parent: root.host
            z: 100
            visible: root.shown
            x: root.tipX
            y: root.tipY

            implicitWidth: (root.hasCustomContent ? contentHolder.implicitWidth : label.width) + root.padding * 2
            implicitHeight: (root.hasCustomContent ? contentHolder.implicitHeight : label.implicitHeight) + root.padding * 2
            width: implicitWidth
            height: implicitHeight

            opacity: tip.ready && root._want && root._shown ? 1 : 0
            scale: tip.ready && root._want && root._shown ? 1 : 0.9
            color: root.flat ? Colors.md3.surface_container_highest : Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)
            radius: 8
            border.width: root.flat ? 0 : 1
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
                font.family: Config.fontFamily
                font.pixelSize: 11
                wrapMode: Text.Wrap
                width: Math.min(implicitWidth, root.maxWidth - root.padding * 2)
                visible: !root.hasCustomContent
            }
        }
    }
}
