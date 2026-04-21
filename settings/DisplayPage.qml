import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.style
import qs.services
import qs.settings.components

PageBase {
    title: "Display"
    subtitle: "Night light and color temperature"

    Component.onCompleted: {
        console.log("[Display] page loaded — active:", NightLightService.active, "nightTemp:", Config.nightLight.nightTemp, "dayTemp:", Config.nightLight.dayTemp);
    }

    HeroCard {
        Layout.fillWidth: true
        title: "Night light"
        subtitle: NightLightService.active ? "Active · " + Config.nightLight.nightTemp + "K" : "Off · " + Config.nightLight.dayTemp + "K during day"
        iconBg: Colors.md3.tertiary_container
        cardColor: Colors.md3.surface_container
        checked: NightLightService.active
        onToggled: v => {
            console.log("[Display] toggle → active will become:", !NightLightService.active);
            NightLightService.toggle();
        }
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
                onMoved: v => {
                    console.log("[Display] nightTemp moved →", Math.round(v));
                    NightLightService.setNightTemp(Math.round(v));
                }
                Component.onCompleted: console.log("[Display] TempStrip night completed, value:", Config.nightLight.nightTemp)
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
                onMoved: v => {
                    console.log("[Display] dayTemp moved →", Math.round(v));
                    NightLightService.setDayTemp(Math.round(v));
                }
                Component.onCompleted: console.log("[Display] TempStrip day completed, value:", Config.nightLight.dayTemp)
            }
        }
    }

    SectionCard {
        label: "Schedule"
        Layout.fillWidth: true

        TimeInput {
            label: "Sunrise"
            sublabel: "Night light turns off"
            value: Config.nightLight.sunrise
            onCommitted: v => NightLightService.setSunrise(v)
        }
        TimeInput {
            label: "Sunset"
            sublabel: "Night light turns on"
            value: Config.nightLight.sunset
            onCommitted: v => NightLightService.setSunset(v)
        }
    }
}
