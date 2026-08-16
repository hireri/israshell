import QtQuick
import qs.style
import qs.services

DesktopWidgetShell {
    id: shell

    label: Localization.t("widgetDrawer.weather_card")
    sizeMode: "free"
    aspectLocked: false
    minSpan: ({ w: 3, h: 3 })
    maxSpan: ({ w: 9, h: 5 })
    frameCornerRadius: 24

    WeatherCardVisual {
        anchors.fill: parent
        screen: shell.hostScreen
    }
}
