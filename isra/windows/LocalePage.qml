pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import qs.style
import qs.icons
import qs.services
import qs.windows.components

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
            label: "Show seconds"
            sublabel: "Display seconds in the bar clock"
            checked: Config.showSeconds
            onToggled: v => Config.update({
                    showSeconds: v
                })
        }

        SettingInput {
            label: "Custom time format"
            sublabel: "Overrides clock settings. Leave empty to restore dynamic defaults"
            value: Config.barTimeFormat
            placeholder: "hh:mm"
            onCommitted: v => Config.update({
                    barTimeFormat: v
                })
        }

        SettingSwitch {
            isLast: true
            label: "Show weather glance"
            sublabel: "Display weather icon and temp on the bar clock"
            checked: Config.showBarWeather
            onToggled: v => Config.update({
                    showBarWeather: v
                })
        }
    }

    SectionCard {
        label: "Date"
        Layout.fillWidth: true

        SettingSwitch {
            label: "Week starts on Monday"
            sublabel: "ISO week, Monday as first day"
            checked: Config.weekMonday
            onToggled: v => Config.update({
                    weekMonday: v
                })
        }

        SettingInput {
            isLast: true
            label: "Custom date format"
            sublabel: "Overrides settings. Leave empty to restore dynamic defaults"
            value: Config.barDateFormat
            placeholder: "ddd, dd/MM"
            onCommitted: v => Config.update({
                    barDateFormat: v
                })
        }
    }

    SectionCard {
        label: "Location"
        Layout.fillWidth: true

        SettingInput {
            isLast: true
            label: "City name"
            sublabel: "Leave empty to auto locate via IP address"
            value: Config.cityName
            placeholder: "e.g., Paris"
            onCommitted: v => Config.update({
                    cityName: v
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