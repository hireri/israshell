pragma Singleton
import QtQuick
import Quickshell
import qs.style
import qs.components

Singleton {
    id: root

    readonly property var knownTypes: ["photo", "music"]
    readonly property var singletonTypes: ["music"]

    function isSingleton(type) {
        return root.singletonTypes.indexOf(type) !== -1;
    }

    function canAddInstance(type) {
        if (root.knownTypes.indexOf(type) === -1)
            return false;
        if (!root.isSingleton(type))
            return true;
        return !(Config.desktopWidgets ?? []).some(w => w.type === type);
    }

    readonly property var _defaultsByType: ({
        photo: { enabled: false, mirror: true, x: 100, y: 100, size: 200, positions: {}, data: { imagePath: "", shape: "circle" } },
        music: { enabled: false, mirror: true, x: 100, y: 100, size: 180, positions: {}, data: { buttonScale: 0.28 } }
    })

    Component { id: photoComp; PhotoWidget {} }
    Component { id: musicComp; MusicWidget {} }

    readonly property var componentMap: ({
        photo: photoComp,
        music: musicComp
    })

    property var _idList: []
    readonly property var enabledIds: root._idList

    function _recomputeIdList() {
        const ids = (Config.desktopWidgets ?? []).filter(w => w.enabled).map(w => w.id);
        const same = ids.length === root._idList.length && ids.every((id, i) => id === root._idList[i]);
        if (!same)
            root._idList = ids;
    }

    Connections {
        target: Config
        function onDesktopWidgetsChanged() {
            root._recomputeIdList();
        }
    }

    Component.onCompleted: root._recomputeIdList()

    function entryFor(id) {
        return (Config.desktopWidgets ?? []).find(w => w.id === id) ?? null;
    }

    function countOf(type) {
        return (Config.desktopWidgets ?? []).filter(w => w.type === type).length;
    }

    function firstOf(type) {
        return (Config.desktopWidgets ?? []).find(w => w.type === type) ?? null;
    }

    function addWidget(type) {
        if (!root.canAddInstance(type))
            return null;
        const defaults = root._defaultsByType[type];
        if (!defaults)
            return null;
        const offset = root.countOf(type) * 40;
        const id = type + "-" + Math.random().toString(36).slice(2, 9);
        const entry = Object.assign({}, defaults, {
            id: id,
            enabled: true,
            x: (defaults.x ?? 100) + offset,
            y: (defaults.y ?? 100) + offset,
            data: Object.assign({}, defaults.data),
            positions: {}
        });
        Config.update({ desktopWidgets: (Config.desktopWidgets ?? []).concat([entry]) });
        return id;
    }

    function removeEntry(id) {
        Config.update({ desktopWidgets: (Config.desktopWidgets ?? []).filter(w => w.id !== id) });
    }

    function updateEntry(id, patch) {
        const list = (Config.desktopWidgets ?? []).map(w => w.id === id ? Object.assign({}, w, patch) : w);
        Config.update({ desktopWidgets: list });
    }

    function updateEntryData(id, dataPatch) {
        const list = (Config.desktopWidgets ?? []).map(w => w.id === id ? Object.assign({}, w, { data: Object.assign({}, w.data, dataPatch) }) : w);
        Config.update({ desktopWidgets: list });
    }

    function updateEntryPosition(id, monitorName, pos) {
        const list = (Config.desktopWidgets ?? []).map(w => {
            if (w.id !== id)
                return w;
            const positions = Object.assign({}, w.positions);
            positions[monitorName] = pos;
            return Object.assign({}, w, { positions: positions });
        });
        Config.update({ desktopWidgets: list });
    }

    function reconcile(list) {
        if (!Array.isArray(list))
            return [];

        const seenIds = new Set();
        const seenSingletonTypes = new Set();
        const out = [];
        for (const raw of list) {
            if (!raw || typeof raw !== "object")
                continue;
            if (root.knownTypes.indexOf(raw.type) === -1)
                continue;
            if (root.isSingleton(raw.type)) {
                if (seenSingletonTypes.has(raw.type))
                    continue;
                seenSingletonTypes.add(raw.type);
            }

            const defaults = root._defaultsByType[raw.type];
            let id = raw.id;
            if (!id || seenIds.has(id))
                id = raw.type + "-" + Math.random().toString(36).slice(2, 9);
            seenIds.add(id);

            out.push(Object.assign({}, defaults, raw, {
                id: id,
                data: Object.assign({}, defaults.data, raw.data),
                positions: Object.assign({}, defaults.positions, raw.positions)
            }));
        }
        return out;
    }
}
