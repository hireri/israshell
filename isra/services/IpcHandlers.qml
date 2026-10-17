import Quickshell
import Quickshell.Io
import QtQuick

import qs.services
import qs.windows

Item {
    id: root

    required property var settingsLoader
    required property var systemLoader
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
            root.settingsLoader.item.open(page);
        }

        function search(query: string): string {
            return SettingsRegistry.searchJson(query);
        }

        function list(path: string): string {
            return SettingsRegistry.listJson(path);
        }

        function get(path: string): string {
            return SettingsRegistry.getJson(path);
        }

        function set(path: string, value: string): string {
            return SettingsRegistry.apply(path, value);
        }

        function toggle(path: string): string {
            return SettingsRegistry.toggle(path);
        }
    }

    IpcHandler {
        target: "system"
        function open(page: string): void {
            root.systemLoader.active = true;
            root.systemLoader.item.visible = true;
            root.systemLoader.item.open(page === "" ? "overview" : page);
        }

        function close(): void {
            if (root.systemLoader.item)
                root.systemLoader.item.visible = false;
        }

        function toggle(): void {
            if (root.systemLoader.active && root.systemLoader.item?.visible) {
                root.systemLoader.item.visible = false;
                return;
            }
            root.systemLoader.active = true;
            root.systemLoader.item.visible = true;
            root.systemLoader.item.open("overview");
        }

        function pages(): string {
            return JSON.stringify(SystemPages.pageKeys);
        }
    }

    IpcHandler {
        target: "screentime"
        function status(): string {
            return ScreenTimeService.statusJson();
        }

        function today(): string {
            return ScreenTimeService.todayJson();
        }

        function pause(): void {
            ScreenTimeService.pause();
        }

        function resume(): void {
            ScreenTimeService.resume();
        }

        function toggle(): void {
            ScreenTimeService.toggle();
        }

        function set(key: string, value: string): string {
            return ScreenTimeService.setOption(key, value);
        }

        function exportData(): void {
            ScreenTimeService.exportData();
        }
    }

    IpcHandler {
        target: "health"
        function status(): string {
            return HealthService.statusJson();
        }

        function results(): string {
            return HealthService.resultsJson();
        }

        function refresh(): void {
            HealthService.refresh();
        }

        function set(key: string, value: string): string {
            return HealthService.setOption(key, value);
        }

        function run(action: string, arg: string): string {
            return HealthService.runAction(action, arg);
        }
    }

    IpcHandler {
        target: "gamemode"
        function toggle(): void {
            GameModeService.toggle();
        }
    }

    IpcHandler {
        target: "gameoverlay"
        function toggle(): void {
            GameOverlayService.toggle();
        }
        function crosshair(code: string): void {
            GameOverlayService.setCrosshair(code);
        }
        function unpin(): void {
            GameOverlayService.unpinAll();
        }
    }

    IpcHandler {
        target: "voice"
        function press(): void {
            VoiceService.press();
        }
        function release(): void {
            VoiceService.release();
        }
        function toggle(): void {
            VoiceService.toggle();
        }
        function cancel(): void {
            VoiceService.cancel();
        }
    }

    IpcHandler {
        target: "bedtime"
        function toggle(): void {
            BedtimeService.toggle();
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

    IpcHandler {
        target: "brightness"
        function increment(): void {
            BrightnessService.increaseBrightness();
        }
        function decrement(): void {
            BrightnessService.decreaseBrightness();
        }
        function sleepBegin(): void {
            BrightnessService.sleepBegin();
        }
        function restoreAfterWake(): void {
            BrightnessService.restoreAfterWake();
        }
    }

    IpcHandler {
        target: "editmode"
        function enable(): void {
            EditModeService.enable();
        }
        function disable(): void {
            EditModeService.disable();
        }
        function toggle(): void {
            EditModeService.toggle();
        }
    }
}