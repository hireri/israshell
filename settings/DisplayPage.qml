import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.style
import qs.services
import qs.icons
import qs.settings.components

PageBase {
    title: "Display"
    subtitle: "Night light and color temperature"

    HeroCard {
        Layout.fillWidth: true
        title: "Night light"
        subtitle: NightLightService.active ? "Active · " + Config.nightLight.nightTemp + "K" : "Off · " + Config.nightLight.dayTemp + "K during day"
        iconBg: Colors.md3.tertiary_container
        cardColor: Colors.md3.surface_container
        checked: NightLightService.active
        onToggled: v => NightLightService.toggle()
        NightlightIcon {}
    }

    SectionCard {
        label: "Temperature"
        Layout.fillWidth: true

        SettingRow {
            label: "Night"
            sublabel: "Applied when night light is active"
            TempStrip {
                from: 1000
                to: 10000
                stepSize: 100
                value: Config.nightLight.nightTemp
                onMoved: v => NightLightService.setNightTemp(Math.round(v))
            }
        }

        SettingRow {
            isLast: true
            label: "Day"
            sublabel: "Applied during the day"
            TempStrip {
                from: 1000
                to: 10000
                stepSize: 100
                value: Config.nightLight.dayTemp
                onMoved: v => NightLightService.setDayTemp(Math.round(v))
            }
        }
    }

    SectionCard {
        label: "Schedule"
        Layout.fillWidth: true

        SettingSwitch {
            label: "Auto night light"
            sublabel: "Apply temperature on schedule"
            checked: Config.nightLight.scheduleEnabled
            onToggled: v => Config.update({
                    nightLight: Object.assign({}, Config.nightLight, {
                        scheduleEnabled: v
                    })
                })
        }

        SettingSwitch {
            label: "Auto dark mode"
            sublabel: "Switch theme at sunrise and sunset"
            checked: Config.nightLight.autoDarkMode
            onToggled: v => Config.update({
                    nightLight: Object.assign({}, Config.nightLight, {
                        autoDarkMode: v
                    })
                })
        }

        TimeInput {
            label: "Sunrise"
            sublabel: "Night light off · light mode"
            value: Config.nightLight.sunrise
            onCommitted: v => NightLightService.setSunrise(v)
        }

        TimeInput {
            label: "Sunset"
            sublabel: "Night light on · dark mode"
            value: Config.nightLight.sunset
            onCommitted: v => NightLightService.setSunset(v)
        }
    }
}
