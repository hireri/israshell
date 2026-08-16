pragma Singleton
import QtQuick
import Quickshell
import qs.style

Singleton {
    id: root

    readonly property bool ready: !LocaleService.weatherLoading && LocaleService.weatherError === ""

    readonly property int code: root.ready ? LocaleService.weatherCode : -1
    readonly property bool isDay: LocaleService.weatherIsDay

    readonly property string temp: root.ready ? LocaleService.weatherTempValue + "°" : "—"
    readonly property string high: root.ready ? LocaleService.weatherHighValue + "°" : "—"
    readonly property string low: root.ready ? LocaleService.weatherLowValue + "°" : "—"
    readonly property string desc: LocaleService.weatherDesc

    readonly property string location: Config.cityName !== "" ? LocaleService.weatherLocation : Localization.t("weather.your_location")

    readonly property string source: Localization.t("weather.source")
}
