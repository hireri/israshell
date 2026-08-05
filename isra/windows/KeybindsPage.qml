import QtQuick
import QtQuick.Layouts

import qs.style
import qs.windows.components

import qs.services

PageBase {
    title: Localization.t("keybindsPage.keybinds")
    subtitle: Localization.t("keybindsPage.shell_shortcuts_read_only")

    SectionCard {
        Layout.fillWidth: true

        KeybindRow {
            action: Localization.t("keybindsPage.open_launcher")
            keys: ["Super", "Space"]
        }
        KeybindRow {
            action: Localization.t("widgetService.quick_settings")
            keys: ["Super", "S"]
        }
        KeybindRow {
            action: Localization.t("keybindsPage.open_settings")
            keys: ["Super", ","]
        }
        KeybindRow {
            action: Localization.t("qsTileService.screenshot")
            keys: ["Super", "Shift", "S"]
        }
        KeybindRow {
            action: Localization.t("keybindsPage.screen_record")
            keys: ["Super", "Shift", "R"]
        }
        KeybindRow {
            action: Localization.t("qsTileService.color_picker")
            keys: ["Super", "Shift", "C"]
        }
        KeybindRow {
            action: Localization.t("keybindsPage.night_light_toggle")
            keys: ["Super", "N"]
        }
        KeybindRow {
            action: Localization.t("keybindsPage.media_play_pause")
            keys: ["Super", "M"]
        }
        KeybindRow {
            action: Localization.t("keybindsPage.open_wallpapers")
            keys: ["Super", "W"]
        }
    }
}
