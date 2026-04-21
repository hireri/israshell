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
    property string currentDir: Quickshell.env("HOME") + "/Pictures"

    property var entries: []

    property int clockRenderWidth: 350
    property int clockRenderHeight: 350
    property bool _pendingRandomize: false

    Component.onCompleted: wallSyncProc.running = true

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
        isOpen = false;
        applyProc.wallPath = path;
        applyProc.mode = isDark ? "dark" : "light";
        applyProc.running = false;
        applyProc.running = true;
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

    function openFolder() {
        openFolderProc.running = false;
        openFolderProc.running = true;
    }

    function refresh() {
        _runList();
    }

    function applyTheme() {
        if (applying || !currentWall)
            return;
        applying = true;
        applyProc.wallPath = Quickshell.env("HOME") + "/.config/hypr/current_wall";
        applyProc.mode = isDark ? "dark" : "light";
        applyProc.running = false;
        applyProc.running = true;
    }

    function reportClockSize(width, height) {
        const padding = 10;
        const w = width + (padding * 2);
        const h = height + (padding * 2);

        if (w > 0 && h > 0 && (clockRenderWidth !== w || clockRenderHeight !== h)) {
            clockRenderWidth = w;
            clockRenderHeight = h;
            dimsFile.setText(w + "x" + h);

            if (currentWall && !loading)
                debounceTimer.restart();
        }
    }

    Timer {
        id: debounceTimer
        interval: 100
        onTriggered: _runClockPosition()
    }

    function _runClockPosition() {
        if (!currentWall || !Config.desktopClock)
            return;

        const raw = dimsFile.text().trim();
        const parts = raw.split("x");
        const w = parts.length === 2 ? (parseInt(parts[0]) || clockRenderWidth) : clockRenderWidth;
        const h = parts.length === 2 ? (parseInt(parts[1]) || clockRenderHeight) : clockRenderHeight;

        const mode = isDark ? "dark" : "light";
        clockProc.command = [Quickshell.env("HOME") + "/.config/quickshell/scripts/leastbusy.py", root.currentWall, "--clock-w", String(w), "--clock-h", String(h), "--mode", mode];
        clockProc.running = false;
        clockProc.running = true;
    }

    FileView {
        id: dimsFile
        path: "/tmp/qs-clock-dims"
        blockLoading: true
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            if (!root.applying)
                wallSyncProc.running = true;
        }
    }

    Process {
        id: wallSyncProc
        command: ["readlink", "-f", Quickshell.env("HOME") + "/.config/hypr/current_wall"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim();
                if (p && p !== root.currentWall) {
                    root.currentWall = p;
                    if (!root.isOpen) {
                        const dir = p.substring(0, p.lastIndexOf("/"));
                        if (dir && dir !== root.currentDir)
                            root.currentDir = dir;
                    }
                }
            }
        }
    }

    FileView {
        id: wallSymlink
        path: Quickshell.env("HOME") + "/.config/hypr/current_wall"
        watchChanges: true
        onFileChanged: {
            wallSymlink.reload();
            const p = wallSymlink.text.trim();
            if (p && p !== root.currentWall) {
                root.currentWall = p;
                if (!root.isOpen) {
                    const dir = p.substring(0, p.lastIndexOf("/"));
                    if (dir && dir !== root.currentDir)
                        root.currentDir = dir;
                }
            }
        }
        Component.onCompleted: {
            wallSymlink.reload();
            const p = wallSymlink.text.trim();
            if (p) {
                root.currentWall = p;
                const dir = p.substring(0, p.lastIndexOf("/"));
                if (dir)
                    root.currentDir = dir;
            }
        }
    }

    onCurrentDirChanged: _runList()

    onIsDarkChanged: {
        Config.update({
            darkMode: isDark
        });
        if (currentWall)
            applyTheme();
    }

    function _runList() {
        loading = true;
        listProc.running = false;
        listProc.command = ["bash", "-c", "{ find " + JSON.stringify(currentDir) + " -maxdepth 1 -mindepth 1 -type d ! -name '.*' -printf '%T@\\tD\\t%f\\t%p\\n'; " + "find " + JSON.stringify(currentDir) + " -maxdepth 1 -mindepth 1 -type f ! -name '.*' " + "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \\) " + "-printf '%T@\\tF\\t%f\\t%p\\n'; } | sort -rn | cut -f2-"];
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
        command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/apply-wallpaper.sh", applyProc.wallPath, applyProc.mode]
        running: false
        onExited: (code, _) => {
            root.applying = false;
            if (code === 0)
                debounceTimer.restart();
        }
    }

    Process {
        id: openFolderProc
        command: ["bash", "-c", "export PATH=\"$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH\";" + "xdg-open " + JSON.stringify(root.currentDir)]
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
}
