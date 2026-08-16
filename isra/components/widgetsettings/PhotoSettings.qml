import QtQuick
import qs.style
import qs.components
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
        label: Localization.t("widgetMenu.shape")

        ShapePicker {
            width: root.width
            currentShape: root.entryData.shape || "circle"
            onPicked: name => DesktopWidgetService.updateEntryData(root.entryId, { shape: name })
        }
    }
}
