pragma ComponentBehavior: Bound
import QtQuick
import qs.style
import qs.services
import qs.windows.components

Column {
    id: root

    required property string entryId

    readonly property real preferredWidth: 300

    readonly property var breakTypeOptions: [
        { value: "short_break", label: Localization.t("pomodoro.short_break") },
        { value: "long_break", label: Localization.t("pomodoro.long_break") }
    ]

    spacing: 12

    function _updateStep(index, changes) {
        const steps = PomodoroService.steps.map((s, i) => i === index ? Object.assign({}, s, changes) : s);
        PomodoroService.setSteps(steps);
    }

    Repeater {
        model: PomodoroService.steps.length

        SectionCard {
            id: stepCard
            required property int index
            readonly property var step: PomodoroService.steps[index]

            width: root.width
            compact: true
            label: Localization.t("widgetSettings.step_n").replace("%1", stepCard.index + 1)

            SettingSlider {
                width: stepCard.width
                compact: true
                label: Localization.t("widgetSettings.focus_duration")
                from: 1
                to: 90
                stepSize: 1
                unit: Localization.t("widgetSettings.minutes_unit")
                value: stepCard.step.focusMinutes
                onMoved: v => root._updateStep(stepCard.index, { focusMinutes: Math.round(v) })
            }

            SettingChips {
                width: stepCard.width
                compact: true
                label: Localization.t("widgetSettings.break_type")
                options: root.breakTypeOptions
                currentValue: stepCard.step.breakType
                onSelected: v => root._updateStep(stepCard.index, { breakType: v })
            }

            SettingSlider {
                width: stepCard.width
                compact: true
                isLast: true
                label: Localization.t("widgetSettings.break_duration")
                from: 1
                to: 90
                stepSize: 1
                unit: Localization.t("widgetSettings.minutes_unit")
                value: stepCard.step.breakMinutes
                onMoved: v => root._updateStep(stepCard.index, { breakMinutes: Math.round(v) })
            }
        }
    }
}
