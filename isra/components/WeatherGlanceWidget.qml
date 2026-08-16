import QtQuick
import qs.style
import qs.services

DesktopWidgetShell {
    id: shell

    label: Localization.t("widgetDrawer.weather")
    sizeMode: "free"
    aspectLocked: false
    minSpan: ({ w: 2, h: 2 })
    maxSpan: ({ w: 6, h: 4 })
    frameCornerRadius: 20

    WeatherGlanceVisual {
        anchors.fill: parent
    }
}
