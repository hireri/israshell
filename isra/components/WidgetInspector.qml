import QtQuick
import Quickshell.Widgets
import qs.style
import qs.services

Item {
    id: root

    required property var hostScreen

    readonly property alias cardItem: card
    readonly property bool coexistsWithMode: true

    signal closed

    readonly property real cardW: Math.max(240, Math.min(root._panelWidth, root.width - root.margin * 2))
    readonly property real _panelWidth: contentLoader.item?.preferredWidth ?? 320
    readonly property real cardR: 20
    readonly property real margin: 12
    readonly property real pad: 8
    readonly property real gap: 16
    readonly property real dialogMaxH: 480

    property var panel: null
    property rect anchorRect: Qt.rect(0, 0, 0, 0)

    property Item blurSource: null
    readonly property bool blurActive: root.blurSource !== null && Config.blurAllowed(true)

    property bool _originRight: false
    readonly property real cardOriginX: root._originRight ? 1 : 0
    readonly property real cardOriginY: 0

    anchors.fill: parent
    visible: false

    onVisibleChanged: root.visible ? EditModeService.settingsPanelOpened() : EditModeService.settingsPanelClosed()
    Component.onDestruction: {
        if (root.visible)
            EditModeService.settingsPanelClosed();
    }

    property real cardX: 0
    property real cardY: 0

    readonly property real _maxH: Math.max(120, Math.min(root.dialogMaxH, root.height - root.margin * 2))
    readonly property real _contentH: (contentLoader.item?.implicitHeight ?? 0) + root.pad * 2
    readonly property real cardH: Math.min(root._maxH, root._contentH)

    function open(rect: rect, panelComponent: var): void {
        root.anchorRect = rect;
        root._lastAnchorX = rect.x;
        root._lastAnchorY = rect.y;
        card._wiping = true;
        root.panel = panelComponent;
        root._place();
        card.opacity = 0;
        card.scale = 0.9;
        root.visible = true;
        closeAnim.stop();
        openAnim.restart();
        PanelService.opened(root, root.hostScreen);
    }

    function close(): void {
        if (!root.visible)
            return;
        openAnim.stop();
        if (!closeAnim.running)
            closeAnim.restart();
        PanelService.closed(root);
        root.closed();
    }

    ParallelAnimation {
        id: openAnim
        NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: 160; easing.type: Easing.OutCubic }
        NumberAnimation { target: card; property: "scale"; from: 0.9; to: 1; duration: 160; easing.type: Easing.OutCubic }
        onStarted: card._wiping = true
        onStopped: card._wiping = false
    }

    ParallelAnimation {
        id: closeAnim
        NumberAnimation { target: card; property: "opacity"; to: 0; duration: 110; easing.type: Easing.InCubic }
        NumberAnimation { target: card; property: "scale"; to: 0.9; duration: 110; easing.type: Easing.InCubic }
        onStarted: card._wiping = true
        onStopped: {
            card._wiping = false;
            root.visible = false;
            root.panel = null;
        }
    }

    function _place(): void {
        const r = root.anchorRect;
        const rightX = r.x + r.width + root.gap;
        const leftX = r.x - root.gap - root.cardW;

        let x;
        let originRight = false;
        if (rightX + root.cardW + root.margin <= root.width) {
            x = rightX;
        } else if (leftX >= root.margin) {
            x = leftX;
            originRight = true;
        } else {
            x = root.width - root.cardW - root.margin;
            originRight = true;
        }

        root.cardX = Math.max(root.margin, Math.min(x, root.width - root.cardW - root.margin));
        root.cardY = Math.max(root.margin, Math.min(r.y, root.height - root.cardH - root.margin));
        root._originRight = originRight;
    }

    property real _lastAnchorX: 0
    property real _lastAnchorY: 0
    onAnchorRectChanged: {
        if (!root.visible)
            return;
        if (Math.abs(root.anchorRect.x - root._lastAnchorX) < 1 && Math.abs(root.anchorRect.y - root._lastAnchorY) < 1)
            return;
        root._lastAnchorX = root.anchorRect.x;
        root._lastAnchorY = root.anchorRect.y;
        root._place();
    }

    onCardHChanged: {
        if (!root.visible)
            return;
        const maxY = root.height - root.cardH - root.margin;
        if (root.cardY > maxY)
            root.cardY = Math.max(root.margin, maxY);
    }

    Connections {
        target: EditModeService
        function onSelectedIdChanged(): void {
            if (EditModeService.selectedId === "")
                root.close();
        }
    }

    MouseArea {
        id: outsideCatcher
        anchors.fill: parent
        visible: root.visible
        enabled: root.visible
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        propagateComposedEvents: true
        onClicked: mouse => {
            root.close();
            if (mouse.button === Qt.RightButton)
                mouse.accepted = false;
        }
    }

    ClippingRectangle {
        id: card
        property bool _wiping: false

        x: root.cardX
        y: root.cardY
        width: root.cardW
        height: root.cardH

        Behavior on width {
            enabled: !card._wiping
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on height {
            enabled: root.visible && !card._wiping && !openAnim.running
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on x {
            enabled: !card._wiping
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on y {
            enabled: !card._wiping
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        color: root.blurActive ? "transparent" : Qt.alpha(Colors.md3.surface_container, Config.blurOpacity)
        radius: root.cardR
        border.width: 1
        border.color: Qt.alpha(Colors.md3.on_surface, 0.3)
        layer.enabled: true
        transformOrigin: root._originRight ? Item.TopRight : Item.TopLeft

        ShaderEffectSource {
            anchors.fill: parent
            visible: root.blurActive
            sourceItem: root.blurSource
            sourceRect: Qt.rect(card.x, card.y, card.width, card.height)
            hideSource: false
        }

        Rectangle {
            anchors.fill: parent
            visible: root.blurActive
            color: Qt.alpha(Colors.md3.surface_container, Config.blurOpacity)
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: {}
        }

        Flickable {
            id: scroller
            anchors.fill: parent
            anchors.margins: root.pad
            clip: true

            contentWidth: width
            contentHeight: contentLoader.item?.implicitHeight ?? 0
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds

            Loader {
                id: contentLoader
                width: scroller.width
                sourceComponent: root.panel
            }
        }
    }
}
