import Quickshell
import Quickshell.Io
import QtQuick

import qs.services

Item {
    id: root

    required property var settingsLoader
    required property var wallpaperPanels
    required property var quickSettingsPanels

    function _resolvePanel(registry: var): var {
        const monName = CompositorService.focusedMonitor?.name;
        if (monName && registry[monName])
            return registry[monName];
        const fallbackName = Quickshell.screens[0]?.name;
        return fallbackName ? (registry[fallbackName] ?? null) : null;
    }

    IpcHandler {
        target: "settings"
        function open(page: string): void {
            root.settingsLoader.active = true;
            root.settingsLoader.item.visible = true;
            const p = root.settingsLoader.item.pageIndexByName[page];
            if (p !== undefined)
                root.settingsLoader.item.currentPage = p;
        }
    }

    IpcHandler {
        target: "gamemode"
        function toggle(): void {
            GameModeService.toggle();
        }
    }

    IpcHandler {
        target: "aiassistant"
        function toggle(): void {
            AiAssistantService.toggle();
        }
    }

    IpcHandler {
        target: "powermenu"
        function toggle(): void {
            PowerMenuState.toggle();
        }
    }

    IpcHandler {
        target: "wallpaperpicker"
        function toggle(): void {
            const panel = root._resolvePanel(root.wallpaperPanels);
            if (panel)
                panel.toggleSelf();
            else
                console.warn("[IpcHandlers] no wallpaperpicker panel available");
        }
    }

    IpcHandler {
        target: "quicksettings"
        function toggle(): void {
            const panel = root._resolvePanel(root.quickSettingsPanels);
            if (panel)
                panel.toggleSelf();
            else
                console.warn("[IpcHandlers] no quicksettings panel available");
        }
    }
}