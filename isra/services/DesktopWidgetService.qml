pragma Singleton
import QtQuick
import Quickshell
import qs.style
import qs.services
import qs.components

Singleton {
    id: root

    readonly property var knownTypes: ["photo", "music", "weyes", "statring", "weather", "weathercard", "weatherscene", "pomodoro", "githubheatmap", "sunmoon", "fetchcard"]
    readonly property var singletonTypes: ["music", "weyes", "weather", "weathercard", "weatherscene", "pomodoro", "fetchcard"]

    readonly property var _capabilityByType: ({
        weyes: "cursorPosition"
    })

    readonly property var freeformTypes: ["weyes"]

    function isFreeformType(type) {
        return root.freeformTypes.indexOf(type) !== -1;
    }

    function isFreeform(entry) {
        if (!entry)
            return false;
        return root.isFreeformType(entry.type) || (entry.data?.autoPlace ?? false);
    }

    function isSingleton(type) {
        return root.singletonTypes.indexOf(type) !== -1;
    }

    function isAvailable(type) {
        const cap = root._capabilityByType[type];
        return !cap || CompositorService.hasCapability(cap);
    }

    function canAddInstance(type) {
        if (root.knownTypes.indexOf(type) === -1)
            return false;
        if (!root.isAvailable(type))
            return false;
        if (!root.isSingleton(type))
            return true;
        return !(Config.desktopWidgets ?? []).some(w => w.type === type);
    }

    readonly property var _defaultsByType: ({
        photo: { enabled: true, screen: null, cell: { col: 0, row: 0 }, span: { w: 2, h: 2 }, data: { imagePath: "", shape: "circle" } },
        music: { enabled: true, screen: null, cell: { col: 0, row: 0 }, span: { w: 2, h: 2 }, data: { buttonScale: 0.28 } },
        weyes: { enabled: true, mirror: true, x: 100, y: 100, width: 220, height: 120, positions: {}, data: {} },
        statring: { enabled: true, screen: null, cell: { col: 0, row: 0 }, span: { w: 2, h: 2 }, data: { metric: "cpu" } },
        weather: { enabled: true, screen: null, cell: { col: 0, row: 0 }, span: { w: 3, h: 3 }, data: {} },
        weathercard: { enabled: true, screen: null, cell: { col: 0, row: 0 }, span: { w: 5, h: 3 }, data: {} },
        weatherscene: { enabled: true, screen: null, cell: { col: 0, row: 0 }, span: { w: 8, h: 3 }, data: {} },
        pomodoro: { enabled: true, screen: null, cell: { col: 0, row: 0 }, span: { w: 3, h: 3 }, data: {} },
        githubheatmap: { enabled: true, screen: null, cell: { col: 0, row: 0 }, span: { w: 8, h: 3 }, data: { username: "" } },
        sunmoon: { enabled: true, screen: null, cell: { col: 0, row: 0 }, span: { w: 6, h: 3 }, data: { mode: "both", showIllumination: true } },
        fetchcard: { enabled: true, screen: null, cell: { col: 0, row: 0 }, span: { w: 7, h: 4 }, data: { showLogo: true, showSwatches: true } }
    })

    function defaultsFor(type) {
        return root._defaultsByType[type] ?? null;
    }

    function defaultEntry(type) {
        const defaults = root._defaultsByType[type];
        if (!defaults)
            return null;
        return Object.assign({}, defaults, {
            id: type + "-" + Math.random().toString(36).slice(2, 9),
            type: type,
            data: Object.assign({}, defaults.data),
            positions: {}
        });
    }

    Component { id: photoComp; PhotoWidget {} }
    Component { id: musicComp; MusicWidget {} }
    Component { id: weyesComp; Weyes {} }
    Component { id: statRingComp; StatRingWidget {} }
    Component { id: weatherComp; WeatherGlanceWidget {} }
    Component { id: weatherCardComp; WeatherCardWidget {} }
    Component { id: weatherSceneComp; WeatherSceneWidget {} }
    Component { id: pomodoroComp; PomodoroWidget {} }
    Component { id: githubHeatmapComp; GithubHeatmapWidget {} }
    Component { id: sunMoonComp; SunMoonWidget {} }
    Component { id: fetchCardComp; FetchCardWidget {} }

    readonly property var componentMap: ({
        photo: photoComp,
        music: musicComp,
        weyes: weyesComp,
        statring: statRingComp,
        weather: weatherComp,
        weathercard: weatherCardComp,
        weatherscene: weatherSceneComp,
        pomodoro: pomodoroComp,
        githubheatmap: githubHeatmapComp,
        sunmoon: sunMoonComp,
        fetchcard: fetchCardComp
    })

    property var _idList: []
    readonly property var enabledIds: root._idList

    ListModel {
        id: idModel
    }
    readonly property alias entryModel: idModel

    function _syncModel(ids) {
        for (let i = idModel.count - 1; i >= 0; i--) {
            if (ids.indexOf(idModel.get(i).widgetId) === -1)
                idModel.remove(i);
        }
        for (let i = 0; i < ids.length; i++) {
            if (i < idModel.count && idModel.get(i).widgetId === ids[i])
                continue;
            let found = -1;
            for (let j = i; j < idModel.count; j++) {
                if (idModel.get(j).widgetId === ids[i]) {
                    found = j;
                    break;
                }
            }
            if (found >= 0)
                idModel.move(found, i, 1);
            else
                idModel.insert(i, { widgetId: ids[i] });
        }
    }

    function _recomputeIdList() {
        const ids = (Config.desktopWidgets ?? []).filter(w => w.enabled).map(w => w.id);
        const same = ids.length === root._idList.length && ids.every((id, i) => id === root._idList[i]);
        if (!same)
            root._idList = ids;
        root._syncModel(ids);
    }

    Connections {
        target: Config
        function onDesktopWidgetsChanged() {
            root._recomputeIdList();
        }
    }

    Component.onCompleted: root._recomputeIdList()

    readonly property var referenceScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    function referenceSize(fallbackScreen) {
        return {
            width: root.referenceScreen?.width ?? fallbackScreen?.width ?? 1920,
            height: root.referenceScreen?.height ?? fallbackScreen?.height ?? 1080
        };
    }

    function screenTransform(screen) {
        const ref = root.referenceSize(screen);
        const curW = screen?.width ?? ref.width;
        const curH = screen?.height ?? ref.height;
        const scale = Math.max(curW / ref.width, curH / ref.height);
        return {
            scale: scale,
            cropX: (ref.width * scale - curW) / 2,
            cropY: (ref.height * scale - curH) / 2
        };
    }

    function fromReference(screen, refX, refY) {
        const t = root.screenTransform(screen);
        return { x: refX * t.scale - t.cropX, y: refY * t.scale - t.cropY, scale: t.scale };
    }

    function toReference(screen, localX, localY) {
        const t = root.screenTransform(screen);
        return { x: (localX + t.cropX) / t.scale, y: (localY + t.cropY) / t.scale, scale: t.scale };
    }

    function entryFor(id) {
        return (Config.desktopWidgets ?? []).find(w => w.id === id) ?? null;
    }

    function countOf(type) {
        return (Config.desktopWidgets ?? []).filter(w => w.type === type).length;
    }

    function firstOf(type) {
        return (Config.desktopWidgets ?? []).find(w => w.type === type) ?? null;
    }

    function addWidget(type, screen) {
        if (!root.canAddInstance(type))
            return null;
        const defaults = root._defaultsByType[type];
        if (!defaults)
            return null;
        const id = type + "-" + Math.random().toString(36).slice(2, 9);

        const base = {
            id: id,
            type: type,
            enabled: true,
            data: Object.assign({}, defaults.data)
        };

        let entry;
        if (root.isFreeformType(type)) {
            entry = Object.assign({}, defaults, base, { positions: {} });
        } else {
            const target = screen ?? root.referenceScreen;
            const span = defaults.span ?? { w: 2, h: 2 };
            const cell = WidgetGrid.firstFreeCell(target, span.w, span.h, null);
            entry = Object.assign({}, defaults, base, {
                screen: target?.name ?? null,
                cell: { col: cell.col, row: cell.row },
                span: { w: span.w, h: span.h }
            });
        }
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

    function migrateWeyes(rawWeyes, rawWeyesPositions, list) {
        const out = Array.isArray(list) ? list : [];
        if (!rawWeyes || rawWeyes.enabled !== true)
            return out;
        if (out.some(w => w && w.type === "weyes"))
            return out;

        const defaults = root._defaultsByType.weyes;
        return out.concat([Object.assign({}, defaults, {
            id: "weyes-" + Math.random().toString(36).slice(2, 9),
            type: "weyes",
            enabled: true,
            mirror: rawWeyes.mirror ?? true,
            x: rawWeyes.x ?? defaults.x,
            y: rawWeyes.y ?? defaults.y,
            width: rawWeyes.width ?? defaults.width,
            height: rawWeyes.height ?? defaults.height,
            positions: Object.assign({}, rawWeyesPositions ?? {}),
            data: {}
        })]);
    }

    function migrateToGrid(list) {
        const out = Array.isArray(list) ? list : [];
        const ref = root.referenceScreen;

        function spanOf(screen, src, fallback) {
            const w = src.width ?? src.size ?? fallback;
            const h = src.height ?? src.size ?? fallback;
            return WidgetGrid.spanFromPixels(screen, w, h);
        }

        return out.map(entry => {
            if (!entry || typeof entry !== "object")
                return entry;
            if (entry.cell || root.isFreeformType(entry.type))
                return entry;

            const fallback = 180;
            const span = spanOf(ref, entry, fallback);
            const cell = WidgetGrid.clampCell(ref, WidgetGrid.nearestCol(ref, entry.x ?? 100), WidgetGrid.nearestRow(ref, entry.y ?? 100), span.w, span.h);

            const migrated = Object.assign({}, entry, {
                screen: ref?.name ?? null,
                cell: { col: cell.col, row: cell.row },
                span: { w: span.w, h: span.h }
            });

            delete migrated.x;
            delete migrated.y;
            delete migrated.size;
            delete migrated.width;
            delete migrated.height;
            delete migrated.positions;
            return migrated;
        });
    }

    function migrateAbsoluteEntries(list) {
        if (!Array.isArray(list))
            return [];
        const screen = root.referenceScreen;
        return list.map(entry => {
            if (!entry || typeof entry !== "object")
                return entry;
            if (entry.x !== undefined || !entry.cell)
                return entry;
            if (!(entry.data?.autoPlace ?? false))
                return entry;
            const p = WidgetGrid.placementOf(entry, screen);
            const r = WidgetGrid.cellRect(screen, p.col, p.row, p.w, p.h);
            return Object.assign({}, entry, {
                x: Math.round(r.x),
                y: Math.round(r.y),
                width: Math.round(r.width),
                height: Math.round(r.height)
            });
        });
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
