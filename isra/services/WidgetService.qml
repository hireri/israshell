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
        { id: "sysMonitor",    label: "System monitor", defaultZone: "left",    component: sysMonitorComp },
        { id: "media",         label: "Media player",   defaultZone: "center",   component: mediaComp },
        { id: "workspaces",    label: "Workspaces",     defaultZone: "center",   component: workspacesComp },
        { id: "clock",         label: "Clock",          defaultZone: "center",   component: clockComp },
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
        const valid = new Set(allIds);
        const left = barConfig.left.filter(id => valid.has(id));
        const center = barConfig.center.items.filter(id => valid.has(id));
        const right = barConfig.right.filter(id => valid.has(id));
        const disabled = barConfig.disabled.filter(id => valid.has(id));

        const known = new Set([...left, ...center, ...right, ...disabled]);
        const missing = allIds.filter(id => !known.has(id));

        const dropped = (barConfig.left.length + barConfig.center.items.length + barConfig.right.length + barConfig.disabled.length) !== (left.length + center.length + right.length + disabled.length);
        if (missing.length === 0 && !dropped)
            return barConfig;

        return Object.assign({}, barConfig, {
            left: left,
            center: Object.assign({}, barConfig.center, { items: center }),
            right: right,
            disabled: [...disabled, ...missing]
        });
    }
}
