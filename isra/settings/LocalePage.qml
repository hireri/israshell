pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import qs.style
import qs.icons
import qs.services
import qs.settings.components

PageBase {
    title: "Locale"
    subtitle: "Time, date and regional preferences"

    SectionCard {
        label: "Clock"
        Layout.fillWidth: true

        SettingChips {
            label: "Hour format"
            options: [
                {
                    label: "12h",
                    value: 1
                },
                {
                    label: "24h",
                    value: 0
                }
            ]
            currentValue: Config.hourFormat
            onSelected: v => Config.update({
                    hourFormat: v
                })
        }

        SettingSwitch {
            isLast: true
            label: "Show seconds"
            sublabel: "Display seconds in the bar clock"
            checked: Config.showSeconds
            onToggled: v => Config.update({
                    showSeconds: v
                })
        }
    }

    SectionCard {
        label: "Date"
        Layout.fillWidth: true

        SettingChips {
            label: "Date format"
            options: [
                {
                    label: "DD/MM/YYYY",
                    value: 0
                },
                {
                    label: "MM/DD/YYYY",
                    value: 1
                }
            ]
            currentValue: Config.dateFormat
            onSelected: v => Config.update({
                    dateFormat: v
                })
        }

        SettingSwitch {
            isLast: true
            label: "Week starts on Monday"
            sublabel: "ISO week, Monday as first day"
            checked: Config.weekMonday
            onToggled: v => Config.update({
                    weekMonday: v
                })
        }
    }

    SectionCard {
        label: "Units"
        Layout.fillWidth: true

        SettingSwitch {
            isLast: true
            label: "Fahrenheit"
            sublabel: "Use °F instead of °C for temperature"
            checked: Config.useFarenheit
            onToggled: v => Config.update({
                    useFarenheit: v
                })
        }
    }
}
