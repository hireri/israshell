import QtQuick
import qs.style
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

        SettingSwitch {
            label: Localization.t("widgetSettings.st_bar")
            checked: root.entryData.showBar ?? true
            onToggled: v => DesktopWidgetService.updateEntryData(root.entryId, { showBar: v })
        }

        SettingSwitch {
            label: Localization.t("widgetSettings.st_chart")
            sublabel: Localization.t("widgetSettings.st_chart_sub")
            checked: root.entryData.showChart ?? true
            onToggled: v => DesktopWidgetService.updateEntryData(root.entryId, { showChart: v })
        }

        SettingSwitch {
            label: Localization.t("widgetSettings.st_apps")
            checked: root.entryData.showApps ?? true
            onToggled: v => DesktopWidgetService.updateEntryData(root.entryId, { showApps: v })
        }

        SettingChips {
            label: Localization.t("widgetSettings.st_max_apps")
            isLast: true
            enabled: root.entryData.showApps ?? true
            options: [1, 2, 3, 4, 5].map(n => ({ value: n, label: String(n) }))
            currentValue: root.entryData.maxApps ?? 5
            onSelected: v => DesktopWidgetService.updateEntryData(root.entryId, { maxApps: v })
        }
    }
}
