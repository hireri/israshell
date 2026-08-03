pragma ComponentBehavior: Bound

import QtQuick
import qs.style
import qs.services

Item {
    id: root

    property bool editMode: false

    readonly property int rowUnits: 8
    readonly property real rowHeight: 64
    readonly property real gap: 8
    readonly property real _unitWidth: (width - gap * (rowUnits - 1)) / rowUnits

    width: parent ? parent.width : 0

    implicitHeight: _totalHeight
    property real _totalHeight: rowHeight

    Behavior on implicitHeight {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
    }

    property int _draggingIndex: -1
    property int _resizingIndex: -1
    property int _resizingPreviewSize: 0
    property int _pressExpandIndex: -1

    ListModel { id: tileModel }

    Component.onCompleted: _syncFromConfig(true)

    Connections {
        target: Config
        function onQuickSettingsTilesChanged() {
            root._syncFromConfig(false);
        }
    }

    function _syncFromConfig(force) {
        if (!force && (root._draggingIndex !== -1 || root._resizingIndex !== -1))
            return;
        const active = Config.quickSettingsTiles?.active ?? [];

        let same = active.length === tileModel.count;
        if (same) {
            for (let i = 0; i < active.length; i++) {
                const m = tileModel.get(i);
                if (m.tileId !== active[i].id || m.size !== active[i].size) {
                    same = false;
                    break;
                }
            }
        }
        if (same)
            return;

        let isPrefix = tileModel.count < active.length;
        if (isPrefix) {
            for (let i = 0; i < tileModel.count; i++) {
                const m = tileModel.get(i);
                if (m.tileId !== active[i].id || m.size !== active[i].size) {
                    isPrefix = false;
                    break;
                }
            }
        }

        if (isPrefix) {
            for (let i = tileModel.count; i < active.length; i++)
                tileModel.append({ tileId: active[i].id, size: active[i].size });
        } else {
            tileModel.clear();
            for (const t of active)
                tileModel.append({ tileId: t.id, size: t.size });
        }
        root._layout();
    }

    function _widthUnits(size) {
        return size / 25;
    }

    function _computeLayout(overrideIndex, overrideSize) {
        const targets = [];
        let x = 0, y = 0;
        for (let i = 0; i < tileModel.count; i++) {
            const it = tileModel.get(i);
            const size = (i === overrideIndex) ? overrideSize : it.size;
            const units = root._widthUnits(size);

            if (x > 0 && x + units > root.rowUnits) {
                x = 0;
                y += root.rowHeight + root.gap;
            }

            targets.push({
                x: x * (root._unitWidth + root.gap),
                y: y,
                width: units * root._unitWidth + (units - 1) * root.gap,
                row: y
            });

            x += units;
        }

        root._applyPressExpand(targets, overrideIndex);

        return { targets: targets, totalHeight: y + root.rowHeight };
    }

    function _applyPressExpand(targets, overrideIndex) {
        const pIndex = root._pressExpandIndex;
        if (pIndex < 0 || pIndex >= targets.length || pIndex === overrideIndex)
            return;
        if (root._draggingIndex !== -1 || root._resizingIndex !== -1)
            return;

        const rowY = targets[pIndex].row;
        const rowIndices = [];
        for (let i = 0; i < targets.length; i++)
            if (targets[i].row === rowY)
                rowIndices.push(i);

        if (rowIndices.length <= 1)
            return;

        const unit = root._unitWidth + root.gap;
        const minWidth = unit * 0.4;
        const expandAmount = Math.min(root._unitWidth * 0.5, 14);

        const others = rowIndices.filter(i => i !== pIndex);
        const available = others.reduce((s, i) => s + Math.max(0, targets[i].width - minWidth), 0);
        const actualExpand = Math.min(expandAmount, available);

        if (actualExpand <= 0)
            return;

        const totalOtherWidth = others.reduce((s, i) => s + targets[i].width, 0);
        for (const i of others) {
            const share = targets[i].width / totalOtherWidth;
            const shrink = Math.min(actualExpand * share, targets[i].width - minWidth);
            targets[i].width -= shrink;
        }
        targets[pIndex].width += actualExpand;

        let cx = null;
        for (const i of rowIndices) {
            if (cx === null)
                cx = targets[i].x;
            targets[i].x = cx;
            cx += targets[i].width + root.gap;
        }
    }

    function _setPressExpand(index, active) {
        const newIndex = active ? index : (root._pressExpandIndex === index ? -1 : root._pressExpandIndex);
        if (newIndex === root._pressExpandIndex)
            return;
        root._pressExpandIndex = newIndex;
        root._layout();
    }

    function _layout() {
        if (root._unitWidth <= 0)
            return;
        const result = root._computeLayout(root._resizingIndex, root._resizingPreviewSize);

        for (let i = 0; i < tileModel.count; i++) {
            const del = tileRepeater.itemAt(i);
            if (!del)
                continue;
            const t = result.targets[i];
            del.targetX = t.x;
            del.targetY = t.y;
            del.targetWidth = t.width;
            del.layoutReady = true;
        }
        root._totalHeight = result.totalHeight;
    }

    onWidthChanged: Qt.callLater(_layout)

    function _persist() {
        const active = [];
        for (let i = 0; i < tileModel.count; i++) {
            const it = tileModel.get(i);
            active.push({ id: it.tileId, size: it.size });
        }
        Config.update({ quickSettingsTiles: Object.assign({}, Config.quickSettingsTiles, { active: active }) });
    }

    function _removeTile(index) {
        const it = tileModel.get(index);
        const removed = [...(Config.quickSettingsTiles?.removed ?? []), it.tileId];
        tileModel.remove(index, 1);
        root._layout();

        const active = [];
        for (let i = 0; i < tileModel.count; i++) {
            const t = tileModel.get(i);
            active.push({ id: t.tileId, size: t.size });
        }
        Config.update({ quickSettingsTiles: Object.assign({}, Config.quickSettingsTiles, {
            active: active,
            removed: removed
        }) });
    }

    function _startReposition(index) {
        root._draggingIndex = index;
        const del = tileRepeater.itemAt(index);
        if (del) del.z = 100;
    }

    function _moveReposition(index, cx, cy) {
        let bestIdx = index;
        let bestDist = Infinity;

        const order = [];
        for (let i = 0; i < tileModel.count; i++)
            order.push({ size: tileModel.get(i).size });
        const dragged = order.splice(index, 1)[0];

        for (let k = 0; k < tileModel.count; k++) {
            const trial = order.slice();
            trial.splice(k, 0, dragged);

            let x = 0, y = 0, slot = null;
            for (let i = 0; i < trial.length; i++) {
                const units = root._widthUnits(trial[i].size);
                if (x > 0 && x + units > root.rowUnits) {
                    x = 0;
                    y += root.rowHeight + root.gap;
                }
                if (i === k) {
                    slot = {
                        x: x * (root._unitWidth + root.gap),
                        y: y,
                        width: units * root._unitWidth + (units - 1) * root.gap
                    };
                }
                x += units;
            }
            if (!slot)
                continue;

            const dx = cx - (slot.x + slot.width / 2);
            const dy = cy - (slot.y + root.rowHeight / 2);
            const dist = dx * dx + dy * dy;
            if (dist < bestDist) {
                bestDist = dist;
                bestIdx = k;
            }
        }

        if (bestIdx !== index) {
            tileModel.move(index, bestIdx, 1);
            root._draggingIndex = bestIdx;
            root._layout();
        }
    }

    function _endReposition(index) {
        const del = tileRepeater.itemAt(index);
        if (del) del.z = 0;
        root._draggingIndex = -1;
        root._layout();
        root._persist();
    }

    function _previewResize(index, previewSize) {
        root._resizingIndex = index;
        root._resizingPreviewSize = previewSize;
        root._layout();
    }

    function _commitResize(index, finalSize) {
        tileModel.setProperty(index, "size", finalSize);
        root._resizingIndex = -1;
        root._resizingPreviewSize = 0;
        root._layout();
        root._persist();
    }

    Repeater {
        id: tileRepeater
        model: tileModel

        delegate: QsTile {
            id: tileItem
            required property int index

            editMode: root.editMode
            unitWidth: root._unitWidth + root.gap
            gap: root.gap
            tileHeight: root.rowHeight

            onRemoveRequested: root._removeTile(index)
            onBodyDragStarted: (sceneX, sceneY) => root._startReposition(index)
            onBodyDragMoved: (sceneX, sceneY) => root._moveReposition(index, sceneX, sceneY)
            onBodyDragEnded: root._endReposition(index)
            onResizePreview: previewSize => root._previewResize(index, previewSize)
            onResizeCommitted: finalSize => root._commitResize(index, finalSize)
            onPressExpandedChanged: root._setPressExpand(index, tileItem.pressExpanded)

            Component.onCompleted: root._layout()
        }
    }
}
