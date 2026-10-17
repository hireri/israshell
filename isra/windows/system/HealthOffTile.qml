import QtQuick
import qs.style
import qs.services
import qs.windows.components

Tile {
    visible: !HealthService.enabled
    label: Localization.t("systemApp.health")
    value: Localization.t("systemApp.hero_off")
    valueSize: 22
    sublabel: Localization.t("systemApp.health_off")

    actions: [
        ActionButton {
            primary: true
            label: Localization.t("systemApp.turn_on")
            onClicked: HealthService.setOption("enabled", true)
        }
    ]
}
