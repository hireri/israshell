pragma Singleton
import QtQuick
import Quickshell
import qs.style

Singleton {
    readonly property var pages: [
        {
            key: "overview",
            tint: "#929fc9",
            titleKey: "settingsWindow.overview",
            sublabelKey: "settingsWindow.wallpaper_appearance",
            icon: "overview",
            iconTransition: "wipe-right",
            group: 0,
            source: "OverviewPage.qml"
        },
        {
            key: "network",
            tint: "#8fbacc",
            titleKey: "settingsWindow.connectivity",
            sublabelKey: "settingsWindow.wi_fi_bluetooth",
            icon: "networking",
            iconTransition: "wipe-left",
            group: 1,
            source: "NetworkPage.qml"
        },
        {
            key: "display",
            tint: "#d0b18b",
            titleKey: "settingsWindow.visuals_display",
            sublabelKey: "settingsWindow.night_light_blur",
            icon: "monitor",
            iconTransition: "wipe-down",
            group: 1,
            source: "DisplayPage.qml"
        },
        {
            key: "sound",
            tint: "#ca91af",
            titleKey: "settingsWindow.sound_audio",
            sublabelKey: "settingsWindow.audio_popups",
            icon: "volume-up",
            iconTransition: "wipe-up",
            group: 1,
            source: "SoundPage.qml"
        },
        {
            key: "background",
            tint: "#c992aa",
            titleKey: "settingsWindow.background",
            sublabelKey: "settingsWindow.effects_wallpaper_widgets",
            icon: "panorama",
            iconTransition: "wipe-right",
            group: 2,
            source: "BackgroundPage.qml"
        },
        {
            key: "clock",
            tint: "#d0ae8b",
            titleKey: "settingsWindow.desktop_clock",
            sublabelKey: "settingsWindow.mode_colors",
            icon: "analog-clock",
            iconTransition: "circle",
            group: 2,
            source: "ClockPage.qml"
        },
        {
            key: "bar",
            tint: "#91b6ca",
            titleKey: "settingsWindow.bar",
            sublabelKey: "settingsWindow.layout_media_tray",
            icon: "customization",
            iconTransition: "wipe-up",
            group: 2,
            source: "BarPage.qml"
        },
        {
            key: "floatingdock",
            tint: "#8d98cd",
            titleKey: "widgetService.dock",
            sublabelKey: "settingsWindow.position_hiding_icon_size",
            icon: "call-to-action",
            iconTransition: "circle",
            group: 2,
            source: "DockPage.qml"
        },
        {
            key: "gameoverlay",
            tint: "#aa92c9",
            titleKey: "settingsWindow.game_overlay",
            sublabelKey: "settingsWindow.crosshair_widgets",
            icon: "videogame-asset",
            iconTransition: "circle",
            group: 3,
            source: "GameOverlayPage.qml"
        },
        {
            key: "aiassistant",
            tint: "#9f90cb",
            titleKey: "settingsWindow.ai_assistant",
            sublabelKey: "settingsWindow.provider_prompt_behavior",
            icon: "automation",
            iconTransition: "none",
            group: 3,
            source: "AiAssistantPage.qml"
        },
        {
            key: "calendar",
            tint: "#9cbea2",
            titleKey: "settingsWindow.calendar",
            sublabelKey: "settingsWindow.calendar_sources_sync",
            icon: "calendar-month",
            iconTransition: "none",
            group: 3,
            source: "CalendarPage.qml"
        },
        {
            key: "powermenu",
            tint: "#c99692",
            titleKey: "powerMenuPage.title",
            sublabelKey: "powerMenuPage.sidebar",
            icon: "shutdown",
            iconTransition: "circle",
            group: 3,
            source: "PowerMenuPage.qml"
        },
        {
            key: "locale",
            tint: "#9ac1ba",
            titleKey: "settingsWindow.locale",
            sublabelKey: "settingsWindow.time_date_units",
            icon: "earth",
            iconTransition: "none",
            group: 3,
            source: "LocalePage.qml"
        },
        {
            key: "system",
            tint: "#a8afb3",
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
