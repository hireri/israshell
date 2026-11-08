import Quickshell
import Quickshell.Io
import QtQuick
import qs.services

Scope {
    id: root

    readonly property string panelType: "overview"
    readonly property bool excludeFromBarOverlay: false
    property bool isOpen: false
    property var _targetScreen: null

    property var windows: []
    property int selected: 0

    readonly property var specialNames: {
        const names = [];
        for (const w of windows)
            if (w.workspaceId < 0 && !names.includes(w.workspaceName))
                names.push(w.workspaceName);
        return names;
    }

    onIsOpenChanged: isOpen ? PanelService.opened(root, root._targetScreen) : PanelService.closed(root)

    function _findFocusedScreen(): var {
        const name = CompositorService.focusedMonitor?.name;
        return Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0] ?? null;
    }

    function _forScreen(list: var): var {
        return list.filter(w => !w.outputName || w.outputName === _targetScreen?.name).sort((a, b) => a.floating - b.floating);
    }

    function load(): void {
        _sig = "";
        windows = _forScreen(CompositorService.windowSnapshot());
    }

    function open(): void {
        _targetScreen = _findFocusedScreen();
        load();
        selected = Math.max(0, Math.min(9, (CompositorService.monitorFor(_targetScreen)?.activeWorkspaceId ?? 1) - 1));
        if (isOpen)
            PanelService.opened(root, _targetScreen);
        else
            isOpen = true;
    }

    function close(): void {
        isOpen = false;
    }

    function toggle(): void {
        if (isOpen && _targetScreen === _findFocusedScreen())
            close();
        else
            open();
    }

    property var pending: null
    function closeThen(action: var): void {
        pending = action;
        close();
        pendingTimer.restart();
    }
    Timer {
        id: pendingTimer
        interval: 80
        onTriggered: {
            const a = root.pending;
            root.pending = null;
            if (a)
                a();
        }
    }

    property bool dragActive: false
    Connections {
        target: CompositorService
        enabled: root.isOpen
        function onWindowEvent(): void {
            liveTimer.restart();
            settleTimer.restart();
        }
    }
    Timer {
        id: liveTimer
        interval: 80
        onTriggered: root._refetch()
    }
    Timer {
        id: settleTimer
        interval: 500
        onTriggered: root._refetch()
    }
    function _refetch(): void {
        if (isOpen && !dragActive)
            CompositorService.fetchWindowSnapshot(list => root._apply(list));
    }

    property string _sig: ""
    function _apply(list: var): void {
        if (!isOpen)
            return;
        const sig = JSON.stringify(list.map(w => [w.address, w.workspaceId, w.workspaceName, w.x, w.y, w.w, w.h, w.floating, w.fullscreen, w.monitor, !!w.toplevel]));
        if (sig === _sig)
            return;
        _sig = sig;
        windows = _forScreen(list);
    }

    Timer {
        interval: 250
        repeat: true
        running: root.isOpen && !root.dragActive
        onTriggered: root._refetch()
    }

    function moveWindow(address: string, wsId: int, special: string): void {
        dragActive = false;
        CompositorService.moveWindowAndSnapshot(address, wsId, special, list => root._apply(list));
    }

    function closeWindow(address: string): void {
        CompositorService.closeWindow(address);
        closeTimer.restart();
    }
    Timer {
        id: closeTimer
        interval: 150
        onTriggered: CompositorService.fetchWindowSnapshot(list => root._apply(list))
    }

    IpcHandler {
        target: "overview"
        function toggle(): void {
            root.toggle();
        }
        function open(): void {
            root.open();
        }
        function close(): void {
            root.close();
        }
    }
}
