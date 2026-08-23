import QtQuick
import qs.style
import qs.services
import qs.icons

Item {
    id: root

    property string entryId: ""
    property var hostScreen: null
    property string label: ""

    property string sizeMode: "uniform"
    property real defaultSize: 200
    property real defaultWidth: 220
    property real defaultHeight: 120
    property real minSize: 48
    property real minWidth: 40
    property real minHeight: 25

    property bool wallpaperRelative: false

    property real contentWidth: 0
    property real contentHeight: 0
    property real contentNominal: 200

    readonly property real contentScale: {
        if (root.contentWidth <= 0 || root.contentHeight <= 0)
            return 1;
        return Math.min(root.bodyWidth / root.contentWidth, root.bodyHeight / root.contentHeight);
    }

    property real frameCornerRadius: root.sizeMode === "uniform" ? Math.max(4, root.localSize / 6) : 8

    property Component extraQuickActions: null

    property var extraMenuEntries: []
    property var extraPlacementEntries: []

    property Component settingsPanel: null

    property var widgetMenu: null
    property var widgetDrawer: null
    property var widgetInspector: null

    function openSettings(): void {
        if (!root.widgetInspector || !root.settingsPanel)
            return;
        if (root.widgetInspector.visible && EditModeService.isSelected(root.entryId, root.hostScreen)) {
            root.widgetInspector.close();
            return;
        }
        root.widgetDrawer?.close();
        EditModeService.select(root.entryId, root.hostScreen);
        root.widgetInspector.open(Qt.rect(body.x, body.y, body.width, body.height), root.settingsPanel);
    }

    default property alias content: body.data

    anchors.fill: parent

    readonly property var entry: DesktopWidgetService.entryFor(root.entryId)
    readonly property var entryData: root.entry?.data ?? ({})
    readonly property bool mirrored: root.freeform && (root.entry?.mirror ?? true)

    readonly property bool _belongsHere: root.freeform || !root.entry?.screen || root.entry.screen === root.hostScreen?.name
    visible: root._belongsHere
    enabled: root._belongsHere

    readonly property alias bodyItem: body

    property var minSpan: ({ w: 1, h: 1 })
    property var maxSpan: ({ w: 12, h: 12 })
    property bool aspectLocked: root.sizeMode === "uniform"

    readonly property bool freeform: DesktopWidgetService.isFreeform(root.entry)

    readonly property var placement: WidgetGrid.placementOf(root.entry, root.hostScreen)

    function _fitBox(span: rect): rect {
        if (!root.aspectLocked)
            return span;
        const side = Math.min(span.width, span.height);
        return Qt.rect(span.x + (span.width - side) / 2, span.y + (span.height - side) / 2, side, side);
    }

    readonly property rect cellBox: {
        if (!root.freeform)
            return root._fitBox(WidgetGrid.cellRect(root.hostScreen, root.placement.col, root.placement.row, root.placement.w, root.placement.h));

        const e = root.entry;
        const rawX = e?.x ?? 100;
        const rawY = e?.y ?? 100;
        const rawW = e?.width ?? root.defaultWidth;
        const rawH = e?.height ?? root.defaultHeight;

        const perMonitor = !(e?.mirror ?? true) ? e?.positions?.[root.hostScreen?.name ?? ""] : null;
        if (perMonitor && perMonitor.x !== undefined)
            return Qt.rect(perMonitor.x, perMonitor.y ?? rawY, perMonitor.width ?? rawW, perMonitor.height ?? rawH);

        if (!root.wallpaperRelative)
            return Qt.rect(rawX, rawY, rawW, rawH);

        const p = DesktopWidgetService.fromReference(root.hostScreen, rawX, rawY);
        return Qt.rect(p.x, p.y, rawW * p.scale, rawH * p.scale);
    }

    property bool _dragging: false
    property bool _resizing: false
    property bool _shiftSnap: false

    readonly property bool gestureActive: root._dragging || root._resizing
    property real _liveX: 0
    property real _liveY: 0
    property real _liveW: 0
    property real _liveH: 0

    readonly property real localX: root._dragging ? root._liveX : root.cellBox.x
    readonly property real localY: root._dragging ? root._liveY : root.cellBox.y
    readonly property real bodyWidth: root._resizing ? root._gestureBox.width : root.cellBox.width
    readonly property real bodyHeight: root._resizing ? root._gestureBox.height : root.cellBox.height

    readonly property real _pullFactor: 0.38
    property real _snapW: 0
    property real _snapH: 0
    property real _pullW: 0
    property real _pullH: 0

    property int _pullSpanW: 1
    property int _pullSpanH: 1

    property bool _snapInstant: false

    Behavior on _snapW {
        enabled: !root._snapInstant
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }
    Behavior on _snapH {
        enabled: !root._snapInstant
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    readonly property real _pullFloorW: WidgetGrid.spanWidth(root.hostScreen, root.minSpan.w ?? 1) * 0.72
    readonly property real _pullFloorH: WidgetGrid.spanHeight(root.hostScreen, root.minSpan.h ?? 1) * 0.72

    readonly property rect _gestureBox: {
        if (root.freeform && !root._shiftSnap)
            return Qt.rect(root._liveX, root._liveY, root._liveW, root._liveH);
        return Qt.rect(root._liveX, root._liveY, Math.max(root._pullFloorW, root._snapW + root._pullW), Math.max(root._pullFloorH, root._snapH + root._pullH));
    }

    function _updatePull(): void {
        const t = root.targetPlacement;
        // resize targets carry no real grid cell (only w/h) — col/row default to 0 here,
        // but that's fine since only .width/.height of the box are ever read below
        const box = t ? root._fitBox(WidgetGrid.cellRect(root.hostScreen, t.col ?? 0, t.row ?? 0, t.w, t.h)) : root.cellBox;
        const spanW = t ? t.w : root.placement.w;
        const spanH = t ? t.h : root.placement.h;

        const unitW = WidgetGrid.cellWidth(root.hostScreen) + WidgetGrid.gutter;
        const unitH = WidgetGrid.cellHeight(root.hostScreen) + WidgetGrid.gutter;
        const overW = Math.max(-1, Math.min(1, (root._liveW + WidgetGrid.gutter) / unitW - spanW));
        const overH = Math.max(-1, Math.min(1, (root._liveH + WidgetGrid.gutter) / unitH - spanH));
        let pw = overW * unitW * root._pullFactor;
        let ph = overH * unitH * root._pullFactor;

        if (root.aspectLocked) {
            const p = (pw + ph) / 2;
            pw = p;
            ph = p;
        }

        if (spanW !== root._pullSpanW || spanH !== root._pullSpanH) {
            const shownW = root._snapW + root._pullW;
            const shownH = root._snapH + root._pullH;
            root._snapInstant = true;
            root._snapW = shownW - pw;
            root._snapH = shownH - ph;
            root._snapInstant = false;
            root._pullSpanW = spanW;
            root._pullSpanH = spanH;
        }

        root._pullW = pw;
        root._pullH = ph;
        root._snapW = box.width;
        root._snapH = box.height;
    }

    ParallelAnimation {
        id: pullSettle
        NumberAnimation { target: root; property: "_pullW"; to: 0; duration: 120; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "_pullH"; to: 0; duration: 120; easing.type: Easing.OutCubic }
        onFinished: {
            root._resizing = false;
            root._interacting = false;
            root._shiftSnap = false;
        }
    }

    readonly property real localSize: Math.min(root.bodyWidth, root.bodyHeight)

    readonly property var targetPlacement: {
        if (root.freeform) {
            if (!root._shiftSnap)
                return null;
            if (root._dragging)
                return { col: WidgetGrid.nearestCol(root.hostScreen, root._liveX), row: WidgetGrid.nearestRow(root.hostScreen, root._liveY), w: 0, h: 0 };
            if (root._resizing) {
                // no real grid cell for a resize — position stays wherever it was, only size snaps
                const raw = WidgetGrid.spanFromPixels(root.hostScreen, root._liveW, root._liveH);
                const span = root._clampSpan(raw.w, raw.h);
                return { w: span.w, h: span.h };
            }
            return null;
        }
        if (root._dragging) {
            const want = WidgetGrid.clampCell(root.hostScreen, WidgetGrid.nearestCol(root.hostScreen, root._liveX), WidgetGrid.nearestRow(root.hostScreen, root._liveY), root.placement.w, root.placement.h);
            const free = WidgetGrid.nearestFreeCell(root.hostScreen, want.col, want.row, root.placement.w, root.placement.h, root.entryId);
            return free ? { col: free.col, row: free.row, w: root.placement.w, h: root.placement.h } : null;
        }
        if (root._resizing) {
            const raw = WidgetGrid.spanFromPixels(root.hostScreen, root._liveW, root._liveH);
            const span = root._clampSpan(raw.w, raw.h);
            if (!WidgetGrid.fits(root.hostScreen, root.placement.col, root.placement.row, span.w, span.h, root.entryId))
                return null;
            return { col: root.placement.col, row: root.placement.row, w: span.w, h: span.h };
        }
        return null;
    }

    function _clampSpan(w, h): var {
        let cw = Math.max(root.minSpan.w ?? 1, Math.min(w, root.maxSpan.w ?? 12));
        let ch = Math.max(root.minSpan.h ?? 1, Math.min(h, root.maxSpan.h ?? 12));
        if (root.aspectLocked) {
            const s = Math.max(cw, ch);
            cw = s;
            ch = s;
        }
        return WidgetGrid.clampSpan(root.hostScreen, cw, ch);
    }

    function _commitFreeform(x: real, y: real, w: real, h: real): void {
        if (!root.mirrored) {
            if (!root.hostScreen?.name)
                return;
            DesktopWidgetService.updateEntryPosition(root.entryId, root.hostScreen.name, {
                x: Math.round(x),
                y: Math.round(y),
                width: Math.round(w),
                height: Math.round(h)
            });
            return;
        }
        if (!root.wallpaperRelative) {
            DesktopWidgetService.updateEntry(root.entryId, {
                x: Math.round(x),
                y: Math.round(y),
                width: Math.round(w),
                height: Math.round(h)
            });
            return;
        }
        const t = DesktopWidgetService.toReference(root.hostScreen, x, y);
        DesktopWidgetService.updateEntry(root.entryId, {
            x: Math.round(t.x),
            y: Math.round(t.y),
            width: Math.round(w / t.scale),
            height: Math.round(h / t.scale)
        });
    }

    function _commitPlacement(col, row, w, h): void {
        DesktopWidgetService.updateEntry(root.entryId, { cell: { col: col, row: row }, span: { w: w, h: h } });
    }

    function _captureCurrentAsIndividualPosition(): void {
        if (!root.hostScreen?.name || !root.freeform)
            return;
        root._commitFreeform(root.localX, root.localY, root.bodyWidth, root.bodyHeight);
    }

    function _seedMirrorBaseFromReferenceMonitor(): void {
        if (!root.freeform || root.hostScreen !== DesktopWidgetService.referenceScreen)
            return;
        const pos = root.entry?.positions?.[root.hostScreen?.name];
        if (!pos)
            return;
        DesktopWidgetService.updateEntry(root.entryId, {
            x: Math.round(pos.x ?? 100),
            y: Math.round(pos.y ?? 100),
            width: Math.round(pos.width ?? root.defaultWidth),
            height: Math.round(pos.height ?? root.defaultHeight)
        });
    }

    function commitGeometry(): void {
        if (root.freeform) {
            root._commitFreeform(root.localX, root.localY, root.bodyWidth, root.bodyHeight);
            return;
        }
        const p = root.placement;
        root._commitPlacement(p.col, p.row, p.w, p.h);
    }

    property bool _mirrorInitialized: false
    property bool _prevMirror: true
    property bool _prevFreeform: false
    property bool _interacting: false

    function _maybeInit(): void {
        if (root._mirrorInitialized || !root.entry || !root.hostScreen)
            return;
        root._prevMirror = root.mirrored;
        root._prevFreeform = root.freeform;
        root._mirrorInitialized = true;
    }

    onEntryChanged: {
        root._maybeInit();
        if (!root._mirrorInitialized || !root.entry)
            return;
        const mirror = root.mirrored;
        const enabling = !root._prevMirror && mirror;
        const disabling = root._prevMirror && !mirror;
        root._prevMirror = mirror;
        if (enabling)
            root._seedMirrorBaseFromReferenceMonitor();
        else if (disabling)
            root._captureCurrentAsIndividualPosition();

        const free = root.freeform;
        if (free !== root._prevFreeform) {
            const wasFree = root._prevFreeform;
            root._prevFreeform = free;

            if (root.hostScreen === DesktopWidgetService.referenceScreen)
                root._adoptOtherPlacementModel(wasFree);
        }
    }

    function _adoptOtherPlacementModel(wasFreeform: bool): void {
        const screen = DesktopWidgetService.referenceScreen;
        const e = root.entry;
        if (!e)
            return;

        if (wasFreeform) {
            const raw = WidgetGrid.spanFromPixels(screen, e.width ?? root.defaultWidth, e.height ?? root.defaultHeight);
            const span = root._clampSpan(raw.w, raw.h);
            const want = WidgetGrid.clampCell(screen, WidgetGrid.nearestCol(screen, e.x ?? 0), WidgetGrid.nearestRow(screen, e.y ?? 0), span.w, span.h);
            const free = WidgetGrid.nearestFreeCell(screen, want.col, want.row, span.w, span.h, root.entryId) ?? want;
            DesktopWidgetService.updateEntry(root.entryId, {
                cell: { col: free.col, row: free.row },
                span: { w: span.w, h: span.h }
            });
            return;
        }

        const p = WidgetGrid.placementOf(e, screen);
        const r = WidgetGrid.cellRect(screen, p.col, p.row, p.w, p.h);
        DesktopWidgetService.updateEntry(root.entryId, {
            x: Math.round(r.x),
            y: Math.round(r.y),
            width: Math.round(r.width),
            height: Math.round(r.height)
        });
    }

    function _releaseFromAutoPlacement(): void {
        if (root.entry?.data?.autoPlace)
            DesktopWidgetService.updateEntryData(root.entryId, { autoPlace: false });
    }

    onHostScreenChanged: root._maybeInit()

    Connections {
        target: EditModeService
        enabled: EditModeService.isSelected(root.entryId, root.hostScreen)
        function onNudgeRequested(dx: real, dy: real): void {
            root._releaseFromAutoPlacement();
            if (root.freeform) {
                root._commitFreeform(root.cellBox.x + dx, root.cellBox.y + dy, root.cellBox.width, root.cellBox.height);
                return;
            }
            const p = root.placement;
            const col = p.col + (dx > 0 ? 1 : dx < 0 ? -1 : 0);
            const row = p.row + (dy > 0 ? 1 : dy < 0 ? -1 : 0);
            const clamped = WidgetGrid.clampCell(root.hostScreen, col, row, p.w, p.h);
            if (!WidgetGrid.fits(root.hostScreen, clamped.col, clamped.row, p.w, p.h, root.entryId))
                return;
            root._commitPlacement(clamped.col, clamped.row, p.w, p.h);
        }
        function onDeleteRequested(): void {
            EditModeService.clearSelection();
            DesktopWidgetService.removeEntry(root.entryId);
        }
    }

    readonly property rect frameBox: {
        if (root._resizing)
            return root._gestureBox;
        const t = root.targetPlacement;
        if (t && root.freeform) {
            // a resize target has no grid cell (t.col is undefined) — position stays put, only size comes from the target
            return t.col !== undefined ? Qt.rect(WidgetGrid.cellX(root.hostScreen, t.col), WidgetGrid.cellY(root.hostScreen, t.row), root.bodyWidth, root.bodyHeight) : Qt.rect(root.localX, root.localY, root.bodyWidth, root.bodyHeight);
        }
        if (t)
            return root._fitBox(WidgetGrid.cellRect(root.hostScreen, t.col, t.row, t.w, t.h));

        if (root.freeform && root._dragging)
            return Qt.rect(root.localX, root.localY, root.bodyWidth, root.bodyHeight);
        return root.cellBox;
    }

    Item {
        id: body
        x: root.localX
        y: root.localY
        width: root.bodyWidth
        height: root.bodyHeight
        z: 2
        readonly property bool _settling: !root._dragging && !root._resizing && root._placementSettled

        Behavior on x {
            enabled: body._settling
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on y {
            enabled: body._settling
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on width {
            enabled: body._settling
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on height {
            enabled: body._settling
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        onXChanged: root._syncInspectorAnchor()
        onYChanged: root._syncInspectorAnchor()
        onWidthChanged: root._syncInspectorAnchor()
        onHeightChanged: root._syncInspectorAnchor()
    }

    property bool _placementSettled: false
    Component.onCompleted: Qt.callLater(() => root._placementSettled = true)

    function _syncInspectorAnchor(): void {
        if (root.widgetInspector?.visible && EditModeService.isSelected(root.entryId, root.hostScreen))
            root.widgetInspector.anchorRect = Qt.rect(body.x, body.y, body.width, body.height);
    }

    function _openContextMenu(x: real, y: real): void {
        if (!root.widgetMenu)
            return;
        root.widgetDrawer?.close();

        const actions = (root.settingsPanel ? [
            {
                text: Localization.t("widgetMenu.settings"),
                icon: settingsIconComp,
                action: () => root.openSettings()
            }
        ] : []).concat(root.extraMenuEntries ?? []);

        const placement = (root.extraPlacementEntries ?? []).concat(root.freeform ? [
            {
                text: root.mirrored ? Localization.t("widgetMenu.per_monitor") : Localization.t("widgetMenu.mirror"),
                icon: mirrorIconComp,
                action: () => DesktopWidgetService.updateEntry(root.entryId, { mirror: !root.mirrored })
            }
        ] : []);

        const destructive = [
            {
                text: Localization.t("widgetMenu.remove"),
                icon: deleteIconComp,
                danger: true,
                action: () => {
                    EditModeService.clearSelection();
                    DesktopWidgetService.removeEntry(root.entryId);
                }
            }
        ];

        const entries = [];
        for (const group of [actions, placement, destructive]) {
            if (group.length === 0)
                continue;
            if (entries.length > 0)
                entries.push({ isSep: true });
            for (const row of group)
                entries.push(row);
        }

        root.widgetMenu.open(x, y, entries);
    }

    Component {
        id: mirrorIconComp
        MaterialIcon {
            name: "monitor"
            iconSize: 16
        }
    }
    Component {
        id: deleteIconComp
        MaterialIcon {
            name: "delete"
            iconSize: 16
        }
    }
    Component {
        id: settingsIconComp
        MaterialIcon {
            name: "tune"
            iconSize: 16
        }
    }

    EditableFrame {
        id: editFrame
        trackX: root.frameBox.x
        trackY: root.frameBox.y
        trackWidth: root.frameBox.width
        trackHeight: root.frameBox.height
        label: root.label
        widgetId: root.entryId
        widgetScreen: root.hostScreen
        interactive: EditModeService.active
        showChrome: EditModeService.active
        movable: true
        resizable: true
        uniformScale: root.aspectLocked
        animateTracking: root._placementSettled && !root._resizing && (!root.freeform || root._shiftSnap)
        cornerRadius: root.frameCornerRadius

        property real _startX: 0
        property real _startY: 0
        property real _startSize: 0
        property real _startWidth: 0
        property real _startHeight: 0

        quickActions: Component {
            Row {
                spacing: 6

                Loader {
                    anchors.verticalCenter: parent.verticalCenter
                    active: root.extraQuickActions !== null
                    sourceComponent: root.extraQuickActions
                }

                Rectangle {
                    visible: root.settingsPanel !== null
                    width: 16
                    height: 16
                    radius: 8
                    color: Qt.alpha(Colors.md3.on_primary_container, settingsMouse.containsMouse ? 0.15 : 0)

                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        name: "tune"
                        iconSize: 12
                        color: Colors.md3.on_primary_container
                    }

                    MouseArea {
                        id: settingsMouse
                        anchors.fill: parent
                        anchors.margins: -3
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openSettings()
                    }
                }

                Rectangle {
                    visible: root.freeform
                    width: 16
                    height: 16
                    radius: 8
                    color: Qt.alpha(Colors.md3.on_primary_container, mirrorMouse.containsMouse ? 0.15 : 0)

                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        name: "monitor"
                        filled: !root.mirrored
                        iconSize: 12
                        color: Colors.md3.on_primary_container
                    }

                    MouseArea {
                        id: mirrorMouse
                        anchors.fill: parent
                        anchors.margins: -3
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: DesktopWidgetService.updateEntry(root.entryId, { mirror: !root.mirrored })
                    }
                }

                Rectangle {
                    visible: root.extraQuickActions !== null || root.settingsPanel !== null || root.freeform
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: 12
                    color: Qt.alpha(Colors.md3.on_surface, 0.2)
                }

                Rectangle {
                    width: 16
                    height: 16
                    radius: 8
                    color: Qt.alpha(Colors.md3.error, removeMouse.containsMouse ? 0.15 : 0)

                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        name: "delete"
                        iconSize: 12
                        color: Colors.md3.error
                    }

                    MouseArea {
                        id: removeMouse
                        anchors.fill: parent
                        anchors.margins: -3
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            EditModeService.clearSelection();
                            DesktopWidgetService.removeEntry(root.entryId);
                        }
                    }
                }
            }
        }

        onMoveStarted: {
            root._interacting = true;
            root._releaseFromAutoPlacement();
            root._shiftSnap = false;
            _startX = root.cellBox.x;
            _startY = root.cellBox.y;
            root._liveX = _startX;
            root._liveY = _startY;
            root._dragging = true;
        }
        onMoveDelta: (dx, dy, snap) => {
            root._shiftSnap = snap;
            root._liveX = editFrame._startX + dx;
            root._liveY = editFrame._startY + dy;
        }
        onMoveCommitted: {
            const target = root.targetPlacement;
            if (root.freeform) {
                if (target)
                    root._commitFreeform(WidgetGrid.cellX(root.hostScreen, target.col), WidgetGrid.cellY(root.hostScreen, target.row), root.bodyWidth, root.bodyHeight);
                else
                    root._commitFreeform(root.localX, root.localY, root.bodyWidth, root.bodyHeight);
            } else if (target)
                root._commitPlacement(target.col, target.row, target.w, target.h);
            root._dragging = false;
            root._interacting = false;
            root._shiftSnap = false;
        }

        onResizeStarted: {
            pullSettle.stop();
            root._interacting = true;
            root._releaseFromAutoPlacement();
            root._shiftSnap = false;
            _startX = root.cellBox.x;
            _startY = root.cellBox.y;
            root._liveX = _startX;
            root._liveY = _startY;
            _startWidth = root.cellBox.width;
            _startHeight = root.cellBox.height;
            root._liveW = _startWidth;
            root._liveH = _startHeight;
            
            root._pullW = 0;
            root._pullH = 0;
            root._snapInstant = true;
            root._snapW = _startWidth;
            root._snapH = _startHeight;
            root._snapInstant = false;
            const startSpan = WidgetGrid.spanFromPixels(root.hostScreen, _startWidth, _startHeight);
            root._pullSpanW = startSpan.w;
            root._pullSpanH = startSpan.h;
            root._resizing = true;
        }
        onResizeDelta: (dw, dh, snap) => {
            root._shiftSnap = snap;
            let w = editFrame._startWidth + dw;
            let h = editFrame._startHeight + dh;
            if (root.aspectLocked) {
                const s = Math.max(w, h);
                w = s;
                h = s;
            }
            const floorW = root.freeform ? root.minWidth : WidgetGrid.cellWidth(root.hostScreen) * 0.4;
            const floorH = root.freeform ? root.minHeight : WidgetGrid.cellHeight(root.hostScreen) * 0.4;
            root._liveW = Math.max(floorW, w);
            root._liveH = Math.max(floorH, h);
            if (!root.freeform || root._shiftSnap)
                root._updatePull();
        }
        onResizeCommitted: {
            const target = root.targetPlacement;
            if (root.freeform) {
                if (root._shiftSnap && target) {
                    const w = WidgetGrid.spanWidth(root.hostScreen, target.w);
                    const h = WidgetGrid.spanHeight(root.hostScreen, target.h);
                    root._commitFreeform(root.localX, root.localY, w, h);
                    root._snapW = w;
                    root._snapH = h;
                    pullSettle.restart();
                    return;
                }
                root._commitFreeform(root.localX, root.localY, root.bodyWidth, root.bodyHeight);
                root._resizing = false;
                root._interacting = false;
                root._shiftSnap = false;
                return;
            }
            if (target)
                root._commitPlacement(target.col, target.row, target.w, target.h);
            root._snapW = root.cellBox.width;
            root._snapH = root.cellBox.height;
            pullSettle.restart();
        }

        onContextRequested: (x, y) => root._openContextMenu(x, y)
    }
}
