import QtQuick
import qs.components
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

        SettingSlider {
            label: Localization.t("widgetSettings.button_size")
            sublabel: Localization.t("widgetSettings.share_of_the_widget_the")
            isLast: true
            from: 0.1
            to: 0.5
            stepSize: 0.01
            decimals: 2
            value: root.entryData.buttonScale ?? 0.28
            onMoved: v => DesktopWidgetService.updateEntryData(root.entryId, { buttonScale: v })
        }
    }

    SectionCard {
        width: root.width
        compact: true
        label: Localization.t("widgetSettings.idle_shape")

        ShapePicker {
            width: root.width
            currentShape: root.entryData.shape || "circle"
            onPicked: name => DesktopWidgetService.updateEntryData(root.entryId, { shape: name })
        }
    }

    SectionCard {
        width: root.width
        compact: true
        label: Localization.t("widgetSettings.playing_shape")

        ShapePicker {
            width: root.width
            currentShape: root.entryData.playingShape || "cookie9"
            onPicked: name => DesktopWidgetService.updateEntryData(root.entryId, { playingShape: name })
        }
    }
}
