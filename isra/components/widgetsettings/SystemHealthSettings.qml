import QtQuick
import qs.style
import qs.services
import qs.windows.components

Column {
    id: root

    required property string entryId
    readonly property var entryData: DesktopWidgetService.entryFor(root.entryId)?.data ?? ({})
    readonly property var areas: root.entryData.areas ?? ["packages", "storage", "system"]

    readonly property real preferredWidth: 300

    spacing: 12

    SectionCard {
        width: root.width
        compact: true

        SettingSwitch {
            label: Localization.t("widgetSettings.health_tinted")
            sublabel: Localization.t("widgetSettings.health_tinted_sub")
            checked: root.entryData.tinted ?? false
            onToggled: v => DesktopWidgetService.updateEntryData(root.entryId, { tinted: v })
        }

        SettingSwitch {
            label: Localization.t("widgetSettings.health_areas")
            checked: root.entryData.showAreas ?? true
            onToggled: v => DesktopWidgetService.updateEntryData(root.entryId, { showAreas: v })
        }

        SettingSwitch {
            label: Localization.t("widgetSettings.health_detail")
            enabled: root.entryData.showAreas ?? true
            checked: root.entryData.showDetail ?? true
            onToggled: v => DesktopWidgetService.updateEntryData(root.entryId, { showDetail: v })
        }
    }

    SectionCard {
        width: root.width
        compact: true
        label: Localization.t("widgetSettings.health_which")
        visible: root.entryData.showAreas ?? true

        Repeater {
            model: ["packages", "storage", "system"]

            SettingSwitch {
                id: row
                required property string modelData
                label: Localization.t("systemApp." + row.modelData)
                checked: root.areas.indexOf(row.modelData) >= 0
                onToggled: v => {
                    const keep = ["packages", "storage", "system"].filter(a => a === row.modelData ? v : root.areas.indexOf(a) >= 0);
                    DesktopWidgetService.updateEntryData(root.entryId, { areas: keep });
                }
            }
        }
    }
}
