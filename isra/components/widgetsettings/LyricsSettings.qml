import QtQuick
import qs.style
import qs.services
import qs.windows.components

Column {
    id: root

    required property string entryId
    readonly property var entryData: DesktopWidgetService.entryFor(root.entryId)?.data ?? ({})

    readonly property real preferredWidth: 300

    readonly property bool isFlex: (root.entryData.fontFamily || "Google Sans Flex") === "Google Sans Flex"

    spacing: 12

    function patch(changes) {
        DesktopWidgetService.updateEntryData(root.entryId, changes);
    }

    SectionCard {
        width: root.width
        compact: true

        SettingSwitch {
            label: Localization.t("widgetSettings.lyrics_show_card")
            sublabel: Localization.t("widgetSettings.lyrics_show_card_sub")
            checked: root.entryData.showCard ?? true
            onToggled: v => root.patch({ showCard: v })
        }

        SettingSwitch {
            label: Localization.t("widgetSettings.lyrics_show_track_info")
            checked: root.entryData.showTrackInfo ?? true
            onToggled: v => root.patch({ showTrackInfo: v })
        }

        SettingSlider {
            label: Localization.t("widgetSettings.lyrics_art_size")
            visible: root.entryData.showTrackInfo ?? true
            from: 0
            to: 64
            stepSize: 2
            value: root.entryData.artSize ?? 36
            onMoved: v => root.patch({ artSize: v })
        }

        SettingSlider {
            label: Localization.t("widgetSettings.lyrics_blur")
            sublabel: Localization.t("widgetSettings.lyrics_blur_sub")
            from: 0
            to: 24
            stepSize: 1
            value: root.entryData.idleBlur ?? 0
            onMoved: v => root.patch({ idleBlur: v })
        }

        SettingChips {
            label: Localization.t("clockPage.content_alignment")
            isLast: true
            options: [
                { value: "left", label: Localization.t("barPage.left") },
                { value: "center", label: Localization.t("backgroundPage.center") },
                { value: "right", label: Localization.t("barPage.right") }
            ]
            currentValue: root.entryData.align || "left"
            onSelected: v => root.patch({ align: v })
        }
    }

    SectionCard {
        width: root.width
        compact: true
        label: Localization.t("widgetSettings.lyrics_font")

        SettingSlider {
            label: Localization.t("widgetSettings.lyrics_size")
            from: 12
            to: 48
            stepSize: 1
            value: root.entryData.lyricSize ?? 20
            onMoved: v => root.patch({ lyricSize: v })
        }

        SettingSlider {
            label: Localization.t("widgetSettings.lyrics_idle_weight")
            visible: root.isFlex
            from: 100
            to: 1000
            stepSize: 10
            value: root.entryData.idleWeight ?? 380
            onMoved: v => root.patch({ idleWeight: v })
        }

        SettingSlider {
            label: Localization.t("widgetSettings.lyrics_active_weight")
            visible: root.isFlex
            from: 100
            to: 1000
            stepSize: 10
            value: root.entryData.activeWeight ?? 620
            onMoved: v => root.patch({ activeWeight: v })
        }

        SettingSlider {
            label: Localization.t("widgetSettings.lyrics_grad")
            sublabel: Localization.t("widgetSettings.lyrics_grad_sub")
            visible: root.isFlex
            from: 0
            to: 100
            stepSize: 1
            value: root.entryData.activeGrad ?? 70
            onMoved: v => root.patch({ activeGrad: v })
        }

        SettingSlider {
            label: Localization.t("clockPage.width")
            visible: root.isFlex
            from: 25
            to: 151
            stepSize: 1
            value: root.entryData.fontWidth ?? 100
            onMoved: v => root.patch({ fontWidth: v })
        }

        SettingSlider {
            label: Localization.t("clockPage.roundness")
            isLast: true
            visible: root.isFlex
            from: 0
            to: 100
            stepSize: 1
            value: root.entryData.fontRoundness ?? 0
            onMoved: v => root.patch({ fontRoundness: v })
        }
    }

    SectionCard {
        width: root.width
        compact: true
        label: Localization.t("widgetSettings.lyrics_motion")

        SettingSwitch {
            label: Localization.t("widgetSettings.lyrics_word_mode")
            sublabel: Localization.t("widgetSettings.lyrics_word_mode_sub")
            checked: root.entryData.wordMode ?? true
            onToggled: v => root.patch({ wordMode: v })
        }

        SettingSlider {
            label: Localization.t("widgetSettings.lyrics_line_duration")
            from: 120
            to: 1400
            stepSize: 10
            unit: "ms"
            value: root.entryData.lineDuration ?? 620
            onMoved: v => root.patch({ lineDuration: v })
        }

        SettingSlider {
            label: Localization.t("widgetSettings.lyrics_word_duration")
            visible: root.entryData.wordMode ?? true
            from: 40
            to: 900
            stepSize: 10
            unit: "ms"
            value: root.entryData.wordDuration ?? 260
            onMoved: v => root.patch({ wordDuration: v })
        }

        SettingSlider {
            label: Localization.t("widgetSettings.lyrics_lead_in")
            sublabel: Localization.t("widgetSettings.lyrics_lead_in_sub")
            visible: root.entryData.wordMode ?? true
            from: 0
            to: 400
            stepSize: 10
            unit: "ms"
            value: root.entryData.leadIn ?? 120
            onMoved: v => root.patch({ leadIn: v })
        }

        SettingSlider {
            label: Localization.t("widgetSettings.lyrics_active_scale")
            isLast: true
            from: 1
            to: 1.2
            stepSize: 0.01
            decimals: 2
            value: root.entryData.activeScale ?? 1.04
            onMoved: v => root.patch({ activeScale: v })
        }
    }
}
