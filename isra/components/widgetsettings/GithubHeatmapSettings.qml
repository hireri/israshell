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

        SettingInput {
            label: Localization.t("widgetSettings.github_username")
            fieldWidth: 120
            value: root.entryData.username ?? ""
            onCommitted: text => DesktopWidgetService.updateEntryData(root.entryId, { username: text })
        }
    }
}
