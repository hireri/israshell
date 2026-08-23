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
            label: Localization.t("backgroundPage.tinted")
            sublabel: Localization.t("backgroundPage.match_colors_to_the_system")
            isLast: true
            checked: root.entryData.tinted ?? false
            onToggled: v => DesktopWidgetService.updateEntryData(root.entryId, { tinted: v })
        }
    }
}
