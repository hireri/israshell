import Quickshell
import Quickshell.Io
import QtQuick

import qs.services

Item {
    id: root

    required property var settingsLoader
    required property var wallpaperPanels
    required property var quickSettingsPanels

    IpcHandler {
        target: "settings"
        function open(page: string): void {
            const map = {
                "overview": 0,
                "network": 1,
                "bar": 2,
                "clock": 3,
                "display": 4,
                "sound": 5,
                "locale": 6,
                "system": 7
            };
            root.settingsLoader.active = true;
            root.settingsLoader.item.visible = true;
            const p = map[page];
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
        target: "powermenu"
        function toggle(): void {
            PowerMenuState.toggle();
        }
    }

    IpcHandler {
        target: "wallpaperpicker"
        function toggle(): void {
            const mon = CompositorService.focusedMonitor;
            const panel = root.wallpaperPanels[mon?.name];
            if (panel)
                panel.toggleSelf();
            else
                console.warn("[IpcHandlers] no wallpaperpicker registered for monitor", mon?.name);
        }
    }

    IpcHandler {
        target: "quicksettings"
        function toggle(): void {
            const mon = CompositorService.focusedMonitor;
            const panel = root.quickSettingsPanels[mon?.name];
            if (panel)
                panel.toggleSelf();
            else
                console.warn("[IpcHandlers] no quicksettings registered for monitor", mon?.name);
        }
    }
}
