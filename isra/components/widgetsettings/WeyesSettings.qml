import QtQuick
import qs.style
import qs.services
import qs.windows.components

Column {
    id: root

    required property string entryId

    readonly property real preferredWidth: 300

    spacing: 12

    SectionCard {
        width: root.width
        compact: true

        SettingSwitch {
            label: Localization.t("backgroundPage.tinted")
            sublabel: Localization.t("backgroundPage.match_colors_to_the_system")
            isLast: true
            checked: Config.weyes.tinted ?? false
            onToggled: v => Config.update({ weyes: Object.assign({}, Config.weyes, { tinted: v }) })
        }
    }
}
