import QtQuick
import qs.style
import qs.icons
import qs.services
import qs.windows.components

Column {
    id: root

    required property string entryId
    readonly property var entryData: DesktopWidgetService.entryFor(root.entryId)?.data ?? ({})

    readonly property real preferredWidth: 300

    spacing: 12

    SectionCard {
        width: root.width
        compact: true

        SettingChips {
            label: Localization.t("widgetSettings.metric")
            isLast: true
            options: [
                { value: "cpu", label: "", icon: cpuIcon },
                { value: "ram", label: "", icon: ramIcon },
                { value: "gpu", label: "", icon: gpuIcon },
                { value: "temp", label: "", icon: tempIcon },
                { value: "swap", label: "", icon: swapIcon }
            ]
            currentValue: root.entryData.metric ?? "cpu"
            onSelected: v => DesktopWidgetService.updateEntryData(root.entryId, { metric: v })
        }
    }

    Component {
        id: cpuIcon
        MaterialIcon {
            name: "memory"
            iconSize: 16
        }
    }
    Component {
        id: ramIcon
        MaterialIcon {
            name: "memory-alt"
            iconSize: 16
        }
    }
    Component {
        id: gpuIcon
        MaterialIcon {
            name: "videogame-asset"
            iconSize: 16
        }
    }
    Component {
        id: tempIcon
        MaterialIcon {
            name: "thermostat"
            iconSize: 16
        }
    }
    Component {
        id: swapIcon
        MaterialIcon {
            name: "swap-horiz"
            iconSize: 16
        }
    }
}
