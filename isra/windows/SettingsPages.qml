pragma Singleton
import QtQuick
import Quickshell
import qs.style

Singleton {
    readonly property var pages: [
        {
            key: "overview",
            titleKey: "settingsWindow.overview",
            sublabelKey: "settingsWindow.wallpaper_appearance",
            icon: "overview",
            iconTransition: "wipe-right",
            group: 0,
            source: "OverviewPage.qml"
        },
        {
            key: "network",
            titleKey: "settingsWindow.connectivity",
            sublabelKey: "settingsWindow.wi_fi_bluetooth",
            icon: "networking",
            iconTransition: "wipe-left",
            group: 0,
            source: "NetworkPage.qml"
        },
        {
            key: "bar",
            titleKey: "settingsWindow.bar",
            sublabelKey: "settingsWindow.layout_media_tray",
            icon: "customization",
            iconTransition: "wipe-up",
            group: 1,
            source: "BarPage.qml"
        },
        {
            key: "floatingdock",
            titleKey: "widgetService.dock",
            sublabelKey: "settingsWindow.position_hiding_icon_size",
            icon: "call-to-action",
            iconTransition: "circle",
            group: 1,
            source: "DockPage.qml"
        },
        {
            key: "background",
            titleKey: "settingsWindow.background",
            sublabelKey: "settingsWindow.effects_wallpaper_widgets",
            icon: "panorama",
            iconTransition: "wipe-right",
            group: 1,
            source: "BackgroundPage.qml"
        },
        {
            key: "clock",
            titleKey: "settingsWindow.desktop_clock",
            sublabelKey: "settingsWindow.mode_colors",
            icon: "analog-clock",
            iconTransition: "circle",
            group: 1,
            source: "ClockPage.qml"
        },
        {
            key: "display",
            titleKey: "settingsWindow.visuals_display",
            sublabelKey: "settingsWindow.night_light_blur",
            icon: "monitor",
            iconTransition: "wipe-down",
            group: 2,
            source: "DisplayPage.qml"
        },
        {
            key: "sound",
            titleKey: "settingsWindow.sound_audio",
            sublabelKey: "settingsWindow.audio_popups",
            icon: "notifications",
            iconTransition: "wipe-up",
            group: 2,
            source: "SoundPage.qml"
        },
        {
            key: "aiassistant",
            titleKey: "settingsWindow.ai_assistant",
            sublabelKey: "settingsWindow.provider_prompt_behavior",
            icon: "automation",
            iconTransition: "none",
            group: 3,
            source: "AiAssistantPage.qml"
        },
        {
            key: "locale",
            titleKey: "settingsWindow.locale",
            sublabelKey: "settingsWindow.time_date_units",
            icon: "language",
            iconTransition: "none",
            group: 3,
            source: "LocalePage.qml"
        },
        {
            key: "system",
            titleKey: "settingsWindow.system",
            sublabelKey: "settingsWindow.about_paths_keybinds",
            icon: "about",
            iconTransition: "circle",
            group: 3,
            source: "SystemPage.qml"
        }
    ]

    readonly property var pageKeys: pages.map(p => p.key)

    function pageDef(key) {
        return pages.find(p => p.key === key) ?? null;
    }

    function pageIndex(key) {
        return pages.findIndex(p => p.key === key);
    }

    function pageTitle(def) {
        return Localization.t(def.titleKey);
    }
}
