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

        SettingChips {
            label: Localization.t("widgetSettings.sunmoon_mode")
            options: [
                { value: "both", label: Localization.t("sunmoon.both") },
                { value: "arc", label: Localization.t("sunmoon.sun") },
                { value: "moon", label: Localization.t("sunmoon.moon") }
            ]
            currentValue: root.entryData.mode ?? "both"
            onSelected: v => DesktopWidgetService.updateEntryData(root.entryId, { mode: v })
        }

        SettingSwitch {
            label: Localization.t("widgetSettings.show_illumination")
            isLast: true
            checked: root.entryData.showIllumination ?? true
            onToggled: v => DesktopWidgetService.updateEntryData(root.entryId, { showIllumination: v })
        }
    }
}
