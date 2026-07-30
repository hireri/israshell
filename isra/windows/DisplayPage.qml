pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.style
import qs.services
import qs.icons
import qs.windows.components
import qs.components
import Quickshell.Widgets

PageBase {
    title: "Visuals"
    subtitle: "Night light, blur"

    HeroCard {
        Layout.fillWidth: true
        title: "Night light"
        subtitle: NightLightService.active ? "Active · " + Config.nightLight.nightTemp + "K" : "Off · " + Config.nightLight.dayTemp + "K during day"
        iconBg: Colors.md3.tertiary_container
        cardColor: Colors.md3.surface_container
        checked: NightLightService.active
        onToggled: v => NightLightService.toggle()
        MaterialIcon { name: "nightlight" }
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

    SectionCard {
        label: "Blur & Transparency"
        Layout.fillWidth: true

        SettingSwitch {
            id: blurSwitch
            label: "Background blur"
            sublabel: "Apply blur effect to panels and menus"
            checked: Config.blurEffects
            onToggled: v => Config.update({
                    blurEffects: v
                })
            isLast: !blurSwitch.checked
        }

        SettingSlider {
            label: "Bar & Blur dimming"
            sublabel: "Overlay opacity of the blurred panels"
            from: 0.1
            to: 1.0
            stepSize: 0.05
            decimals: 2
            value: Config.blurOpacity
            onMoved: v => Config.update({
                    blurOpacity: v
                })
            isLast: true
        }
    }

}