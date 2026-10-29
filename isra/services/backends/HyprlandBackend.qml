pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "Shapes.js" as Shapes

Scope {
    id: root

    readonly property var capabilities: ["cursorPosition", "panelFocusGrab"]

    signal panelFocusCleared()

    signal windowEvent()
    readonly property var _windowEvents: ["openwindow", "closewindow", "movewindow", "movewindowv2", "windowtitle", "windowtitlev2", "changefloatingmode", "fullscreen", "moveworkspace", "workspacev2", "pin"]

    HyprlandFocusGrab {
        id: focusGrab
        onCleared: root.panelFocusCleared()
    }

    function grabPanelFocus(windows: var): void {
        focusGrab.windows = windows;
        focusGrab.active = windows.length > 0;
    }

    function releasePanelFocus(): void {
        focusGrab.active = false;
    }

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
            pid: ipc?.pid ?? 0,
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
            specialWorkspaceId: m.lastIpcObject?.specialWorkspace?.id ?? 0,
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
            .filter(t => !!t.lastIpcObject)
            .map(t => Object.assign({}, t.lastIpcObject, { toplevel: t.wayland }));
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
            if (root._windowEvents.includes(event.name))
                root.windowEvent();
            if (event.name === "activespecial") {
                Hyprland.refreshMonitors();
            } else if (event.name === "configreloaded") {
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

    Instantiator {
        model: Hyprland.monitors
        delegate: Connections {
            required property HyprlandMonitor modelData
            target: modelData
            function onLastIpcObjectChanged(): void { _updateState(); }
        }
    }

    Instantiator {
        model: Hyprland.toplevels
        delegate: Connections {
            required property HyprlandToplevel modelData
            target: modelData
            function onLastIpcObjectChanged(): void { _updateState(); }
        }
    }

    function snapshotWindows(clients: var): var {
        const mons = {}, origins = {};
        for (const m of Hyprland.monitors.values) {
            const o = m.lastIpcObject;
            if (o) {
                const sc = o.scale || 1;
                const r = o.reserved ?? [0, 0, 0, 0];
                origins[o.id] = [o.x, o.y];
                mons[o.id] = { x: o.x + r[0], y: o.y + r[1], w: o.width / sc - r[0] - r[2], h: o.height / sc - r[1] - r[3] };
            }
        }
        const handles = {};
        for (const t of Hyprland.toplevels.values)
            if (t.lastIpcObject?.address)
                handles[t.lastIpcObject.address] = t.wayland;

        const onMonitor = (o, org) => !!org && !!o.at && Math.abs(o.at[0] - org[0]) <= 1 && Math.abs(o.at[1] - org[1]) <= 1;

        const list = clients ?? Hyprland.toplevels.values.map(t => t.lastIpcObject).filter(o => !!o);
        return list
            .filter(o => o.address && o.mapped !== false && !o.hidden)
            .sort((a, b) => (a.focusHistoryID ?? 0) - (b.focusHistoryID ?? 0))
            .map(o => ({
                address: o.address,
                appId: o.class ?? "",
                title: o.title || o.class || "",
                workspaceId: o.workspace?.id ?? -1,
                workspaceName: o.workspace?.name ?? "",
                x: o.at?.[0] ?? 0,
                y: o.at?.[1] ?? 0,
                w: o.size?.[0] ?? 0,
                h: o.size?.[1] ?? 0,
                floating: o.floating ?? false,
                fullscreen: (o.fullscreen ?? 0) > 0 && onMonitor(o, origins[o.monitor]),
                monitor: mons[o.monitor] ?? null,
                toplevel: handles[o.address] ?? null
            }));
    }

    function snapshotAfter(dispatches: list<string>, done: var): void {
        if (dispatches.length === 0 && snapProc.running)
            return;
        snapProc.done = done;
        snapProc.command = ["hyprctl", "--batch", dispatches.map(c => `dispatch ${c}`).concat(["j/clients"]).join(" ; ")];
        snapProc.running = false;
        snapProc.running = true;
    }

    Process {
        id: snapProc
        property var done: null
        stdout: StdioCollector {
            onStreamFinished: {
                const cb = snapProc.done;
                snapProc.done = null;
                const i = text.indexOf("[");
                if (!cb || i < 0)
                    return;
                try {
                    cb(root.snapshotWindows(JSON.parse(text.slice(i))));
                } catch (e) {
                    console.warn("[HyprlandBackend] snapshotAfter parse failed:", e);
                }
            }
        }
    }

    function snapshotRaw(done: var): void {
        rawProc.done = done;
        rawProc.running = false;
        rawProc.running = true;
    }

    Process {
        id: rawProc
        property var done: null
        command: ["sh", "-c", "hyprctl -j clients; echo '@@'; hyprctl -j monitors"]
        stdout: StdioCollector {
            onStreamFinished: {
                const cb = rawProc.done;
                rawProc.done = null;
                if (!cb)
                    return;
                try {
                    const [c, m] = text.split("@@");
                    const handles = {};
                    for (const t of Hyprland.toplevels.values)
                        if (t.lastIpcObject?.address)
                            handles[t.lastIpcObject.address] = t.wayland;
                    cb({
                        windows: JSON.parse(c).map(o => Object.assign(o, { toplevel: handles[o.address] ?? null })),
                        monitors: JSON.parse(m).map(o => ({ name: o.name, activeWorkspaceId: o.activeWorkspace?.id ?? -1, specialWorkspaceId: o.specialWorkspace?.id ?? 0 }))
                    });
                } catch (e) {
                    console.warn("[HyprlandBackend] snapshotRaw parse failed:", e);
                }
            }
        }
    }

    function moveWindowSnapshot(address: string, wsId: int, special: string, done: var): void {
        const ws = wsId > 0 ? `${wsId}` : `"special:${special}"`;
        snapshotAfter([`hl.dsp.window.move({ workspace = ${ws}, follow = false, window = "address:${address}" })`], done);
    }

    function usableSize(screen: var): var {
        const o = Hyprland.monitorFor(screen)?.lastIpcObject;
        if (!o)
            return null;
        const sc = o.scale || 1;
        const r = o.reserved ?? [0, 0, 0, 0];
        return { w: o.width / sc - r[0] - r[2], h: o.height / sc - r[1] - r[3] };
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

    function toggleSpecial(name: string): void {
        _dispatch(`hl.dsp.workspace.toggle_special("${name}")`);
    }

    function moveWindowToSpecial(address: string, name: string): void {
        _dispatch(`hl.dsp.window.move({ workspace = "special:${name}", follow = false, window = "address:${address}" })`);
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

    function execFloating(cmd: string): void {
        _dispatch(`hl.dsp.exec_cmd("${cmd.replace(/\\/g, "\\\\").replace(/"/g, '\\"')}", { float = true })`);
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
