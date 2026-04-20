import QtQuick
import QtQuick.Layouts
import qs.style
import qs.services
import qs.settings.components

PageBase {
    title: "Display"
    subtitle: "Night light and color temperature"

    HeroCard {
        Layout.fillWidth: true
        title: "Night light"
        subtitle: NightLightService.active ? "Active · " + Config.nightLight.temp + "K" : "Off · Day temp " + Config.nightLight.dayTemp + "K"
        iconBg: Colors.md3.primary_container
        cardColor: Colors.md3.surface_container
        checked: NightLightService.active
        onToggled: v => NightLightService.toggle()
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
                value: Config.nightLight.temp
                onMoved: v => NightLightService.setNightTemp(Math.round(v))
            }
        }

        SettingRow {
            isLast: true
            label: "Day"
            sublabel: "Applied when night light is off"

            TempStrip {
                from: 1000
                to: 10000
                stepSize: 100
                value: Config.nightLight.dayTemp
                onMoved: v => NightLightService.setDayTemp(Math.round(v))
            }
        }
    }
}
