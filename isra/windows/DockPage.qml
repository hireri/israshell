pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import qs.style
import qs.icons
import qs.services
import qs.windows.components

PageBase {
    title: Localization.t("widgetService.dock")
    subtitle: Localization.t("dockPage.a_separate_app_dock_pinned")

    Component { id: arrowUpwardComp; MaterialIcon { name: "arrow-upward"; iconSize: 16 } }
    Component { id: arrowDownwardComp; MaterialIcon { name: "arrow-downward"; iconSize: 16 } }
    Component { id: arrowBackComp; MaterialIcon { name: "arrow-back"; iconSize: 16 } }
    Component { id: arrowForwComp; MaterialIcon { name: "arrow-forward"; iconSize: 16 } }

    SectionCard {
        label: Localization.t("backgroundPage.layout")
        Layout.fillWidth: true

        SettingSwitch {
            label: Localization.t("dockPage.enabled")
            sublabel: Localization.t("dockPage.show_the_floating_dock")
            checked: Config.floatingDock.enabled
            onToggled: v => Config.update({
                floatingDock: Object.assign({}, Config.floatingDock, { enabled: v })
            })
        }

        SettingChips {
            label: Localization.t("dockPage.edge")
            sublabel: Localization.t("dockPage.screen_edge_the_dock_is")
            options: [
                { value: 0, icon: arrowUpwardComp },
                { value: 1, icon: arrowDownwardComp },
                { value: 2, icon: arrowBackComp },
                { value: 3, icon: arrowForwComp }
            ]
            currentValue: Config.floatingDock.edge
            onSelected: v => Config.update({
                floatingDock: Object.assign({}, Config.floatingDock, { edge: v })
            })
        }

        SettingSlider {
            label: Localization.t("dockPage.icon_size")
            sublabel: Localization.t("dockPage.size_of_the_app_icons")
            from: 16
            to: 56
            stepSize: 2
            unit: "px"
            value: Config.floatingDock.iconSize
            onMoved: v => Config.update({
                floatingDock: Object.assign({}, Config.floatingDock, { iconSize: v })
            })
        }

        SettingSwitch {
            label: Localization.t("dockPage.app_launcher_button")
            sublabel: Localization.t("dockPage.show_a_button_that_opens")
            checked: Config.floatingDock.showLauncher
            onToggled: v => Config.update({
                floatingDock: Object.assign({}, Config.floatingDock, { showLauncher: v })
            })
        }

        SettingSwitch {
            isLast: true
            label: Localization.t("dockPage.trash_bin")
            sublabel: Localization.t("dockPage.drag_files_onto_it_to")
            checked: Config.floatingDock.showTrash
            onToggled: v => Config.update({
                floatingDock: Object.assign({}, Config.floatingDock, { showTrash: v })
            })
        }
    }

    SectionCard {
        label: Localization.t("dockPage.behavior")
        Layout.fillWidth: true

        SettingSwitch {
            label: Localization.t("dockPage.always_visible")
            sublabel: Localization.t("dockPage.keep_the_dock_out_and")
            checked: Config.floatingDock.exclusiveZone
            onToggled: v => Config.update({
                floatingDock: Object.assign({}, Config.floatingDock, { exclusiveZone: v })
            })
        }

        SettingSwitch {
            isLast: true
            label: Localization.t("dockPage.smart_hide")
            sublabel: Config.floatingDock.exclusiveZone
                ? "Unavailable while the dock is always visible"
                : "Slide back out whenever no window is in the way"
            enabled: !Config.floatingDock.exclusiveZone
            opacity: Config.floatingDock.exclusiveZone ? 0.6 : 1
            checked: Config.floatingDock.smartHide
            onToggled: v => Config.update({
                floatingDock: Object.assign({}, Config.floatingDock, { smartHide: v })
            })
        }
    }
}
