pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import qs.style

Singleton {
    id: root

    property bool isOpen: false
    property bool applying: false
    property bool loading: false
    property bool isDark: Config.darkMode
    property string currentWall: ""
    property string currentWallPreview: ""
    property string currentDir: Quickshell.env("HOME") + "/Pictures"

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
        if (currentWall) {
            const wallDir = currentWall.substring(0, currentWall.lastIndexOf("/"));
            if (wallDir && wallDir !== currentDir) {
                currentDir = wallDir;
                return;
            }
        }
        _runList();
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
        isOpen = false;
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

    function randomizeWallhaven() {
        if (applying || loading)
            return;
        const purity = Config.allowNsfw ? "110" : "100";
        const req = new XMLHttpRequest();
        req.open("GET", "https://wallhaven.cc/api/v1/search?sorting=random&purity=" + purity);
        req.onreadystatechange = () => {
            if (req.readyState !== XMLHttpRequest.DONE)
                return;
            if (req.status !== 200) {
                console.log("[Wallpaper] Wallhaven fetch failed:", req.status);
                return;
            }
            try {
                const res = JSON.parse(req.responseText);
                if (!res.data || res.data.length === 0)
                    return;
                const url = res.data[0].path;
                if (!url)
                    return;
                const ext = url.split(".").pop().split("?")[0];
                const dest = Quickshell.env("HOME") + "/Pictures/Random/wallhaven_" + Date.now() + "." + ext;
                wallhavenDownloadProc.url = url;
                wallhavenDownloadProc.dest = dest;
                wallhavenDownloadProc.running = false;
                wallhavenDownloadProc.running = true;
            } catch (e) {
                console.log("[Wallpaper] Wallhaven parse error:", e);
            }
        };
        req.send();
    }

    function randomizeKonachan() {
        if (applying || loading)
            return;
        const req = new XMLHttpRequest();
        req.open("GET", "https://konachan.net/post.json?limit=1&tags=order:random+" + (Config.allowNsfw ? "rating:e" : "rating:s"));
        req.onreadystatechange = () => {
            if (req.readyState !== XMLHttpRequest.DONE)
                return;
            if (req.status !== 200) {
                console.log("[Wallpaper] Konachan fetch failed:", req.status);
                return;
            }
            try {
                const posts = JSON.parse(req.responseText);
                if (!posts || posts.length === 0)
                    return;
                const url = posts[0].file_url;
                if (!url)
                    return;
                const ext = url.split(".").pop().split("?")[0];
                const dest = Quickshell.env("HOME") + "/Pictures/Random/konachan_" + Date.now() + "." + ext;
                konaDownloadProc.url = url;
                konaDownloadProc.dest = dest;
                konaDownloadProc.running = false;
                konaDownloadProc.running = true;
            } catch (e) {
                console.log("[Wallpaper] Konachan parse error:", e);
            }
        };
        req.send();
    }

    function randomizeReddit() {
        if (applying || loading || redditFetchProc.running)
            return;
        const subreddits = ["wallpaper", "ImaginaryLandscapes", "EarthPorn", "SpacePorn"];
        redditFetchProc.subreddit = subreddits[Math.floor(Math.random() * subreddits.length)];
        redditFetchProc.running = true;
    }

    function openFolder() {
        openFolderProc.running = false;
        openFolderProc.running = true;
    }

    function refresh() {
        _runList();
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
        listProc.command = ["bash", "-c", "{ find " + JSON.stringify(currentDir) + " -maxdepth 1 -mindepth 1 -type d ! -name '.*' -printf '%T@\\tD\\t%f\\t%p\\n'; " + "find " + JSON.stringify(currentDir) + " -maxdepth 1 -mindepth 1 -type f ! -name '.*' " + "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' " + "-o -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.webm' -o -iname '*.mov' -o -iname '*.avi' -o -iname '*.m4v' \\) " + "-printf '%T@\\tF\\t%f\\t%p\\n'; } | sort -rn | cut -f2-"];
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
                        isDir: p[0] === "D",
                        name: p[1] ?? "",
                        path: p[2] ?? ""
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
        id: konaDownloadProc
        property string url: ""
        property string dest: ""
        command: ["bash", "-c", "mkdir -p " + JSON.stringify(Quickshell.env("HOME") + "/Pictures/Random") + " && curl -fsSL -o " + JSON.stringify(dest) + " " + JSON.stringify(url)]
        running: false
        onExited: (code, _) => {
            if (code === 0 && konaDownloadProc.dest !== "")
                selectWall(konaDownloadProc.dest);
            else
                console.log("[Wallpaper] Konachan download failed, code:", code);
        }
    }

    Process {
        id: wallhavenDownloadProc
        property string url: ""
        property string dest: ""
        command: ["bash", "-c", "mkdir -p " + JSON.stringify(Quickshell.env("HOME") + "/Pictures/Random") + " && curl -fsSL -o " + JSON.stringify(dest) + " " + JSON.stringify(url)]
        running: false
        onExited: (code, _) => {
            if (code === 0 && wallhavenDownloadProc.dest !== "")
                selectWall(wallhavenDownloadProc.dest);
            else
                console.log("[Wallpaper] Wallhaven download failed, code:", code);
        }
    }

    Process {
        id: redditFetchProc
        property string subreddit: ""
        property string outputBuffer: ""

        command: ["curl", "-s", "-H", "User-Agent: WallpaperPicker/1.0 (by /u/brian518)", "-H", "Accept: application/json", "https://www.reddit.com/r/" + subreddit + "/hot.json?limit=30"]

        stdout: SplitParser {
            splitMarker: ""
            onRead: data => redditFetchProc.outputBuffer += data
        }

        onRunningChanged: {
            if (running) {
                outputBuffer = "";
            } else {
                try {
                    const response = JSON.parse(outputBuffer);
                    const posts = response.data.children;
                    const validPosts = posts.filter(post => {
                        const p = post.data;
                        return !p.is_self && !p.is_video && p.post_hint === "image" && p.url_overridden_by_dest;
                    });

                    if (validPosts.length === 0) {
                        console.log("No valid images found in r/" + subreddit);
                        return;
                    }

                    const randomPost = validPosts[Math.floor(Math.random() * validPosts.length)].data;
                    const finalUrl = (randomPost.url_overridden_by_dest || randomPost.url).replace(/&amp;/g, '&');
                    const ext = finalUrl.split('.').pop().split(/[?#]/)[0] || "jpg";
                    const dest = Quickshell.env("HOME") + "/Pictures/Random/reddit_" + Date.now() + "." + ext;

                    redditDownloadProc.url = finalUrl;
                    redditDownloadProc.dest = dest;
                    redditDownloadProc.running = false;
                    redditDownloadProc.running = true;
                } catch (e) {
                    console.error("Reddit JSON parse error:", e);
                    console.error("Buffer preview:", outputBuffer.substring(0, 300));
                }
            }
        }
    }

    Process {
        id: redditDownloadProc
        property string url: ""
        property string dest: ""
        command: ["bash", "-c", "mkdir -p " + JSON.stringify(Quickshell.env("HOME") + "/Pictures/Random") + " && curl -fsSL -o " + JSON.stringify(dest) + " " + JSON.stringify(url)]
        running: false
        onExited: (code, _) => {
            if (code === 0 && redditDownloadProc.dest !== "")
                selectWall(redditDownloadProc.dest);
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