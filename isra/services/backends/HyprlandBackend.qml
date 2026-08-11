pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "Shapes.js" as Shapes

Scope {
    id: root

    readonly property var capabilities: ["cursorPosition"]

    property var activeWindow: _windowShape(null)
    property var focusedMonitor: _monitorShape(null)
    property var workspaces: []
    property var monitors: []
    property var windows: []

    property var rawWindows: []

    function _windowShape(t): var {
        if (!t)
            return Shapes.emptyWindow({ x: 0, y: 0, w: 0, h: 0 });

        const ipc = t.lastIpcObject;
        const visible = !!ipc && ipc.mapped !== false && !ipc.hidden;

        return {
            address: t.address ?? "",
            title: t.title ?? "",
            appId: t.appId ?? t.wayland?.appId ?? "",
            workspace: t.workspace?.id ?? -1,
            fullscreen: t.wayland?.fullscreen ?? false,
            x: visible ? (ipc.at?.[0] ?? 0) : 0,
            y: visible ? (ipc.at?.[1] ?? 0) : 0,
            w: visible ? (ipc.size?.[0] ?? 0) : 0,
            h: visible ? (ipc.size?.[1] ?? 0) : 0
        };
    }

    function _monitorShape(m): var {
        if (!m)
            return Shapes.emptyMonitor();
        return {
            name: m.name ?? "",
            id: m.id ?? -1,
            activeWorkspaceId: m.activeWorkspace?.id ?? -1,
            activeWorkspaceHasFullscreen: m.activeWorkspace?.hasFullscreen ?? false
        };
    }

    function _workspaceShape(w): var {
        if (!w)
            return Shapes.emptyWorkspace();
        return {
            id: w.id,
            name: w.name,
            monitor: w.monitor?.name ?? "",
            windows: w.lastIpcObject?.windows ?? 0,
            active: w.active,
            hasFullscreen: w.hasFullscreen ?? false
        };
    }

    function _updateState(): void {
        activeWindow = _windowShape(Hyprland.activeToplevel);
        focusedMonitor = _monitorShape(Hyprland.focusedMonitor);
        workspaces = Hyprland.workspaces.values.map(w => _workspaceShape(w));
        monitors = Hyprland.monitors.values.map(m => _monitorShape(m));
        windows = Hyprland.toplevels.values.map(t => _windowShape(t));
        rawWindows = Hyprland.toplevels.values
            .map(t => t.lastIpcObject)
            .filter(ipc => !!ipc);
    }

    Component.onCompleted: {
        _updateState();
    }

    Connections {
        target: Hyprland

        function onActiveToplevelChanged(): void { _updateState(); }
        function onFocusedMonitorChanged(): void { _updateState(); }
        function onFocusedWorkspaceChanged(): void { _updateState(); }

        function onRawEvent(event: HyprlandEvent): void {
            if (event.name === "configreloaded") {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshMonitors();
                Hyprland.refreshToplevels();
            } else if (["workspace", "moveworkspace", "createworkspace", "destroyworkspace"].includes(event.name)) {
                Hyprland.refreshWorkspaces();
            }

            Hyprland.refreshToplevels();
            Qt.callLater(_updateState);
        }
    }

    function focusDirection(direction: string): void {
        _dispatch(`hl.dsp.focus({ direction = "${direction}" })`);
    }

    function focusMonitor(monitorName: string): void {
        _dispatch(`hl.dsp.focus({ monitor = "${monitorName}" })`);
    }

    function focusWorkspace(workspaceId: var, monitorName: string): void {
        if (monitorName !== "")
            _batch([
                `hl.dsp.focus({ monitor = "${monitorName}" })`,
                `hl.dsp.focus({ workspace = ${workspaceId} })`
            ]);
        else
            _dispatch(`hl.dsp.focus({ workspace = ${workspaceId} })`);
    }

    function focusWindow(address: string): void {
        _dispatch(`hl.dsp.focus({ window = "address:${address}" })`);
    }

    function moveWindowToWorkspace(address: string, workspaceId: var, follow: bool): void {
        _dispatch(`hl.dsp.window.move({ workspace = ${workspaceId}, follow = ${follow}, window = "address:${address}" })`);
    }

    function moveWindowToMonitor(address: string, monitorName: string, follow: bool): void {
        _dispatch(`hl.dsp.window.move({ monitor = "${monitorName}", follow = ${follow}, window = "address:${address}" })`);
    }

    function closeWindow(address: string): void {
        _dispatch(address ? `hl.dsp.window.close({ window = "address:${address}" })` : `hl.dsp.window.close()`);
    }

    function killWindow(address: string): void {
        _dispatch(address ? `hl.dsp.window.kill({ window = "address:${address}" })` : `hl.dsp.window.kill()`);
    }

    function toggleFullscreen(address: string): void {
        _dispatch(
            address
                ? `hl.dsp.window.fullscreen({ action = "toggle", window = "address:${address}" })`
                : `hl.dsp.window.fullscreen({ action = "toggle" })`
        );
    }

    function exec(cmd: string): void {
        _dispatch(`hl.dsp.exec_cmd("${cmd.replace(/"/g, '\\"')}")`);
    }

    function dpms(action: string, monitorName: string): void {
        _dispatch(
            monitorName
                ? `hl.dsp.dpms({ action = "${action}", monitor = "${monitorName}" })`
                : `hl.dsp.dpms({ action = "${action}" })`
        );
    }

    function monitorFor(screen: var): var {
        return _monitorShape(Hyprland.monitorFor(screen));
    }

    function restoreLayout(saved: var, activeMonitor: string, activeWindowAddr: string): void {
        const calls = [];
        for (const monitorName in saved) {
            calls.push(`hl.dsp.focus({ monitor = "${monitorName}" })`);
            calls.push(`hl.dsp.focus({ workspace = ${saved[monitorName]} })`);
        }
        if (activeMonitor !== "")
            calls.push(`hl.dsp.focus({ monitor = "${activeMonitor}" })`);
        if (activeWindowAddr !== "")
            calls.push(`hl.dsp.focus({ window = "address:${activeWindowAddr}" })`);

        if (calls.length > 0)
            _batch(calls);
    }

    function _dispatch(cmd: string): void {
        Hyprland.dispatch(cmd);
    }

    function _batch(cmds: list<string>): void {
        const batched = cmds.map(c => `dispatch ${c}`).join(" ; ");
        Quickshell.execDetached(["hyprctl", "--batch", batched]);
    }
}
