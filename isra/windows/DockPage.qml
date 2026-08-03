pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import qs.style
import qs.icons
import qs.services
import qs.windows.components

PageBase {
    title: "Dock"
    subtitle: "A separate app dock, pinned to any screen edge"

    Component { id: arrowUpwardComp; MaterialIcon { name: "arrow-upward"; iconSize: 16 } }
    Component { id: arrowDownwardComp; MaterialIcon { name: "arrow-downward"; iconSize: 16 } }
    Component { id: arrowBackComp; MaterialIcon { name: "arrow-back"; iconSize: 16 } }
    Component { id: arrowForwComp; MaterialIcon { name: "arrow-forward"; iconSize: 16 } }

    SectionCard {
        label: "Layout"
        Layout.fillWidth: true

        SettingSwitch {
            label: "Enabled"
            sublabel: "Show the floating dock"
            checked: Config.floatingDock.enabled
            onToggled: v => Config.update({
                floatingDock: Object.assign({}, Config.floatingDock, { enabled: v })
            })
        }

        SettingChips {
            label: "Edge"
            sublabel: "Screen edge the dock is pinned to"
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
            label: "Icon size"
            sublabel: "Size of the app icons in the dock"
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
            label: "App launcher button"
            sublabel: "Show a button that opens the app launcher"
            checked: Config.floatingDock.showLauncher
            onToggled: v => Config.update({
                floatingDock: Object.assign({}, Config.floatingDock, { showLauncher: v })
            })
        }

        SettingSwitch {
            isLast: true
            label: "Trash bin"
            sublabel: "Drag files onto it to throw them in the trash"
            checked: Config.floatingDock.showTrash
            onToggled: v => Config.update({
                floatingDock: Object.assign({}, Config.floatingDock, { showTrash: v })
            })
        }
    }

    SectionCard {
        label: "Behavior"
        Layout.fillWidth: true

        SettingSwitch {
            label: "Always visible"
            sublabel: "Keep the dock out and reserve space so windows never cover it"
            checked: Config.floatingDock.exclusiveZone
            onToggled: v => Config.update({
                floatingDock: Object.assign({}, Config.floatingDock, { exclusiveZone: v })
            })
        }

        SettingSwitch {
            isLast: true
            label: "Smart hide"
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
