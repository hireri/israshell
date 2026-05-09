import QtQuick
import QtQuick.Layouts

import qs.style
import qs.settings.components

import qs.services

PageBase {
    title: "Keybinds"
    subtitle: "Shell shortcuts, read only"

    SectionCard {
        Layout.fillWidth: true

        KeybindRow {
            action: "Open launcher"
            keys: ["Super", "Space"]
        }
        KeybindRow {
            action: "Quick settings"
            keys: ["Super", "S"]
        }
        KeybindRow {
            action: "Open settings"
            keys: ["Super", ","]
        }
        KeybindRow {
            action: "Screenshot"
            keys: ["Super", "Shift", "S"]
        }
        KeybindRow {
            action: "Screen record"
            keys: ["Super", "Shift", "R"]
        }
        KeybindRow {
            action: "Color picker"
            keys: ["Super", "Shift", "C"]
        }
        KeybindRow {
            action: "Night light toggle"
            keys: ["Super", "N"]
        }
        KeybindRow {
            action: "Media play/pause"
            keys: ["Super", "M"]
        }
        KeybindRow {
            action: "Open wallpapers"
            keys: ["Super", "W"]
        }
    }
}
