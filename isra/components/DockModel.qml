pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick

import qs.style

Item {
    id: root

    visible: false
    width: 0
    height: 0

    property int orientation: 0
    property int itemStride: 34
    readonly property int exitDuration: 200

    readonly property var pinnedApps: (Config && Config.pinnedApps) ? Config.pinnedApps : []

    function togglePinned(appId: string): void {
        let pins = pinnedApps.slice();
        let idx = pins.indexOf(appId);
        if (idx !== -1) {
            pins.splice(idx, 1);
        } else {
            pins.push(appId);
        }
        Config.update({ pinnedApps: pins });
    }

    readonly property int toplevelCount: ToplevelManager.toplevels?.count ?? 0
    readonly property var activeToplevels: ToplevelManager.toplevels?.values ?? []

    function getDesktopEntry(appId: string): var {
        if (!appId) return null;
        let entry = DesktopEntries.heuristicLookup(appId);
        if (entry) return entry;

        let cleaned = appId.toLowerCase();
        entry = DesktopEntries.heuristicLookup(cleaned);
        if (entry) return entry;

        let parts = cleaned.split(".");
        if (parts.length > 1) {
            let lastPart = parts[parts.length - 1];
            entry = DesktopEntries.heuristicLookup(lastPart);
            if (entry) return entry;
        }
        return null;
    }

    function matchesAppId(runningId: string, targetId: string): bool {
        if (!runningId || !targetId) return false;

        let r = runningId.toLowerCase();
        let t = targetId.toLowerCase();

        if (r === t) return true;
        if (r.endsWith("." + t)) return true;

        if (r.endsWith(".desktop")) r = r.slice(0, -8);
        if (t.endsWith(".desktop")) t = t.slice(0, -8);

        return r === t;
    }

    readonly property var dockModel: {
        let list = [];
        let pins = (Config && Config.pinnedApps) ? Config.pinnedApps : [];
        let runningToplevels = activeToplevels;
        if (!runningToplevels) runningToplevels = [];
        let mappedToplevels = new Set();

        for (let i = 0; i < pins.length; i++) {
            let pinId = pins[i];
            let matchedWindows = [];

            for (let j = 0; j < runningToplevels.length; j++) {
                let tl = runningToplevels[j];
                if (!tl) continue;

                if (matchesAppId(tl.appId, pinId)) {
                    matchedWindows.push(tl);
                    mappedToplevels.add(tl);
                }
            }

            list.push({
                appId: pinId,
                isPinned: true,
                isSeparator: false,
                toplevels: matchedWindows,
                key: "pinned:" + pinId
            });
        }

        let unpinnedGroups = [];
        for (let j = 0; j < runningToplevels.length; j++) {
            let tl = runningToplevels[j];
            if (!tl || mappedToplevels.has(tl)) continue;

            let appId = tl.appId;
            let existingGroup = unpinnedGroups.find(item => matchesAppId(item.appId, appId));

            if (existingGroup) {
                existingGroup.toplevels.push(tl);
                mappedToplevels.add(tl);
            } else {
                let group = {
                    appId: appId,
                    isPinned: false,
                    isSeparator: false,
                    toplevels: [tl],
                    key: "running:" + appId
                };
                unpinnedGroups.push(group);
                mappedToplevels.add(tl);
            }
        }

        if (list.length > 0 && unpinnedGroups.length > 0) {
            list.push({ isSeparator: true, isPinned: false, toplevels: [], key: "separator" });
        }
        list = list.concat(unpinnedGroups);

        return list;
    }

    property string draggingKey: ""
    property real dragPos: 0
    property real dragClickOffset: 0
    property int dragSourceIndex: -1
    property bool isReleasing: false
    property var dragPreviewOrder: []
    property bool trashHovered: false

    readonly property int dragTargetIndex: {
        if (draggingKey === "" || dragSourceIndex === -1) return -1;

        let clampedPos = Math.max(0, Math.min((pinnedApps.length - 1) * itemStride, dragPos - dragClickOffset));
        let idx = Math.round(clampedPos / itemStride);

        return Math.max(0, Math.min(dragPreviewOrder.length - 1, idx));
    }

    function beginDrag(key: string, startPos: real): void {
        releaseTimer.stop();
        isReleasing = false;

        let previewOrder = pinnedApps.slice();
        let sourceIndex = previewOrder.indexOf(key.startsWith("pinned:") ? key.slice("pinned:".length) : "");
        let clickOffset = sourceIndex !== -1 ? startPos - (sourceIndex * itemStride) : 0;

        draggingKey = key;
        dragPreviewOrder = previewOrder;
        dragSourceIndex = sourceIndex;
        dragClickOffset = clickOffset;
        dragPos = startPos;
        trashHovered = false;
    }

    function updateDrag(key: string, scenePos: real): void {
        if (draggingKey !== key || isReleasing) return;
        dragPos = scenePos;

        let draggedAppId = key.startsWith("pinned:") ? key.slice("pinned:".length) : "";
        if (!draggedAppId) return;

        let fromIdx = dragPreviewOrder.indexOf(draggedAppId);
        if (fromIdx === -1) return;

        let clampedPos = Math.max(0, Math.min((pinnedApps.length - 1) * itemStride, dragPos - dragClickOffset));
        let targetIdx = Math.round(clampedPos / itemStride);
        targetIdx = Math.max(0, Math.min(dragPreviewOrder.length - 1, targetIdx));

        if (targetIdx !== fromIdx) {
            let reordered = dragPreviewOrder.slice();
            reordered.splice(fromIdx, 1);
            reordered.splice(targetIdx, 0, draggedAppId);
            dragPreviewOrder = reordered;
            dragSourceIndex = targetIdx;
        }
    }

    function unpinOrClose(key: string): void {
        if (key.startsWith("pinned:")) {
            togglePinned(key.slice("pinned:".length));
        } else if (key.startsWith("running:")) {
            let appId = key.slice("running:".length);
            for (const tl of activeToplevels) {
                if (tl && matchesAppId(tl.appId, appId) && typeof tl.close === "function") {
                    tl.close();
                }
            }
        }
    }

    function endDrag(): void {
        let key = draggingKey;

        if (key !== "") {
            isReleasing = true;

            if (trashHovered) {
                unpinOrClose(key);
                trashHovered = false;
            } else {
                dragPos = (dragSourceIndex * itemStride) + dragClickOffset;
                if (dragSourceIndex !== -1) {
                    let reordered = dragPreviewOrder.slice();
                    Config.update({ pinnedApps: reordered });
                }
            }
            releaseTimer.start();
        } else {
            draggingKey = "";
            dragSourceIndex = -1;
            isReleasing = false;
        }
    }

    Timer {
        id: releaseTimer
        interval: 220
        repeat: false
        onTriggered: {
            root.draggingKey = "";
            root.dragSourceIndex = -1;
            root.isReleasing = false;
        }
    }

    readonly property var displayModel: {
        if (draggingKey === "") return dockModel;

        let byKey = {};
        for (let i = 0; i < dockModel.length; i++) byKey[dockModel[i].key] = dockModel[i];

        let result = [];
        for (let i = 0; i < dragPreviewOrder.length; i++) {
            let entry = byKey["pinned:" + dragPreviewOrder[i]];
            if (entry) result.push(entry);
        }
        for (let i = 0; i < dockModel.length; i++) {
            if (!dockModel[i].isPinned) result.push(dockModel[i]);
        }
        return result;
    }

    ListModel {
        id: viewModelImpl
        dynamicRoles: true
    }
    readonly property ListModel viewModel: viewModelImpl
    property int viewModelRevision: 0

    property bool initialized: false

    function indexOfKey(key: string): int {
        for (let i = 0; i < viewModelImpl.count; i++) {
            if (viewModelImpl.get(i)._key === key) return i;
        }
        return -1;
    }

    function layoutIndexOf(key: string): int {
        let n = 0;
        for (let i = 0; i < viewModelImpl.count; i++) {
            let row = viewModelImpl.get(i);
            if (row._key === key) return n;
            if (!row._exiting) n++;
        }
        return -1;
    }

    function syncViewModel(): void {
        let items = displayModel;
        if (!items) return;

        if (draggingKey !== "" && !isReleasing) {
            let draggedIdx = indexOfKey(draggingKey);
            let targetIdx = -1;
            for (let i = 0; i < items.length; i++) {
                if (items[i].key === draggingKey) { targetIdx = i; break; }
            }
            if (draggedIdx !== -1 && targetIdx !== -1 && draggedIdx !== targetIdx) {
                viewModelImpl.move(draggedIdx, targetIdx, 1);
            }
        }

        let anyExiting = false;
        for (let i = 0; i < viewModelImpl.count; i++) {
            let row = viewModelImpl.get(i);
            if (!items.some(it => it.key === row._key)) {
                if (!row._exiting) {
                    viewModelImpl.setProperty(i, "_exiting", true);
                    anyExiting = true;
                }
            }
        }

        for (let targetIdx = 0; targetIdx < items.length; targetIdx++) {
            let key = items[targetIdx].key;
            let currentIdx = indexOfKey(key);

            if (currentIdx === -1) {
                viewModelImpl.insert(targetIdx, { _key: key, _exiting: false, _instant: !root.initialized });
            } else {
                if (viewModelImpl.get(currentIdx)._exiting)
                    viewModelImpl.setProperty(currentIdx, "_exiting", false);
                if (currentIdx !== targetIdx)
                    viewModelImpl.move(currentIdx, targetIdx, 1);
            }
        }

        if (anyExiting) exitSweep.restart();
        viewModelRevision++;
    }

    Timer {
        id: exitSweep
        interval: root.exitDuration + 40
        onTriggered: {
            for (let i = viewModelImpl.count - 1; i >= 0; i--) {
                if (viewModelImpl.get(i)._exiting) viewModelImpl.remove(i);
            }
        }
    }

    onDisplayModelChanged: syncViewModel()
    Component.onCompleted: {
        syncViewModel();
        initialized = true;
    }
}
