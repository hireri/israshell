import QtQuick
import Quickshell
import qs.style
import qs.icons
import qs.services

ContextMenu {
    id: root

    property var widgetDrawer: null

    entries: EditModeService.active ? [
        {
            text: Localization.t("backgroundMenu.add_widget"),
            icon: addIconComp,
            action: () => root.widgetDrawer?.toggle()
        },
        {
            isSep: true
        },
        {
            text: Localization.t("background.undo_changes"),
            icon: undoIconComp,
            action: () => EditModeService.undoChanges()
        },
        {
            text: Localization.t("backgroundMenu.exit_edit_mode"),
            icon: checkIconComp,
            action: () => EditModeService.disable()
        }
    ] : [
        {
            text: Localization.t("backgroundMenu.edit_widgets"),
            icon: editIconComp,
            action: () => EditModeService.enable()
        },
        {
            isSep: true
        },
        {
            text: Localization.t("backgroundMenu.wallpaper"),
            icon: wallpaperIconComp,
            action: () => root.run(["qs", "-c", "isra", "ipc", "call", "wallpaperpicker", "toggle"])
        },
        {
            text: Localization.t("backgroundMenu.settings"),
            icon: settingsIconComp,
            action: () => root.run(["qs", "-c", "isra", "ipc", "call", "settings", "open", "overview"])
        },
        {
            isSep: true
        },
        {
            text: Localization.t("backgroundMenu.open_terminal"),
            icon: terminalIconComp,
            action: () => Quickshell.execDetached({
                    command: ["kitty"],
                    workingDirectory: Quickshell.env("HOME")
                })
        }
    ]

    function run(cmd): void {
        Quickshell.execDetached({ command: cmd });
    }

    Component {
        id: editIconComp
        MaterialIcon {
            name: "edit"
            iconSize: 16
        }
    }
    Component {
        id: addIconComp
        MaterialIcon {
            name: "add"
            iconSize: 16
        }
    }
    Component {
        id: checkIconComp
        MaterialIcon {
            name: "check"
            iconSize: 16
        }
    }
    Component {
        id: undoIconComp
        MaterialIcon {
            name: "history"
            iconSize: 16
        }
    }
    Component {
        id: settingsIconComp
        MaterialIcon {
            name: "settings"
            iconSize: 16
        }
    }
    Component {
        id: wallpaperIconComp
        MaterialIcon {
            name: "wallpapers"
            iconSize: 16
        }
    }
    Component {
        id: terminalIconComp
        MaterialIcon {
            name: "terminal"
            iconSize: 16
        }
    }
}
