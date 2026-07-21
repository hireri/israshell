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
            enabled: Config.timeFormat === ""
            opacity: Config.timeFormat === "" ? 1 : 0.6
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
            enabled: Config.timeFormat === ""
            opacity: Config.timeFormat === "" ? 1 : 0.6
            sublabel: "Display seconds in the bar clock"
            checked: Config.showSeconds
            onToggled: v => Config.update({
                    showSeconds: v
                })
        }

        SettingInput {
            label: "Custom time format"
            sublabel: "Overrides clock settings. Leave empty to restore dynamic defaults"
            value: Config.timeFormat
            placeholder: "hh:mm"
            onCommitted: v => Config.update({
                    timeFormat: v
                })
        }

        SettingSwitch {
            isLast: true
            label: "Show bar clock"
            sublabel: "Display the system time in the status bar"
            checked: Config.bar.showClock ?? true
            onToggled: v => Config.update({
                bar: Object.assign({}, Config.bar, {
                    showClock: v
                })
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

        SettingChips {
            label: "Date order"
            options: [
                {
                    label: "Day first",
                    value: 0
                },
                {
                    label: "Month first",
                    value: 1
                }
            ]
            currentValue: Config.dateOrder
            onSelected: v => Config.update({
                    dateOrder: v
                })
        }

        SettingInput {
            label: "Custom date format"
            sublabel: "Overrides date order. Leave empty to restore dynamic defaults"
            value: Config.dateFormat
            placeholder: "ddd, dd/MM"
            onCommitted: v => Config.update({
                    dateFormat: v
                })
        }

        SettingSwitch {
            isLast: true
            label: "Show bar date"
            sublabel: "Display the current date in the status bar"
            checked: Config.bar.showDate ?? true
            onToggled: v => Config.update({
                bar: Object.assign({}, Config.bar, {
                    showDate: v
                })
            })
        }
    }

    SectionCard {
        label: "Weather & Location"
        Layout.fillWidth: true

        SettingInput {
            label: "City name"
            sublabel: "Leave empty to auto locate via IP address"
            value: Config.cityName
            placeholder: "e.g., Paris"
            onCommitted: v => Config.update({
                    cityName: v
                })
        }

        SettingSwitch {
            label: "Show bar weather info"
            sublabel: "Display weather icon and current temp on the status bar"
            checked: Config.showBarWeather
            onToggled: v => Config.update({
                    showBarWeather: v
                })
        }

        SettingSwitch {
            isLast: true
            label: "Use Fahrenheit units"
            sublabel: "Use °F instead of °C for temperature metrics"
            checked: Config.useFarenheit
            onToggled: v => Config.update({
                    useFarenheit: v
                })
        }
    }
}