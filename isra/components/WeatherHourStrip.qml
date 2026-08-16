import QtQuick
import qs.style
import qs.services

Item {
    id: root

    property real slotWidth: 44

    readonly property var hours: LocaleService.weatherHourly ?? []
    readonly property int slots: Math.max(1, Math.min(root.hours.length, Math.floor(root.width / root.slotWidth)))

    Row {
        anchors.centerIn: parent
        spacing: 0

        Repeater {
            model: root.slots

            Column {
                required property int index
                readonly property var slot: root.hours[index] ?? null

                width: root.width / root.slots
                spacing: 3

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: parent.slot ? parent.slot.temp + "°" : "—"
                    font.family: Config.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: Colors.md3.on_surface_variant
                }

                WeatherIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    code: parent.slot?.code ?? 0
                    isDay: parent.slot?.isDay ?? true
                    iconSize: 28
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: parent.slot ? LocaleService.formatHour(parent.slot.time) : ""
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: Colors.md3.on_surface_variant
                }
            }
        }
    }
}
