import QtQuick
import qs.style
import qs.services

DesktopWidgetShell {
    id: shell

    label: Localization.t("widgetDrawer.weather_scene")
    sizeMode: "free"
    aspectLocked: false
    minSpan: ({ w: 5, h: 2 })
    maxSpan: ({ w: 9, h: 4 })
    frameCornerRadius: 24

    WeatherSceneVisual {
        anchors.fill: parent
    }
}
