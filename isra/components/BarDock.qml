pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQml.Models
import QtQuick.Layouts

import qs.style

Rectangle {
    id: dockRoot

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

    onDockModelChanged: {
        hoverPopup.syncWithModel();
    }

    property string draggingKey: ""
    property real dragX: 0
    property real dragClickOffset: 0
    property int dragSourceIndex: -1
    property bool isReleasing: false
    property var dragPreviewOrder: []

    readonly property int dragTargetIndex: {
        if (draggingKey === "" || dragSourceIndex === -1) return -1;
        
        let clampedX = Math.max(0, Math.min((pinnedApps.length - 1) * 34, dragX - dragClickOffset));
        let idx = Math.round(clampedX / 34);
        
        return Math.max(0, Math.min(dragPreviewOrder.length - 1, idx));
    }

    readonly property Item rowContainer: dockListView.contentItem

    function findDockItemByKey(key: string): var {
        let children = dockListView.contentItem.children;
        for (let i = 0; i < children.length; i++) {
            let child = children[i];
            if (child && child.itemKey === key) return child;
        }
        return null;
    }

    function beginDrag(key: string, startX: real): void {
        releaseTimer.stop();
        isReleasing = false;
        
        dragPreviewOrder = pinnedApps.slice();
        
        dragSourceIndex = -1;
        for (let i = 0; i < dockListModel.count; i++) {
            if (dockListModel.get(i)._key === key) {
                dragSourceIndex = i;
                break;
            }
        }
        
        if (dragSourceIndex !== -1) {
            dragClickOffset = startX - (dragSourceIndex * 34);
        } else {
            dragClickOffset = 0;
        }

        dragX = startX;
        draggingKey = key;
    }

    function updateDrag(key: string, sceneX: real): void {
        if (draggingKey !== key || isReleasing) return;
        dragX = sceneX;

        let draggedAppId = key.startsWith("pinned:") ? key.slice("pinned:".length) : "";
        if (!draggedAppId) return;

        let fromIdx = dragPreviewOrder.indexOf(draggedAppId);
        if (fromIdx === -1) return;

        let clampedX = Math.max(0, Math.min((pinnedApps.length - 1) * 34, dragX - dragClickOffset));
        let targetIdx = Math.round(clampedX / 34);
        targetIdx = Math.max(0, Math.min(dragPreviewOrder.length - 1, targetIdx));

        if (targetIdx !== fromIdx) {
            let reordered = dragPreviewOrder.slice();
            reordered.splice(fromIdx, 1);
            reordered.splice(targetIdx, 0, draggedAppId);
            dragPreviewOrder = reordered;
            dragSourceIndex = targetIdx;
        }
    }

    function endDrag(): void {
        let key = draggingKey;

        if (key !== "") {
            isReleasing = true;
            dragX = (dragSourceIndex * 34) + dragClickOffset;
            
            if (dragSourceIndex !== -1) {
                let reordered = dragPreviewOrder.slice();
                Config.update({ pinnedApps: reordered });
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
            dockRoot.draggingKey = "";
            dockRoot.dragSourceIndex = -1;
            dockRoot.isReleasing = false;
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
        id: dockListModel
        dynamicRoles: true
    }

    function syncListModel() {
        let items = dockRoot.displayModel;
        if (!items) return;

        if (draggingKey !== "" && !isReleasing) {
            let draggedIdx = -1;
            for (let i = 0; i < dockListModel.count; i++) {
                if (dockListModel.get(i)._key === draggingKey) {
                    draggedIdx = i;
                    break;
                }
            }
            let targetIdx = -1;
            for (let i = 0; i < items.length; i++) {
                if (items[i].key === draggingKey) {
                    targetIdx = i;
                    break;
                }
            }
            if (draggedIdx !== -1 && targetIdx !== -1 && draggedIdx !== targetIdx) {
                dockListModel.move(draggedIdx, targetIdx, 1);
            }
        }

        for (let i = dockListModel.count - 1; i >= 0; i--) {
            let k = dockListModel.get(i)._key;
            if (!items.some(it => it.key === k)) {
                dockListModel.remove(i);
            }
        }

        for (let targetIdx = 0; targetIdx < items.length; targetIdx++) {
            let key = items[targetIdx].key;
            let currentIdx = -1;
            for (let i = 0; i < dockListModel.count; i++) {
                if (dockListModel.get(i)._key === key) { currentIdx = i; break; }
            }

            if (currentIdx === -1) {
                dockListModel.insert(targetIdx, { _key: key });
            } else if (currentIdx !== targetIdx) {
                dockListModel.move(currentIdx, targetIdx, 1);
            }
        }
    }

    onDisplayModelChanged: syncListModel()
    
    Component.onCompleted: {
        syncListModel();
    }

    implicitWidth: dockListView.contentWidth + leftPad + rightPad
    implicitHeight: 32

    readonly property int leftPad: 3
    readonly property int rightPad: 3

    color: Config.bar.transparentPills
        ? (Config.bar.transparency ? Qt.alpha(Colors.md3.secondary_container, 0) : Colors.md3.surface_container)
        : (Config.bar.transparency ? Qt.alpha(Colors.md3.surface_container_high, 0.8) : Colors.md3.surface_container_high)

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    radius: 20

    width: implicitWidth
    Behavior on width {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }
    height: implicitHeight

    ListView {
        id: dockListView
        anchors.left: parent.left
        anchors.leftMargin: dockRoot.leftPad
        anchors.verticalCenter: parent.verticalCenter
        height: 32
        orientation: ListView.Horizontal
        interactive: false
        spacing: 6
        clip: false

        width: contentWidth
        model: dockListModel
        cacheBuffer: 0

        add: Transition {
            NumberAnimation { property: "scale"; from: 0.4; to: 1.0; duration: 180; easing.type: Easing.OutBack }
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 140; easing.type: Easing.OutCubic }
        }

        remove: Transition {
            NumberAnimation { property: "scale"; to: 0.4; duration: 140; easing.type: Easing.InCubic }
            NumberAnimation { property: "opacity"; to: 0; duration: 140; easing.type: Easing.InCubic }
        }

        displaced: Transition {
            NumberAnimation { properties: "x,y"; duration: 220; easing.type: Easing.OutCubic }
        }

        moveDisplaced: Transition {
            NumberAnimation { properties: "x,y"; duration: 220; easing.type: Easing.OutCubic }
        }

        delegate: Item {
            id: delegateRoot
            required property string _key
            required property int index

            readonly property var payload: {
                let items = dockRoot.displayModel;
                if (!items) return null;
                for (let i = 0; i < items.length; i++) {
                    if (items[i] && items[i].key === _key) return items[i];
                }
                return null;
            }

            readonly property bool isSeparator: delegateRoot.payload ? !!delegateRoot.payload.isSeparator : false

            width: isSeparator ? 1 : 28
            height: 32

            z: dockRoot.draggingKey === delegateRoot.itemKey ? 100 : 0

            readonly property real targetXOffset: {
                if (dockRoot.draggingKey === "") return 0;
                
                if (dockRoot.draggingKey === delegateRoot.itemKey) {
                    let clampedX = Math.max(0, Math.min((dockRoot.pinnedApps.length - 1) * 34, dockRoot.dragX - dockRoot.dragClickOffset));
                    return clampedX - (index * 34);
                }
                
                return 0;
            }

            property real visualOffset: targetXOffset

            Behavior on visualOffset {
                enabled: dockRoot.isReleasing || (dockRoot.draggingKey !== delegateRoot.itemKey)
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }

            Loader {
                id: inner
                x: ((delegateRoot.width - width) / 2) + delegateRoot.visualOffset
                y: (delegateRoot.height - height) / 2
                width: delegateRoot.width
                height: delegateRoot.isSeparator ? 32 : 28
                sourceComponent: delegateRoot.isSeparator ? separatorComponent : dockItemComponent
            }

            Binding {
                target: inner.item
                property: "modelData"
                value: delegateRoot.payload
                when: inner.item !== null
            }

            readonly property string itemKey: _key
            readonly property bool isPinned: delegateRoot.payload ? !!delegateRoot.payload.isPinned : false
            readonly property string appId: delegateRoot.payload ? (delegateRoot.payload.appId ?? "") : ""
            readonly property var toplevels: inner.item ? inner.item.toplevels : []
        }
    }

    Component {
        id: separatorComponent

        Item {
            property var modelData
            readonly property var toplevels: []
            width: 1
            height: 32

            Rectangle {
                width: 1
                height: 18
                anchors.centerIn: parent
                radius: 0.5
                color: Qt.alpha(Colors.md3.outline_variant, 0.6)
            }

            opacity: 0
            Component.onCompleted: opacity = 1
            Behavior on opacity {
                NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
            }
        }
    }

    Component {
        id: dockItemComponent

        DockItem {
            dockRoot: dockRoot
            hoverPopup: hoverPopup
        }
    }

    DockHover {
        id: hoverPopup
        dockRoot: dockRoot
    }
}