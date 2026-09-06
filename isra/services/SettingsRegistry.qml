pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.style
import "fuzzy.js" as Fuzzy

Singleton {
    id: root

    readonly property string _cacheVersion: "2"

    property bool _initialized: false
    property bool _instancesLoaded: false
    property bool _cacheValid: false
    property string _loadedKey: ""

    property var pageDefs: []
    property var entries: []
    property var byPath: ({})

    readonly property string cachePath: Quickshell.cacheDir + "/settings-registry.json"

    function init(defs) {
        if (root._initialized)
            return;
        root._initialized = true;
        root.pageDefs = defs;
        root._loadCache();
    }

    function pageInstance(key) {
        root.ensureInstances();
        return root._pageInstances[key] ?? null;
    }

    function ensureInstances() {
        if (root._instancesLoaded)
            return;
        root._instancesLoaded = true;
        root._ensureContainer();
        for (let i = 0; i < root.pageDefs.length; i++)
            root._createPage(i);
        cacheWriteSettle.restart();
    }

    property var _container: null

    Component {
        id: containerComp
        Item {}
    }

    function _ensureContainer() {
        if (!root._container)
            root._container = containerComp.createObject(null);
    }

    property var _pageInstances: ({})

    function _createPage(index) {
        const def = root.pageDefs[index];
        if (!def)
            return;
        const comp = Qt.createComponent("../windows/" + def.source);
        if (comp.status === Component.Error) {
            console.warn("[SettingsRegistry] failed to load page '" + def.key + "':", comp.errorString());
            return;
        }
        const item = comp.createObject(root._container);
        if (item)
            root._pageInstances[def.key] = item;
        else
            console.warn("[SettingsRegistry] failed to instantiate page '" + def.key + "'");
    }

    function register(source) {
        const ctx = root._contextFor(source);
        if (!ctx.page || ctx.page.pageId === "")
            return;

        const settingKey = source.settingKey || root.slugify(root._labelOf(source));
        if (settingKey === "")
            return;

        const sectionKey = ctx.section ? (ctx.section.sectionKey || root.slugify(ctx.section.label || "")) : "";
        const segments = [ctx.page.pageId];
        if (sectionKey !== "")
            segments.push(sectionKey);
        segments.push(settingKey);
        let path = segments.join(".");

        const type = source.settingType || "custom";
        const entry = {
            source: source,
            path: path,
            pageId: ctx.page.pageId,
            page: ctx.page.title || ctx.page.pageId,
            sectionPath: sectionKey !== "" ? ctx.page.pageId + "." + sectionKey : ctx.page.pageId,
            section: ctx.section ? (ctx.section.label || sectionKey) : "",
            label: root._labelOf(source),
            sublabel: root._sublabelOf(source),
            type: type,
            meta: source.settingsMeta !== undefined ? source.settingsMeta : root._metaFor(source, type),
            keywords: (source.settingKeywords || "").split(",").map(k => k.trim().toLowerCase()).filter(Boolean)
        };
        root._buildSearchCache(entry);

        const existing = root.byPath[path];
        if (existing) {
            if (existing.source === null) {
                root.entries[root.entries.indexOf(existing)] = entry;
                root.byPath[path] = entry;
                return;
            }
            console.warn("[SettingsRegistry] duplicate settings path '" + path + "' — suffixing");
            let n = 2;
            while (root.byPath[path + "-" + n] !== undefined)
                n++;
            entry.path = path + "-" + n;
        }

        root.entries.push(entry);
        root.byPath[entry.path] = entry;
    }

    Connections {
        target: Localization
        function onLanguageChanged() {
            root.refreshTranslations();
        }
    }

    function refreshTranslations() {
        if (!root._initialized)
            return;
        let changed = false;
        for (const entry of root.entries) {
            if (entry.source === null)
                continue;
            const ctx = root._contextFor(entry.source);
            const label = root._labelOf(entry.source);
            const sublabel = root._sublabelOf(entry.source);
            const page = ctx.page ? (ctx.page.title || ctx.page.pageId) : entry.page;
            const section = ctx.section ? (ctx.section.label || entry.section) : entry.section;
            if (label === entry.label && sublabel === entry.sublabel && page === entry.page && section === entry.section)
                continue;
            entry.label = label;
            entry.sublabel = sublabel;
            entry.page = page;
            entry.section = section;
            root._buildSearchCache(entry);
            changed = true;
        }
        if (changed)
            root._writeCache(true);
    }

    function unregister(source) {
        for (let i = root.entries.length - 1; i >= 0; i--) {
            if (root.entries[i].source === source) {
                delete root.byPath[root.entries[i].path];
                root.entries.splice(i, 1);
            }
        }
    }

    function search(query) {
        const q = (query || "").trim().toLowerCase();
        if (q === "")
            return [];
        const tokens = q.split(/\s+/).filter(Boolean);
        const scored = [];
        for (const entry of root.entries) {
            let total = 0;
            let allMatched = true;
            for (const token of tokens) {
                const s = root._scoreEntry(token, entry);
                if (s === undefined) {
                    allMatched = false;
                    break;
                }
                total += s;
            }
            if (allMatched)
                scored.push({
                    entry: entry,
                    score: total
                });
        }
        scored.sort((a, b) => b.score - a.score);
        return scored.map(r => r.entry);
    }

    function readValue(entry) {
        const s = entry.source;
        if (!s)
            return null;
        if (typeof s.settingsValue === "function")
            return s.settingsValue();
        const reader = root._readers[entry.type];
        return reader ? reader(s) : null;
    }

    property var _readers: ({
        "switch": s => s.checked,
        "slider": s => s.value,
        "select": s => s.currentValue,
        "chips": s => s.currentValue,
        "input": s => s.value,
        "textarea": s => s.value,
        "time": s => s.value
    })

    function apply(path, value) {
        root.ensureInstances();
        const entry = root.byPath[path];
        if (!entry || !entry.source)
            return "error: no such setting: " + path;
        const parsed = root._parseFor(entry.type, value);
        if (parsed === undefined)
            return "error: cannot parse '" + value + "' as " + entry.type;
        entry.source.applyValue(parsed);
        return "ok";
    }

    function toggle(path) {
        root.ensureInstances();
        const entry = root.byPath[path];
        if (!entry || !entry.source)
            return "error: no such setting: " + path;
        if (entry.type !== "switch")
            return "error: '" + path + "' is a " + entry.type + ", not a switch";
        entry.source.applyValue(!root.readValue(entry));
        return "ok";
    }

    function getJson(path) {
        root.ensureInstances();
        const entry = root.byPath[path];
        if (!entry || !entry.source)
            return JSON.stringify({
                error: "no such setting: " + path
            });
        return JSON.stringify({
            path: entry.path,
            label: entry.label,
            sublabel: entry.sublabel,
            type: entry.type,
            page: entry.page,
            section: entry.section,
            value: root.readValue(entry)
        });
    }

    function searchJson(query) {
        return JSON.stringify(root.search(query).map(e => root.publicEntry(e)));
    }

    function listJson(path) {
        const want = (path || "").replace(/^\.+|\.+$/g, "");
        const tree = root._tree();
        if (want === "")
            return JSON.stringify(tree);
        const segs = want.split(".");
        let node = tree.children.find(c => c.path === segs[0]);
        for (let i = 1; node && i < segs.length; i++)
            node = (node.children ?? []).find(c => c.path === segs.slice(0, i + 1).join("."));
        return JSON.stringify(node ?? {
            error: "no such path: " + want
        });
    }

    function publicEntry(entry) {
        return {
            path: entry.path,
            pageId: entry.pageId,
            page: entry.page,
            sectionPath: entry.sectionPath,
            section: entry.section,
            label: entry.label,
            sublabel: entry.sublabel,
            type: entry.type,
            meta: entry.meta
        };
    }

    Timer {
        id: cacheWriteSettle
        interval: 300
        onTriggered: {
            const pruned = root._pruneAdopted();
            root._writeCache(pruned > 0);
        }
    }

    function _pruneAdopted() {
        let removed = 0;
        for (let i = root.entries.length - 1; i >= 0; i--) {
            if (root.entries[i].source !== null)
                continue;
            delete root.byPath[root.entries[i].path];
            root.entries.splice(i, 1);
            removed++;
        }
        return removed;
    }

    function _contextFor(source) {
        let page = null;
        let section = null;
        let obj = source.parent;
        while (obj) {
            if (!section && obj.settingsSection === true)
                section = obj;
            if (obj.settingsPage === true) {
                page = obj;
                break;
            }
            obj = obj.parent;
        }
        return {
            page: page,
            section: section
        };
    }

    function _labelOf(source) {
        return source.label !== undefined ? source.label : (source.title || "");
    }

    function _sublabelOf(source) {
        return source.sublabel !== undefined ? source.sublabel : (source.subtitle || "");
    }

    function _metaFor(source, type) {
        switch (type) {
        case "slider":
            return {
                from: source.from,
                to: source.to,
                stepSize: source.stepSize,
                unit: source.unit,
                decimals: source.decimals
            };
        case "select":
        case "chips":
            return {
                options: (source.options ?? []).map(o => typeof o === "object" && o !== null ? {
                    value: o.value,
                    label: o.label
                } : o)
            };
        case "input":
            return {
                placeholder: source.placeholder,
                password: source.password
            };
        case "textarea":
            return {
                placeholder: source.placeholder
            };
        default:
            return {};
        }
    }

    function _buildSearchCache(entry) {
        const bands = [{
            text: (entry.label || "").toLowerCase(),
            band: {
                exact: 1000,
                startsWith: 900,
                includes: 800,
                fuzzy: 700
            }
        }, {
            text: (entry.sublabel || "").toLowerCase(),
            band: {
                startsWith: 600,
                includes: 550,
                fuzzy: 500
            }
        }, {
            text: (entry.path || "").toLowerCase(),
            band: {
                startsWith: 300,
                includes: 260,
                fuzzy: 220
            }
        }];
        for (const kw of entry.keywords)
            bands.push({
                text: kw,
                band: {
                    exact: 450,
                    startsWith: 400,
                    includes: 380,
                    fuzzy: 350
                }
            });
        entry._bands = bands;
    }

    function _scoreEntry(token, entry) {
        let best;
        const bands = entry._bands;
        for (let i = 0; i < bands.length; i++) {
            const f = bands[i];
            const s = Fuzzy.scoreText(token, f.text, f.band);
            if (s !== undefined && (best === undefined || s > best))
                best = s;
        }
        return best;
    }

    function _parseFor(type, value) {
        const str = String(value);
        switch (type) {
        case "switch": {
            const v = str.trim().toLowerCase();
            if (["true", "1", "on", "yes"].includes(v))
                return true;
            if (["false", "0", "off", "no"].includes(v))
                return false;
            return undefined;
        }
        case "slider": {
            const v = parseFloat(str);
            return isNaN(v) ? undefined : v;
        }
        case "select":
        case "chips": {
            try {
                return JSON.parse(str);
            } catch (e) {
                return str;
            }
        }
        default:
            return str;
        }
    }

    function _tree() {
        const pageNodes = [];
        const pageIndex = {};
        for (const def of root.pageDefs) {
            const node = {
                path: def.key,
                type: "page",
                label: def.title !== undefined ? def.title : (def.titleKey ? Localization.t(def.titleKey) : def.key),
                children: []
            };
            pageNodes.push(node);
            pageIndex[def.key] = node;
        }
        for (const entry of root.entries) {
            const segs = entry.path.split(".");
            let node = pageIndex[segs[0]];
            if (!node)
                continue;
            for (let i = 1; i < segs.length - 1; i++) {
                const segPath = segs.slice(0, i + 1).join(".");
                let child = node.children.find(c => c.path === segPath);
                if (!child) {
                    child = {
                        path: segPath,
                        type: "section",
                        label: entry.section || segs[i],
                        children: []
                    };
                    node.children.push(child);
                }
                node = child;
            }
            node.children.push({
                path: entry.path,
                type: "setting",
                widgetType: entry.type,
                label: entry.label,
                sublabel: entry.sublabel
            });
        }
        return {
            path: "",
            type: "root",
            label: "",
            children: pageNodes
        };
    }

    function slugify(text) {
        return text.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
    }

    FileView {
        id: cacheFile
        path: root.cachePath
        onLoaded: root._loadCache()
    }

    function _loadCache() {
        let text;
        try {
            text = cacheFile.text();
        } catch (e) {
            return;
        }
        if (!text)
            return;
        try {
            const data = JSON.parse(text);
            if (!Array.isArray(data.entries))
                return;
            root._loadedKey = data.key ?? "";
            for (const e of data.entries) {
                if (typeof e.path !== "string" || typeof e.type !== "string")
                    continue;
                const entry = Object.assign({
                    source: null,
                    pageId: "",
                    page: "",
                    sectionPath: "",
                    section: "",
                    label: "",
                    sublabel: "",
                    meta: {},
                    keywords: []
                }, e);
                root._buildSearchCache(entry);
                root.entries.push(entry);
                root.byPath[e.path] = entry;
            }
            root._cacheKeyReady();
        } catch (e) {
            console.warn("[SettingsRegistry] failed to read cache:", e);
            root.entries = [];
            root.byPath = ({});
        }
    }

    function _writeCache(force) {
        if (root._cacheValid && !force)
            return;
        root._cacheValid = true;
        cacheFile.setText(JSON.stringify({
            key: root._cacheVersion,
            entries: root.entries.map(e => root.publicEntry(e))
        }));
    }

    function _cacheKeyReady() {
        if (root._loadedKey !== "" && root._loadedKey === root._cacheVersion) {
            root._cacheValid = true;
            return;
        }
        root.ensureInstances();
    }
}
