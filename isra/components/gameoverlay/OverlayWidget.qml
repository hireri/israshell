import QtQuick
import QtQuick.Layouts
import qs.icons
import qs.services
import qs.style
import "tokens.js" as T

Item {
    id: root

    required property var meta
    property Component bodyComponent

    readonly property var saved: GameOverlayService.widgetState(root.meta.id)

    readonly property bool framed: root.meta.framed !== false
    readonly property bool resizable: root.meta.resizable !== false

    readonly property bool open: GameOverlayService.visible
    readonly property bool pinned: root.saved.pinned === true
    readonly property bool canClick: root.meta.canClick !== false
    readonly property bool clickthrough: GameOverlayService.isClickthrough(root.meta.id)
    readonly property bool shown: root.open || root.pinned
    readonly property bool wantsInput: root.pinned && !root.open && !root.clickthrough
    readonly property real _chromeShift: root.open ? 0 : T.titleBarHeight - T.padding

    function _even(v) {
        return Math.ceil(v / 2) * 2;
    }

    readonly property real minWidth: Math.max(titleRow.implicitWidth + 22, T.padding * 2 + (body.item?.implicitWidth ?? 0))
    readonly property real minHeight: T.titleBarHeight + T.padding + (body.item?.implicitHeight ?? 0)

    readonly property real _canvasW: root.parent?.width ?? 0
    readonly property real _canvasH: root.parent?.height ?? 0
    readonly property real _savedW: root.saved.rw !== undefined ? root.saved.rw * root._canvasW : (root.saved.width ?? 0)
    readonly property real _savedH: root.saved.rh !== undefined ? root.saved.rh * root._canvasH : (root.saved.height ?? 0)
    readonly property real _w: root._even(root.resizable ? Math.max(root._savedW, root.minWidth) : root.minWidth)
    readonly property real _h: root._even(root.resizable ? Math.max(root._savedH, root.minHeight) : root.minHeight)
    readonly property real _defaultY: root.meta.centerBody ? root._canvasH / 2 - root._bodyCenterY(root._h) : root.meta.ay * (root._canvasH - root._h)
    readonly property var _savedX: root.meta.centerBody && root.saved.rcx !== undefined ? root.saved.rcx * root._canvasW - root._w / 2 : root.saved.rx !== undefined ? root.saved.rx * root._canvasW : root.saved.x
    readonly property var _savedY: root.meta.centerBody && root.saved.rcy !== undefined ? root.saved.rcy * root._canvasH - root._bodyCenterY(root._h) : root.saved.ry !== undefined ? root.saved.ry * root._canvasH : root.saved.y
    readonly property real _x: Math.round(Math.max(0, Math.min(root._savedX ?? root.meta.ax * (root._canvasW - root._w), root._canvasW - root._w)))
    readonly property real _y: Math.round(Math.max(0, Math.min(root._savedY ?? root._defaultY, root._canvasH - root._h)))

    function _bodyCenterY(frameHeight) {
        return T.titleBarHeight + (frameHeight - T.titleBarHeight - T.padding) / 2;
    }

    property bool interacting: false
    property real liveX
    property real liveY
    property real liveW
    property real liveH

    visible: root.shown
    opacity: (root.open || !root.clickthrough || root.meta.dim === false) ? 1 : Config.gameOverlay.clickthroughOpacity
    x: root.interacting ? root.liveX : root._x
    y: (root.interacting ? root.liveY : root._y) + root._chromeShift
    width: root.interacting ? root.liveW : root._w
    height: (root.interacting ? root.liveH : root._h) - root._chromeShift
    z: root.interacting ? 5 : 1

    onWantsInputChanged: GameOverlayService.setClickable(root, root.wantsInput)
    Component.onCompleted: {
        if (root.wantsInput)
            GameOverlayService.setClickable(root, true);
    }
    Component.onDestruction: GameOverlayService.setClickable(root, false)

    function beginInteraction() {
        root.liveX = root.x;
        root.liveY = root.y;
        root.liveW = root.width;
        root.liveH = root.height;
        root.interacting = true;
    }

    function endInteraction(resized) {
        const patch = { rx: root.liveX / root._canvasW, ry: root.liveY / root._canvasH };
        if (resized) {
            patch.rw = root.liveW / root._canvasW;
            patch.rh = root.liveH / root._canvasH;
        }
        if (root.meta.centerBody) {
            patch.rcx = (root.liveX + root.liveW / 2) / root._canvasW;
            patch.rcy = (root.liveY + root._bodyCenterY(root.liveH)) / root._canvasH;
        }
        GameOverlayService.setWidgetState(root.meta.id, patch);
        root.interacting = false;
    }

    function resizeTo(ex, ey, r, dx, dy) {
        let left = r.x;
        let top = r.y;
        let right = r.x + r.width;
        let bottom = r.y + r.height;
        if (ex < 0)
            left = Math.min(r.x + dx, right - root.minWidth);
        if (ex > 0)
            right = Math.max(r.x + r.width + dx, left + root.minWidth);
        if (ey < 0)
            top = Math.min(r.y + dy, bottom - root.minHeight);
        if (ey > 0)
            bottom = Math.max(r.y + r.height + dy, top + root.minHeight);
        left = Math.max(0, left);
        top = Math.max(0, top);
        right = Math.min(root._canvasW, right);
        bottom = Math.min(root._canvasH, bottom);
        root.liveX = left;
        root.liveY = top;
        root.liveW = right - left;
        root.liveH = bottom - top;
    }

    property bool _centering: false

    Timer {
        id: centeringTimer
        interval: 400
        onTriggered: root._centering = false
    }

    Behavior on x {
        enabled: root._centering
        NumberAnimation { duration: 350; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1] }
    }
    Behavior on y {
        enabled: root._centering
        NumberAnimation { duration: 350; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1] }
    }

    function center() {
        root._centering = true;
        centeringTimer.restart();
        GameOverlayService.setWidgetState(root.meta.id, {
            rx: (root._canvasW - root.width) / 2 / root._canvasW,
            ry: (root._canvasH / 2 - (root.meta.centerBody ? root._bodyCenterY(root.height) : root.height / 2)) / root._canvasH,
            rcx: 0.5,
            rcy: 0.5
        });
    }

    Connections {
        target: GameOverlayService
        function onCenterRequested(id) {
            if (id === root.meta.id)
                root.center();
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: root.framed
        radius: T.radiusContainer
        color: Colors.md3.surface_container
        border.width: 1
        border.color: root.open ? Colors.md3.outline_variant : "transparent"

        MouseArea {
            anchors.fill: parent
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Item {
            id: titleBar
            visible: root.open
            Layout.fillWidth: true
            Layout.preferredHeight: T.titleBarHeight

            Rectangle {
                anchors.fill: parent
                visible: !root.framed
                radius: height / 2
                color: Colors.md3.surface_container
                border.width: 1
                border.color: Colors.md3.outline_variant

                MouseArea {
                    anchors.fill: parent
                }
            }

            HoverHandler {
                cursorShape: moveHandler.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            }

            DragHandler {
                id: moveHandler
                target: null
                acceptedButtons: Qt.LeftButton

                property real startX
                property real startY

                onActiveChanged: {
                    if (active) {
                        root.beginInteraction();
                        startX = root.liveX;
                        startY = root.liveY;
                    } else {
                        root.endInteraction(false);
                    }
                }
                onTranslationChanged: {
                    if (!active)
                        return;
                    root.liveX = Math.round(Math.max(0, Math.min(startX + translation.x, root._canvasW - root.liveW)));
                    root.liveY = Math.round(Math.max(0, Math.min(startY + translation.y, root._canvasH - root.liveH)));
                }
            }

            RowLayout {
                id: titleRow
                anchors {
                    fill: parent
                    leftMargin: 16
                    rightMargin: 6
                }
                spacing: 8

                MaterialIcon {
                    name: root.meta.icon
                    iconSize: 18
                    filled: true
                    color: Colors.md3.primary
                    transitionType: "none"
                }

                Text {
                    Layout.fillWidth: true
                    text: Localization.t(root.meta.titleKey)
                    elide: Text.ElideRight
                    font.family: Config.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: Colors.md3.on_surface
                    renderType: Text.NativeRendering
                }

                OverlayButton {
                    visible: root.meta.centerButton === true
                    icon: "filter-center-focus"
                    size: 28
                    tip: Localization.t("gameOverlay.center")
                    onClicked: root.center()
                }

                OverlayButton {
                    visible: root.pinned && root.canClick
                    icon: "mouse"
                    size: 28
                    toggled: !root.clickthrough
                    tip: Localization.t("gameOverlay.clickable_when_pinned")
                    onClicked: GameOverlayService.toggleClickthrough(root.meta.id)
                }

                OverlayButton {
                    icon: "keep"
                    size: 28
                    toggled: root.pinned
                    tip: Localization.t("gameOverlay.pin")
                    onClicked: GameOverlayService.togglePinned(root.meta.id)
                }

                OverlayButton {
                    icon: "close"
                    size: 28
                    tip: Localization.t("gameOverlay.close")
                    onClicked: GameOverlayService.toggleWidget(root.meta.id)
                }
            }
        }

        Loader {
            id: body
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: T.padding
            Layout.topMargin: root.open ? 0 : T.padding
            active: root.shown
            sourceComponent: root.bodyComponent
        }
    }

    Repeater {
        model: root.resizable && root.open ? [[-1, -1], [0, -1], [1, -1], [-1, 0], [1, 0], [-1, 1], [0, 1], [1, 1]] : []

        delegate: MouseArea {
            id: handle
            required property var modelData

            readonly property int ex: modelData[0]
            readonly property int ey: modelData[1]
            property point startScene
            property rect startRect

            readonly property real cs: T.cornerSize
            readonly property bool corner: ex !== 0 && ey !== 0

            x: ex < 0 ? 0 : ex > 0 ? root.width - (corner ? cs : T.resizeMargin) : cs
            y: ey < 0 ? 0 : ey > 0 ? root.height - (corner ? cs : T.resizeMargin) : cs
            width: ex === 0 ? root.width - cs * 2 : corner ? cs : T.resizeMargin
            height: ey === 0 ? root.height - cs * 2 : corner ? cs : T.resizeMargin
            z: corner ? 11 : 10
            hoverEnabled: true
            cursorShape: ex === 0 ? Qt.SizeVerCursor : ey === 0 ? Qt.SizeHorCursor : ex === ey ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor

            onPressed: mouse => {
                handle.startScene = handle.mapToItem(root.parent, mouse.x, mouse.y);
                handle.startRect = Qt.rect(root.x, root.y, root.width, root.height);
                root.beginInteraction();
            }
            onPositionChanged: mouse => {
                if (!pressed)
                    return;
                const p = handle.mapToItem(root.parent, mouse.x, mouse.y);
                root.resizeTo(ex, ey, handle.startRect, p.x - handle.startScene.x, p.y - handle.startScene.y);
            }
            onReleased: root.endInteraction(true)
            onCanceled: root.endInteraction(true)
        }
    }
}
