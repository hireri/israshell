pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

import qs.style
import qs.services.wallpaperProviders

Singleton {
    id: root

    property bool isOpen: false
    property var openWindow: null
    property bool applying: false
    property bool loading: false
    property bool isDark: Config.darkMode
    property string currentWall: ""
    property string currentWallPreview: ""
    property string currentDir: Quickshell.env("HOME") + "/Pictures"

    property int sortMode: 0

    function cycleSortMode(): void {
        sortMode = (sortMode + 1) % 4;
    }

    property string currentScheme: Config.colorScheme || "scheme-tonal-spot"
    property var schemePreviews: ({})
    property bool previewsLoading: false
    property var sourceColorCandidates: []
    property int currentSourceIndex: Config.sourceColorIndex ?? 0

    property var entries: []

    property int clockRenderWidth: 350
    property int clockRenderHeight: 350
    property bool _pendingRandomize: false
    property bool _pendingAwwwApply: false

    property string _lastClockPath: ""
    property int _lastClockWidth: -1
    property int _lastClockHeight: -1
    property bool _lastClockIsDark: false

    onIsDarkChanged: {
        Config.update({
            darkMode: isDark
        });
        if (currentWall)
            applyTheme();
    }

    onCurrentDirChanged: _runList()

    Connections {
        target: Config
        function onClockChanged() {
            if (!(Config.clock.manualPos ?? false)) {
                root._lastClockPath = "";
                root._runClockPosition();
            }
        }
        function onUseAwwwChanged() {
            root._handleAwwwDaemonState();
        }
    }

    Component.onCompleted: {
        root._handleAwwwDaemonState();
        root.rescanSaved();
    }

    function rescanSaved() {
        savedScanProc.running = false;
        savedScanProc.running = true;
    }

    function _handleAwwwDaemonState() {
        if (Config.useAwww) {
            awwwStartProc.running = false;
            awwwStartProc.running = true;
        } else {
            awwwStopProc.running = false;
            awwwStopProc.running = true;
        }
    }

    function openFor(_panelWindow) {
        openWindow = _panelWindow;
        isOpen = true;
        root.rescanSaved();
        if (currentWall) {
            const wallDir = currentWall.substring(0, currentWall.lastIndexOf("/"));
            if (wallDir && wallDir !== currentDir) {
                currentDir = wallDir;
                return;
            }
        }
        _runList();
    }

    function toggleFor(_panelWindow) {
        if (isOpen && openWindow === _panelWindow) {
            close();
        } else {
            openFor(_panelWindow);
        }
    }

    function close() {
        isOpen = false;
    }

    function navigate(path) {
        if (path === currentDir)
            _runList();
        else
            currentDir = path;
    }

    function selectWall(path) {
        if (applying)
            return;
        applying = true;
        currentWall = path;
        currentWallPreview = "";
        applyProc.wallPath = path;
        applyProc.mode = isDark ? "dark" : "light";
        applyProc.scheme = currentScheme;
        applyProc.sourceColorIndex = Config.sourceColorIndex ?? 0;
        applyProc.wallChanged = true;
        applyProc.running = false;
        applyProc.running = true;
        _runClockPosition();
    }

    function selectScheme(scheme) {
        if (applying || !currentWall)
            return;
        if (currentScheme === scheme)
            return;
        currentScheme = scheme;
        Config.update({
            colorScheme: scheme
        });
        applyTheme();
    }

    function randomize() {
        if (currentWall) {
            const wallDir = currentWall.substring(0, currentWall.lastIndexOf("/"));
            if (wallDir && wallDir !== currentDir) {
                currentDir = wallDir;
                _pendingRandomize = true;
                return;
            }
        }
        const walls = entries.filter(e => !e.isDir);
        if (walls.length === 0)
            return;
        selectWall(walls[Math.floor(Math.random() * walls.length)].path);
    }

    readonly property string savedDir: Quickshell.env("HOME") + "/Pictures/Saved"
    readonly property string randomDir: Quickshell.env("HOME") + "/Pictures/Random"

    property var pendingDownloads: ({})
    property var savedItems: ({})

    property var _dlQueue: []
    property bool _dlBusy: false

    function _setFlag(mapName, id, value) {
        const next = Object.assign({}, root[mapName]);
        if (value === undefined)
            delete next[id];
        else
            next[id] = value;
        root[mapName] = next;
    }

    function fileKey(id) {
        let s = String(id ?? "");
        if (!s)
            return "";
        if (s.indexOf("://") >= 0)
            s = s.split("?")[0].split("/").pop().replace(/\.[^.]*$/, "");
        return s.replace(/[^A-Za-z0-9._-]/g, "_").slice(0, 80);
    }

    function savedPath(id) {
        return root.savedItems[root.fileKey(id)];
    }

    function isPending(id) {
        return root.pendingDownloads[root.fileKey(id)] === true;
    }

    function saveBrowseItem(item, sourceKey, applyAfter, destDir) {
        const id = root.fileKey(item.id || item.full || "");
        if (!id || root.pendingDownloads[id])
            return;
        const have = root.savedItems[id];
        if (have) {
            if (applyAfter === true)
                root.selectWall(have);
            return;
        }
        root._setFlag("pendingDownloads", id, true);
        root._dlQueue.push({
            id: id,
            url: item.full,
            sourceKey: sourceKey,
            applyAfter: applyAfter === true,
            dir: destDir || root.savedDir
        });
        root._pumpDownloads();
    }

    function _pumpDownloads() {
        if (root._dlBusy || root._dlQueue.length === 0)
            return;
        root._dlBusy = true;
        const job = root._dlQueue.shift();
        const ext = job.url.split(".").pop().split("?")[0];
        const isUgoira = ext.toLowerCase() === "zip";
        downloadProc.jobId = job.id;
        downloadProc.applyAfter = job.applyAfter;
        downloadProc.url = job.url;
        downloadProc.dir = job.dir;
        downloadProc.isUgoira = isUgoira;
        downloadProc.dest = job.dir + "/" + job.id + (isUgoira ? ".mp4" : "." + ext);
        downloadProc.tmpZip = job.dir + "/" + job.id + ".zip";
        downloadProc.running = false;
        downloadProc.running = true;
    }

    function _downloadFrom(sourceName, url) {
        saveBrowseItem({
            full: url
        }, sourceName, true, root.randomDir);
    }

    function randomizeWallhaven() {
        if (applying || loading)
            return;
        WallhavenProvider.fetchRandomUrl(Config.allowNsfw, url => _downloadFrom("wallhaven", url), err => console.log("[Wallpaper] Wallhaven fetch failed:", err));
    }

    function randomizeKonachan() {
        if (applying || loading)
            return;
        KonachanProvider.fetchRandomUrl(Config.allowNsfw, url => _downloadFrom("konachan", url), err => console.log("[Wallpaper] Konachan fetch failed:", err));
    }

    function randomizeDanbooru() {
        if (applying || loading)
            return;
        DanbooruProvider.fetchRandomUrl(Config.allowNsfw, url => _downloadFrom("danbooru", url), err => console.log("[Wallpaper] Danbooru fetch failed:", err));
    }

    property ListModel browseModel: ListModel {}
    property bool browseLoading: false
    property bool browseError: false
    property bool browseHasMore: true

    property string browseSort: "top"

    function _providerFor(sourceKey) {
        return sourceKey === "konachan" ? KonachanProvider : sourceKey === "wallhaven" ? WallhavenProvider : sourceKey === "danbooru" ? DanbooruProvider : null;
    }

    function providerName(sourceKey) {
        const p = _providerFor(sourceKey);
        return p ? p.name : "";
    }

    function randomizeFrom(sourceKey) {
        if (sourceKey === "konachan")
            randomizeKonachan();
        else if (sourceKey === "wallhaven")
            randomizeWallhaven();
        else if (sourceKey === "danbooru")
            randomizeDanbooru();
        else
            randomize();
    }

    function resetBrowse() {
        browseModel.clear();
        browseError = false;
        browseHasMore = true;
    }

    property int _browseToken: 0

    function searchProvider(sourceKey, query, page) {
        const provider = _providerFor(sourceKey);
        if (!provider)
            return;
        if (browseLoading && page > 1)
            return;

        const token = ++root._browseToken;
        browseLoading = true;
        provider.search(query, page, Config.allowNsfw, root.browseSort, result => {
            if (token !== root._browseToken)
                return;
            browseLoading = false;
            if (page === 1)
                browseModel.clear();
            const seen = new Set();
            for (let i = 0; i < browseModel.count; i++)
                seen.add(browseModel.get(i).id);
            for (const it of result.items) {
                if (seen.has(it.id))
                    continue;
                seen.add(it.id);
                browseModel.append(it);
            }
            browseHasMore = result.hasMore;
        }, err => {
            if (token !== root._browseToken)
                return;
            browseLoading = false;
            browseError = true;
            console.log("[Wallpaper] " + sourceKey + " search failed:", err);
        });
    }

    function downloadBrowseItem(item, sourceKey) {
        saveBrowseItem(item, sourceKey, true);
    }

    readonly property var fixedDirs: [Quickshell.env("HOME"), Quickshell.env("HOME") + "/Pictures", root.savedDir]

    readonly property var userPins: (Config.pinnedWallpaperDirs ?? []).filter(p => root.fixedDirs.indexOf(p) < 0)

    function isFixedDir(path) {
        return root.fixedDirs.indexOf(path) >= 0;
    }

    function isPinned(path) {
        return root.isFixedDir(path) || (Config.pinnedWallpaperDirs ?? []).indexOf(path) >= 0;
    }

    function togglePin(path) {
        if (!path || root.isFixedDir(path))
            return;
        const list = (Config.pinnedWallpaperDirs ?? []).slice();
        const i = list.indexOf(path);
        if (i >= 0)
            list.splice(i, 1);
        else
            list.push(path);
        Config.update({
            pinnedWallpaperDirs: list
        });
    }

    function openFolder() {
        openFolderProc.running = false;
        openFolderProc.running = true;
    }

    function _fetchCandidates() {
        const target = currentWallPreview || currentWall;
        if (!target)
            return;
        candidatesProc.command = ["matugen", "image", target, "--show-source-colors"];
        candidatesProc.running = false;
        candidatesProc.running = true;
    }

    function selectSourceColor(index) {
        if (applying || !currentWall)
            return;
        if (currentSourceIndex === index)
            return;
        currentSourceIndex = index;
        Config.update({
            sourceColorIndex: index
        });
        applyTheme();
    }

    function applyTheme() {
        if (applying || !currentWall)
            return;
        applying = true;
        applyProc.wallPath = Quickshell.env("HOME") + "/.config/hypr/current_wall";
        applyProc.mode = isDark ? "dark" : "light";
        applyProc.scheme = currentScheme;
        applyProc.sourceColorIndex = Config.sourceColorIndex ?? 0;
        applyProc.running = false;
        applyProc.running = true;
    }

    function reportClockSize(width, height) {
        const w = Math.round(width + 20);
        const h = Math.round(height + 20);
        if (w <= 0 || h <= 0)
            return;
        clockRenderWidth = w;
        clockRenderHeight = h;
        _runClockPosition();
    }

    function _runClockPosition() {
        const previewPath = currentWallPreview || currentWall;
        if (!previewPath || !Config.desktopClock || (Config.clock.manualPos ?? false))
            return;

        const modeStr = isDark ? "dark" : "light";

        if (previewPath === _lastClockPath &&
            clockRenderWidth === _lastClockWidth &&
            clockRenderHeight === _lastClockHeight &&
            isDark === _lastClockIsDark) {
            return;
        }

        const runAction = () => {
            _lastClockPath = previewPath;
            _lastClockWidth = clockRenderWidth;
            _lastClockHeight = clockRenderHeight;
            _lastClockIsDark = isDark;

            clockProc.command = [
                Quickshell.env("HOME") + "/.config/quickshell/isra/scripts/leastbusy.py",
                previewPath,
                "--clock-w", String(clockRenderWidth),
                "--clock-h", String(clockRenderHeight),
                "--mode", modeStr
            ];
            clockProc.running = false;
            clockProc.running = true;
        };

        if (clockDebounceTimer.running) {
            clockDebounceTimer.pendingCallback = runAction;
        } else {
            runAction();
            clockDebounceTimer.start();
        }
    }

    Process {
        id: wallSyncProc
        command: ["readlink", "-f", Quickshell.env("HOME") + "/.config/hypr/current_wall"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim();
                const changed = (p && p !== root.currentWall);
                if (changed) {
                    root.currentWall = p;
                    if (!root.isOpen) {
                        const dir = p.substring(0, p.lastIndexOf("/"));
                        if (dir && dir !== root.currentDir)
                            root.currentDir = dir;
                    }
                    if (!root.currentWallPreview) {
                        root._fetchCandidates();
                    }
                }

                if (root._pendingAwwwApply && p) {
                    root._pendingAwwwApply = false;
                    root.applyTheme();
                }

                previewDebounce.restart();
                if (!root.currentWallPreview) {
                    root._runClockPosition();
                }
            }
        }
    }

    Process {
        id: wallPreviewSyncProc
        command: ["readlink", "-f", Quickshell.env("HOME") + "/.config/hypr/current_wall_prev"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim();
                const changed = (p && p !== root.currentWallPreview);
                if (changed) {
                    root.currentWallPreview = p;
                    root._fetchCandidates();
                }
                root._runClockPosition();
            }
        }
    }

    Timer {
        id: previewDebounce
        interval: 800
        repeat: false
        onTriggered: {
            const target = root.currentWallPreview || root.currentWall;
            if (!target || root.applying)
                return;
            root.previewsLoading = true;
            previewProc.running = false;
            previewProc.command = [Quickshell.env("HOME") + "/.config/quickshell/isra/scripts/gen-scheme-previews.sh", target, root.isDark ? "dark" : "light"];
            previewProc.running = true;
        }
    }

    Timer {
        id: clockDebounceTimer
        interval: 300
        repeat: false
        property var pendingCallback: null
        onTriggered: {
            if (pendingCallback) {
                const cb = pendingCallback;
                pendingCallback = null;
                cb();
                start();
            }
        }
    }

    Process {
        id: previewProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.previewsLoading = false;
                if (!text.trim())
                    return;
                try {
                    root.schemePreviews = JSON.parse(text.trim());
                } catch (e) {
                    console.log("[Wallpaper] Failed to parse scheme previews:", e);
                }
            }
        }
    }

    FileView {
        id: wallSymlink
        path: Quickshell.env("HOME") + "/.config/hypr/current_wall"
        watchChanges: true
        onFileChanged: {
            watchChanges = false;
            Qt.callLater(() => { watchChanges = true; });

            wallSyncProc.running = false;
            wallSyncProc.running = true;
        }
        Component.onCompleted: {
            wallSyncProc.running = true;
        }
    }

    FileView {
        id: wallPreviewSymlink
        path: Quickshell.env("HOME") + "/.config/hypr/current_wall_prev"
        watchChanges: true
        onFileChanged: {
            watchChanges = false;
            Qt.callLater(() => { watchChanges = true; });

            wallPreviewSyncProc.running = false;
            wallPreviewSyncProc.running = true;
        }
        Component.onCompleted: {
            wallPreviewSyncProc.running = true;
        }
    }

    function _runList() {
        loading = true;
        listProc.running = false;
        listProc.command = ["bash", "-c", "{ find " + JSON.stringify(currentDir) + " -maxdepth 1 -mindepth 1 -type d ! -name '.*' -printf '%T@\\tD\\t%f\\t%p\\n'; " + "find " + JSON.stringify(currentDir) + " -maxdepth 1 -mindepth 1 -type f ! -name '.*' " + "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' " + "-o -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.webm' -o -iname '*.mov' -o -iname '*.avi' -o -iname '*.m4v' \\) " + "-printf '%T@\\tF\\t%f\\t%p\\n'; }"];
        listProc.running = true;
    }

    Process {
        id: listProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                const lines = text.trim().split("\n").filter(l => l.trim());
                root.entries = lines.map(l => {
                    const p = l.split("\t");
                    return {
                        mtime: parseFloat(p[0]) || 0,
                        isDir: p[1] === "D",
                        name: p[2] ?? "",
                        path: p[3] ?? ""
                    };
                }).filter(e => e.name);

                if (root._pendingRandomize) {
                    root._pendingRandomize = false;
                    root.randomize();
                }
            }
        }
    }

    Process {
        id: clockProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const positions = {};
                text.trim().split("\n").forEach(line => {
                    const m = line.match(/^([^=]+)=(\d+),(\d+)$/);
                    if (m)
                        positions[m[1]] = {
                            x: parseInt(m[2]),
                            y: parseInt(m[3])
                        };
                });
                if (Object.keys(positions).length > 0) {
                    const newJson = JSON.stringify(positions);
                    if (newJson !== JSON.stringify(Config.clockPositions))
                        Config.update({
                            clockPositions: positions
                        });
                }
            }
        }
    }

    Process {
        id: applyProc
        property string wallPath: ""
        property string mode: "dark"
        property string scheme: "scheme-tonal-spot"
        property int sourceColorIndex: 0
        property bool wallChanged: false

        command: {
            const cmd = [
                Quickshell.env("HOME") + "/.config/quickshell/isra/scripts/apply-wallpaper.sh",
                applyProc.wallPath,
                applyProc.mode,
                applyProc.scheme,
                String(applyProc.sourceColorIndex)
            ];
            if (Config.useAwww) {
                cmd.push("--awww");
                cmd.push("--transition", Config.background.transitionType);
                cmd.push("--duration", String(Config.background.transitionDuration));
                cmd.push("--wipe-angle", String(Config.background.wipeAngle));
                if (Config.background.circleReverse)
                    cmd.push("--circle-reverse");
            }
            return cmd;
        }
        running: false
        onExited: (code, _) => {
            root.applying = false;
            if (code === 0) {
                wallSyncProc.running = false;
                wallSyncProc.running = true;
                wallPreviewSyncProc.running = false;
                wallPreviewSyncProc.running = true;

                wallChanged = false;
                previewDebounce.restart();
            }
        }
    }

    Process {
        id: openFolderProc
        command: ["bash", "-c", "export PATH=\"$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH\"; xdg-open " + JSON.stringify(root.currentDir)]
        running: false
    }

    Process {
        id: downloadProc
        property string url: ""
        property string dir: ""
        property string dest: ""
        property string tmpZip: ""
        property string jobId: ""
        property bool applyAfter: true
        property bool isUgoira: false
        command: isUgoira
            ? ["bash", "-c", "set -e; mkdir -p " + JSON.stringify(dir) + "; curl -fsSL -o " + JSON.stringify(tmpZip) + " " + JSON.stringify(url) + "; trap 'rm -f " + JSON.stringify(tmpZip) + "' EXIT; " + JSON.stringify(Quickshell.env("HOME") + "/.config/quickshell/isra/scripts/ugoira-to-video.sh") + " " + JSON.stringify(tmpZip) + " " + JSON.stringify(dest)]
            : ["bash", "-c", "mkdir -p " + JSON.stringify(dir) + " && curl -fsSL -o " + JSON.stringify(dest) + " " + JSON.stringify(url)]
        running: false
        onExited: (code, _) => {
            root._dlBusy = false;
            root._setFlag("pendingDownloads", downloadProc.jobId, undefined);

            if (code === 0 && downloadProc.dest !== "") {
                root._setFlag("savedItems", downloadProc.jobId, downloadProc.dest);
                if (downloadProc.applyAfter)
                    root.selectWall(downloadProc.dest);
                else if (root.currentDir === downloadProc.dir)
                    root._runList();
            } else {
                console.log("[Wallpaper] Download failed, code:", code);
            }

            root._pumpDownloads();
        }
    }

    Process {
        id: savedScanProc
        command: ["bash", "-c", "find " + JSON.stringify(root.savedDir) + " " + JSON.stringify(root.randomDir) + " -maxdepth 1 -type f -printf '%p\\n' 2>/dev/null"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const next = {};
                for (const line of text.trim().split("\n")) {
                    const path = line.trim();
                    if (!path)
                        continue;
                    const key = path.split("/").pop().replace(/\.[^.]*$/, "");
                    if (key)
                        next[key] = path;
                }
                root.savedItems = next;
            }
        }
    }

    Process {
        id: candidatesProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text.trim())
                    return;
                root.sourceColorCandidates = text.trim().split("\n").filter(l => l.trim() !== "");
            }
        }
    }

    Process {
        id: awwwStartProc
        command: ["bash", "-c", "pgrep -x awww-daemon &>/dev/null || { awww-daemon &>/dev/null & disown; sleep 0.5; }"]
        running: false
        onExited: (code, _) => {
            if (code === 0 && Config.useAwww) {
                if (root.currentWall) {
                    root.applyTheme();
                } else {
                    root._pendingAwwwApply = true;
                }
            }
        }
    }

    Process {
        id: awwwStopProc
        command: ["bash", "-c", "pgrep -x awww-daemon &>/dev/null && awww kill &>/dev/null || true"]
        running: false
    }
}