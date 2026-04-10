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
    property bool isDark: true

    property string currentWall: ""
    property string currentDir: Quickshell.env("HOME") + "/Pictures"

    // [{isDir, name, path}]
    property var entries: []

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
        if (path === currentDir) {
            _runList();
        } else {
            currentDir = path;
        }
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
        const walls = entries.filter(e => !e.isDir);
        if (walls.length === 0)
            return;
        const pick = walls[Math.floor(Math.random() * walls.length)];
        selectWall(pick.path);
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
        applyProc.wallPath = currentWall;
        applyProc.mode = isDark ? "dark" : "light";
        applyProc.running = false;
        applyProc.running = true;
    }

    function _runList() {
        loading = true;
        listProc.running = false;
        listProc.command = ["bash", "-c", "{ find " + JSON.stringify(currentDir) + " -maxdepth 1 -mindepth 1 -type d ! -name '.*' -printf '%T@\\tD\\t%f\\t%p\\n'; " + "find " + JSON.stringify(currentDir) + " -maxdepth 1 -mindepth 1 -type f ! -name '.*' " + "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \\) " + "-printf '%T@\\tF\\t%f\\t%p\\n'; } | " + "sort -rn | cut -f2-"];
        listProc.running = true;
    }

    onCurrentDirChanged: _runList()

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
            }
        }
    }

    Process {
        id: currentWallProc
        running: true
        command: ["bash", "-c", "readlink -f ~/.config/hypr/current_wall 2>/dev/null || echo ''"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim();
                if (p)
                    root.currentWall = p;
            }
        }
    }

    Process {
        id: openFolderProc
        command: ["bash", "-c", "export PATH=\"$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH\";" + "xdg-open " + JSON.stringify(root.currentDir)]
        running: false
    }

    Process {
        id: applyProc
        property string wallPath: ""
        property string mode: "dark"
        command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/apply-wallpaper.sh", applyProc.wallPath, applyProc.mode]
        running: false
        onExited: (code, _) => {
            root.applying = false;
            if (code === 0) {
                currentWallProc.running = false;
                currentWallProc.running = true;
            }
        }
    }
}
