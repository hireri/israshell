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
        switch (backendName) {
        case "hyprland":
            backend = hyprlandBackendComp.createObject(root);
            break;
        // case "niri":
        //     backend = niriBackendComp.createObject(root);
        //     break;
        default:
            console.warn("CompositorService: no backend for", backendName);
        }
    }

    Component { id: hyprlandBackendComp; HyprlandBackend {} }
    // Component { id: niriBackendComp; NiriBackend {} }

    readonly property var activeWindow: backend?.activeWindow ?? { address: "", title: "", appId: "", workspace: -1, fullscreen: false }
    readonly property var focusedMonitor: backend?.focusedMonitor ?? { name: "", id: -1, activeWorkspaceId: -1, activeWorkspaceHasFullscreen: false }
    readonly property var workspaces: backend?.workspaces ?? []
    readonly property var monitors: backend?.monitors ?? []
    readonly property var windows: backend?.windows ?? []

    signal workspaceChanged(workspace: var)
    signal windowOpened(window: var)
    signal windowClosed(address: string)

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
