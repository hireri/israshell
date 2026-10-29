pragma Singleton
pragma ComponentBehavior: Bound

import qs.services
import qs.services.backends
import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property string backendName: SystemInfo.compositor
    property QtObject backend: null

    Component.onCompleted: {
        console.log("[CompositorService] using " + backendName)
        switch (backendName) {
        case "hyprland":
            backend = hyprlandBackendComp.createObject(root);
            break;
        case "niri":
            backend = niriBackendComp.createObject(root);
            break;
        default:
            console.warn("[CompositorService] no backend for", backendName);
        }
    }

    Component { id: hyprlandBackendComp; HyprlandBackend {} }
    Component { id: niriBackendComp; NiriBackend {} }

    signal panelFocusCleared()
    signal windowEvent()

    Connections {
        target: root.backend
        function onPanelFocusCleared() { root.panelFocusCleared(); }
        function onWindowEvent() { root.windowEvent(); }
    }

    function grabPanelFocus(windows: var): void {
        backend?.grabPanelFocus(windows);
    }

    function releasePanelFocus(): void {
        backend?.releasePanelFocus();
    }

    readonly property var activeWindow: backend?.activeWindow ?? { address: "", title: "", appId: "", workspace: -1, fullscreen: false }
    readonly property var focusedMonitor: backend?.focusedMonitor ?? { name: "", id: -1, activeWorkspaceId: -1, activeWorkspaceHasFullscreen: false }
    readonly property var workspaces: backend?.workspaces ?? []
    readonly property var monitors: backend?.monitors ?? []
    readonly property var windows: backend?.windows ?? []
    readonly property var clientRects: _deriveClientRects(backendName, backend, monitors)

    function _deriveClientRects(backend_: string, backendObj: QtObject, mons: var): var {
        let rects;
        switch (backend_) {
        case "niri":
            rects = _niriClientRects(backendObj);
            break;
        case "hyprland":
            rects = _hyprlandClientRects(backendObj);
            break;
        default:
            rects = [];
        }
        return _filterToVisibleWorkspaces(rects, mons);
    }

    function _niriClientRects(backendObj: QtObject): var {
        const rawWindows = backendObj?.rawWindows;
        const rawWorkspaces = backendObj?.rawWorkspaces;
        const rawOutputs = backendObj?.rawOutputs;
        if (!Array.isArray(rawWindows))
            return [];

        const outputByWorkspace = {};
        if (Array.isArray(rawWorkspaces)) {
            for (const ws of rawWorkspaces)
                outputByWorkspace[ws.id] = ws.output;
        }

        const outputOffsets = {};
        if (Array.isArray(rawOutputs)) {
            for (const out of rawOutputs) {
                if (out.name)
                    outputOffsets[out.name] = { x: out.logical?.x ?? 0, y: out.logical?.y ?? 0 };
            }
        }

        const rects = [];
        for (const w of rawWindows) {
            const layout = w.layout;
            if (!layout || !layout.tile_pos_in_workspace_view || !layout.tile_size)
                continue;

            const pos = layout.tile_pos_in_workspace_view;
            const size = layout.tile_size;
            const offset = outputOffsets[outputByWorkspace[w.workspace_id]] ?? { x: 0, y: 0 };

            rects.push({
                x: offset.x + pos[0],
                y: offset.y + pos[1],
                w: size[0],
                h: size[1],
                workspaceId: w.workspace_id ?? -1,
                fullscreen: w.is_fullscreen ?? false,
                title: w.title ?? "",
                appId: w.app_id ?? ""
            });
        }
        return rects;
    }

    function _hyprlandClientRects(backendObj: QtObject): var {
        const rawWindows = backendObj?.rawWindows;
        if (!Array.isArray(rawWindows))
            return [];

        const rects = [];
        for (const w of rawWindows) {
            if (!w.at || !w.size || w.mapped === false || w.hidden)
                continue;
            rects.push({
                x: w.at[0],
                y: w.at[1],
                w: w.size[0],
                h: w.size[1],
                workspaceId: w.workspace?.id ?? -1,
                fullscreen: w.fullscreen ?? false,
                title: w.title ?? "",
                appId: w.class ?? "",
                address: w.address ?? "",
                toplevel: w.toplevel ?? null,
                floating: w.floating ?? false,
                focusOrder: w.focusHistoryID ?? 0
            });
        }
        const layer = r => r.workspaceId < 0 ? 2 : r.floating ? 1 : 0;
        return rects.sort((a, b) => layer(a) - layer(b) || b.focusOrder - a.focusOrder);
    }

    function _filterToVisibleWorkspaces(rects: var, mons: var): var {
        if (!Array.isArray(rects) || !Array.isArray(mons))
            return [];

        const screenByWs = {};
        for (const m of mons) {
            const scr = Quickshell.screens.find(s => s.name === m.name);
            if (!scr)
                continue;
            if (m.activeWorkspaceId !== -1)
                screenByWs[m.activeWorkspaceId] = scr;
            if (m.specialWorkspaceId)
                screenByWs[m.specialWorkspaceId] = scr;
        }

        const out = [];
        for (const r of rects) {
            const scr = screenByWs[r.workspaceId];
            if (!scr || typeof r.w !== "number" || typeof r.h !== "number")
                continue;
            const x1 = Math.max(r.x, scr.x);
            const y1 = Math.max(r.y, scr.y);
            const x2 = Math.min(r.x + r.w, scr.x + scr.width);
            const y2 = Math.min(r.y + r.h, scr.y + scr.height);
            if (x2 > x1 && y2 > y1)
                out.push({ x: x1, y: y1, w: x2 - x1, h: y2 - y1, workspaceId: r.workspaceId, title: r.title, appId: r.appId,
                    toplevel: x1 === r.x && y1 === r.y && x2 === r.x + r.w && y2 === r.y + r.h ? (r.toplevel ?? null) : null });
        }
        return out;
    }

    function fetchClientRects(done: var): void {
        if (backendName === "hyprland" && backend?.snapshotRaw)
            backend.snapshotRaw(r => done(_filterToVisibleWorkspaces(_hyprlandClientRects({ rawWindows: r.windows }), r.monitors)));
    }

    function windowSnapshot(): var {
        return backend?.snapshotWindows?.() ?? [];
    }

    function fetchWindowSnapshot(done: var): void {
        if (backend?.snapshotAfter)
            backend.snapshotAfter([], done);
    }

    function moveWindowAndSnapshot(address: string, wsId: int, special: string, done: var): void {
        if (backend?.moveWindowSnapshot)
            backend.moveWindowSnapshot(address, wsId, special, done);
    }

    function usableSize(screen: var): var {
        return backend?.usableSize?.(screen) ?? null;
    }

    function focusDirection(direction: string): void {
        backend?.focusDirection(direction);
    }

    function monitorFor(screen: var): var {
        return backend?.monitorFor(screen) ?? { name: "", id: -1, activeWorkspaceId: -1 };
    }

    function focusMonitor(monitorName: string): void {
        backend?.focusMonitor(monitorName);
    }

    function focusWorkspace(workspaceId: var, monitorName: string): void {
        backend?.focusWorkspace(workspaceId, monitorName);
    }

    function focusWindow(address: string): void {
        backend?.focusWindow(address);
    }

    function moveWindowToWorkspace(address: string, workspaceId: var, follow: bool): void {
        backend?.moveWindowToWorkspace(address, workspaceId, follow);
    }

    function moveWindowToMonitor(address: string, monitorName: string, follow: bool): void {
        backend?.moveWindowToMonitor(address, monitorName, follow);
    }

    function toggleSpecial(name: string): void {
        backend?.toggleSpecial?.(name);
    }

    function moveWindowToSpecial(address: string, name: string): void {
        backend?.moveWindowToSpecial?.(address, name);
    }

    function closeWindow(address: string): void {
        backend?.closeWindow(address);
    }

    function killWindow(address: string): void {
        backend?.killWindow(address);
    }

    function toggleFullscreen(address: string): void {
        backend?.toggleFullscreen(address);
    }

    function exec(cmd: string): void {
        backend?.exec(cmd);
    }

    function execFloating(cmd: string): void {
        if (backend?.execFloating)
            backend.execFloating(cmd);
        else
            backend?.exec(cmd);
    }

    function dpms(action: string, monitorName: string): void {
        backend?.dpms(action, monitorName);
    }

    function restoreLayout(saved: var, activeMonitor: string, activeWindowAddr: string): void {
        backend?.restoreLayout(saved, activeMonitor, activeWindowAddr);
    }

    function hasCapability(name: string): bool {
        return !!backend?.capabilities?.includes(name);
    }
}
