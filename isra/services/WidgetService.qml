pragma Singleton
import QtQuick
import Quickshell
import qs.components

Singleton {
    id: root

    Component { id: activeWindowComp; ActiveWindow {} }
    Component { id: workspacesComp; Workspaces {} }
    Component { id: mediaComp; MediaPlayer {} }
    Component { id: clockComp; BarClock {} }
    Component { id: screencapComp; ScreencapControls {} }
    Component { id: trayComp; TrayWidget {} }
    Component { id: quicksettingsComp; QuickSettings {} }
    Component { id: dockComp; BarDock {} }
    Component { id: launcherComp; LauncherButton {} }
    Component { id: sysMonitorComp; SysMonitor {} }

    readonly property var definitions: [
        { id: "activeWindow",  label: "Active window",  defaultZone: "left",     component: activeWindowComp },
        { id: "workspaces",    label: "Workspaces",     defaultZone: "center",   component: workspacesComp },
        { id: "media",         label: "Media player",   defaultZone: "center",   component: mediaComp },
        { id: "clock",         label: "Clock",          defaultZone: "center",   component: clockComp },
        { id: "sysMonitor",    label: "System monitor", defaultZone: "right",    component: sysMonitorComp },
        { id: "screencap",     label: "Toolbar", defaultZone: "right",    component: screencapComp },
        { id: "tray",          label: "Tray",           defaultZone: "right",    component: trayComp },
        { id: "quicksettings", label: "Quick settings", defaultZone: "right",    component: quicksettingsComp },
        { id: "dock",          label: "Dock",           defaultZone: "disabled", component: dockComp },
        { id: "launcher",      label: "App launcher",   defaultZone: "disabled", component: launcherComp }
    ]

    readonly property var allIds: definitions.map(d => d.id)

    readonly property var componentMap: {
        const m = {};
        for (const d of definitions)
            m[d.id] = d.component;
        return m;
    }

    readonly property var labelMap: {
        const m = {};
        for (const d of definitions)
            m[d.id] = d.label;
        return m;
    }

    function defaultLayout() {
        const layout = { left: [], center: [], right: [], disabled: [] };
        for (const d of definitions)
            layout[d.defaultZone].push(d.id);
        return layout;
    }

    function reconcile(barConfig) {
        const known = new Set([
            ...barConfig.left,
            ...barConfig.center.items,
            ...barConfig.right,
            ...barConfig.disabled
        ]);
        const missing = allIds.filter(id => !known.has(id));
        if (missing.length === 0)
            return barConfig;

        return Object.assign({}, barConfig, {
            disabled: [...barConfig.disabled, ...missing]
        });
    }
}
