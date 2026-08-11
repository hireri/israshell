pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import "Shapes.js" as Shapes

Scope {
    id: root

    readonly property var capabilities: []

    property var activeWindow: _windowShape(null)
    property var focusedMonitor: _monitorShape(null)
    property var workspaces: []
    property var monitors: []
    property var windows: []

    property var rawWorkspaces: []
    property var rawWindows: []
    property var rawOutputs: []

    function _windowShape(t): var {
        if (!t)
            return Shapes.emptyWindow();
        return {
            address: (t.id !== undefined && t.id !== null) ? t.id.toString() : "",
            title: t.title ?? "",
            appId: t.app_id ?? t.appId ?? "",
            workspace: t.workspace_id ?? t.workspace ?? -1,
            fullscreen: t.is_fullscreen ?? t.fullscreen ?? false
        };
    }

    function _monitorShape(m): var {
        if (!m)
            return Shapes.emptyMonitor();
        return {
            name: m.name ?? "",
            id: m.id ?? m.name ?? -1,
            activeWorkspaceId: m.active_workspace_id ?? m.activeWorkspaceId ?? -1,
            activeWorkspaceHasFullscreen: m.active_workspace_has_fullscreen ?? m.activeWorkspaceHasFullscreen ?? false
        };
    }

    function _workspaceShape(w): var {
        if (!w)
            return Shapes.emptyWorkspace({ idx: -1 });

        let winCount = 0;
        let hasFs = false;
        if (Array.isArray(rawWindows)) {
            for (let i = 0; i < rawWindows.length; i++) {
                if (rawWindows[i].workspace_id === w.id) {
                    winCount++;
                    if (rawWindows[i].is_fullscreen)
                        hasFs = true;
                }
            }
        }

        return {
            id: w.id ?? -1,
            idx: w.idx ?? -1,
            name: w.name ?? (w.idx !== undefined ? w.idx.toString() : (w.id !== undefined ? w.id.toString() : "")),
            monitor: w.output ?? w.monitor ?? "",
            windows: winCount,
            active: w.is_active ?? w.active ?? false,
            hasFullscreen: hasFs
        };
    }

    function _updateState(): void {
        let outputList = [];
        if (Array.isArray(rawOutputs) && rawOutputs.length > 0) {
            outputList = rawOutputs;
        } else if (rawOutputs && typeof rawOutputs === "object" && Object.keys(rawOutputs).length > 0) {
            outputList = Object.values(rawOutputs);
        } else if (Array.isArray(rawWorkspaces)) {
            let seenOutputs = {};
            for (let i = 0; i < rawWorkspaces.length; i++) {
                let ws = rawWorkspaces[i];
                if (ws.output && !seenOutputs[ws.output]) {
                    seenOutputs[ws.output] = true;
                    let activeWs = rawWorkspaces.find(x => x.output === ws.output && x.is_active);
                    outputList.push({
                        name: ws.output,
                        id: ws.output,
                        active_workspace_id: activeWs ? activeWs.id : -1
                    });
                }
            }
        }
        monitors = outputList.map(m => _monitorShape(m));

        let focusedWs = Array.isArray(rawWorkspaces) ? rawWorkspaces.find(w => w.is_focused) : null;
        let focusedMon = null;
        if (focusedWs && outputList.length > 0) {
            focusedMon = outputList.find(m => m.name === focusedWs.output) ?? null;
        } else if (outputList.length > 0) {
            focusedMon = outputList[0];
        }
        focusedMonitor = _monitorShape(focusedMon);

        let activeWin = null;
        if (Array.isArray(rawWindows)) {
            activeWin = rawWindows.find(w => w.is_focused) ?? null;
        }
        activeWindow = _windowShape(activeWin);

        workspaces = Array.isArray(rawWorkspaces) ? rawWorkspaces.map(w => _workspaceShape(w)) : [];
        windows = Array.isArray(rawWindows) ? rawWindows.map(w => _windowShape(w)) : [];
    }

    function _handleEvent(eventData: string): void {
        if (!eventData || eventData.trim() === "")
            return;

        try {
            let parsed = JSON.parse(eventData);
            let key = Object.keys(parsed)[0];
            let data = parsed[key];

            if (key === "WorkspacesChanged") {
                rawWorkspaces = data.workspaces ?? [];
            } else if (key === "WindowsChanged") {
                rawWindows = data.windows ?? [];
            } else if (key === "OutputsChanged") {
                const rawMap = data.outputs ?? {};
                if (Array.isArray(rawMap)) {
                    rawOutputs = rawMap;
                } else {
                    rawOutputs = Object.keys(rawMap).map(name => Object.assign({ name }, rawMap[name]));
                }
            } else if (key === "WorkspaceActivated") {
                if (Array.isArray(rawWorkspaces)) {
                    let targetWs = rawWorkspaces.find(w => w.id === data.id);
                    let targetOutput = targetWs ? targetWs.output : null;
                    rawWorkspaces = rawWorkspaces.map(w => {
                        if (w.id === data.id) {
                            return Object.assign({}, w, {
                                is_active: true,
                                is_focused: data.focused ? true : w.is_focused
                            });
                        }
                        if (targetOutput && w.output === targetOutput) {
                            return Object.assign({}, w, { is_active: false, is_focused: data.focused ? false : w.is_focused });
                        }
                        if (data.focused) {
                            return Object.assign({}, w, { is_focused: false });
                        }
                        return w;
                    });
                }
            } else if (key === "WorkspaceActiveWindowChanged") {
                if (Array.isArray(rawWorkspaces)) {
                    rawWorkspaces = rawWorkspaces.map(w => {
                        if (w.id === data.workspace_id) {
                            return Object.assign({}, w, { active_window_id: data.active_window_id });
                        }
                        return w;
                    });
                }
            } else if (key === "WindowFocusChanged") {
                if (Array.isArray(rawWindows)) {
                    rawWindows = rawWindows.map(w => {
                        return Object.assign({}, w, { is_focused: (data.id !== null && data.id !== undefined && w.id === data.id) });
                    });
                }
            } else if (key === "WindowOpenedOrChanged" || key === "WindowOpened") {
                if (data.window && Array.isArray(rawWindows)) {
                    let idx = rawWindows.findIndex(w => w.id === data.window.id);
                    if (idx >= 0) {
                        rawWindows[idx] = data.window;
                        rawWindows = [...rawWindows];
                    } else {
                        rawWindows = [...rawWindows, data.window];
                    }
                }
            } else if (key === "WindowClosed") {
                if (Array.isArray(rawWindows)) {
                    rawWindows = rawWindows.filter(w => w.id !== data.id);
                }
            } else if (key === "WindowLayoutsChanged") {
                if (Array.isArray(data?.changes) && Array.isArray(rawWindows)) {
                    const layoutById = {};
                    for (const change of data.changes) {
                        if (Array.isArray(change) && change.length >= 2)
                            layoutById[change[0]] = change[1];
                    }
                    rawWindows = rawWindows.map(w => {
                        if (Object.prototype.hasOwnProperty.call(layoutById, w.id))
                            return Object.assign({}, w, { layout: layoutById[w.id] });
                        return w;
                    });
                }
            }

            _updateState();
        } catch (e) {}
    }

    Process {
        id: eventStreamProcess
        command: ["niri", "msg", "--json", "event-stream"]
        running: true

        stdout: SplitParser {
            onRead: data => root._handleEvent(data)
        }
    }

    function focusDirection(direction: string): void {
        const actionMap = {
            "left": "focus-column-left",
            "right": "focus-column-right",
            "up": "focus-window-up",
            "down": "focus-window-down"
        };
        const act = actionMap[direction] ?? "focus-column-right";
        _dispatchAction([act]);
    }

    function focusMonitor(monitorName: string): void {
        _dispatchAction(["focus-monitor", monitorName]);
    }

    function focusWorkspace(workspaceId: var, monitorName: string): void {
        if (monitorName && monitorName !== "") {
            _dispatchAction(["focus-monitor", monitorName]);
        }
        _dispatchAction(["focus-workspace", workspaceId.toString()]);
    }

    function focusWindow(address: string): void {
        if (address)
            _dispatchAction(["focus-window", "--id", address.toString()]);
    }

    function moveWindowToWorkspace(address: string, workspaceId: var, follow: bool): void {
        if (address) {
            _dispatchAction(["move-window-to-workspace", "--window-id", address.toString(), workspaceId.toString()]);
            if (follow)
                _dispatchAction(["focus-window", "--id", address.toString()]);
        } else {
            _dispatchAction(["move-window-to-workspace", workspaceId.toString()]);
        }
    }

    function moveWindowToMonitor(address: string, monitorName: string, follow: bool): void {
        if (address) {
            _dispatchAction(["move-window-to-monitor", "--id", address.toString(), monitorName]);
            if (follow)
                _dispatchAction(["focus-window", "--id", address.toString()]);
        }
    }

    function closeWindow(address: string): void {
        if (address) {
            _dispatchAction(["close-window", "--id", address.toString()]);
        } else {
            _dispatchAction(["close-window"]);
        }
    }

    function killWindow(address: string): void {
        closeWindow(address);
    }

    function toggleFullscreen(address: string): void {
        if (address) {
            _dispatchAction(["focus-window", "--id", address.toString()]);
        }
        _dispatchAction(["fullscreen-window"]);
    }

    function exec(cmd: string): void {
        Quickshell.execDetached(["sh", "-c", cmd]);
    }

    function dpms(action: string, monitorName: string): void {
        const act = (action === "off") ? "power-off-monitors" : "power-on-monitors";
        _dispatchAction([act]);
    }

    function monitorFor(screen: var): var {
        if (!screen) return _monitorShape(null);
        let mon = monitors.find(m => m.name === screen.name || m.id === screen.id);
        return mon ?? _monitorShape(null);
    }

    function restoreLayout(saved: var, activeMonitor: string, activeWindowAddr: string): void {
        for (let monitorName in saved) {
            _dispatchAction(["focus-monitor", monitorName]);
            _dispatchAction(["focus-workspace", saved[monitorName].toString()]);
        }
        if (activeMonitor !== "") {
            _dispatchAction(["focus-monitor", activeMonitor]);
        }
        if (activeWindowAddr !== "") {
            _dispatchAction(["focus-window", "--id", activeWindowAddr.toString()]);
        }
    }

    function _dispatchAction(args: var): void {
        Quickshell.execDetached(["niri", "msg", "action"].concat(args));
    }
}