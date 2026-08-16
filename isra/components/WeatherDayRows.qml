import QtQuick
import qs.style
import qs.services

Item {
    id: root

    property real rowHeight: 30

    readonly property var days: (LocaleService.weatherDaily ?? []).slice(1)
    readonly property int rows: Math.max(0, Math.min(root.days.length, Math.floor(root.height / root.rowHeight)))

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Qt.alpha(Colors.md3.secondary_container, 0.45)
    }

    Column {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14

        Repeater {
            model: root.rows

            Item {
                required property int index
                readonly property var day: root.days[index] ?? null

                width: parent.width
                height: root.rowHeight

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: LocaleService.formatWeekday(parent.day?.date)
                    font.family: Config.fontFamily
                    font.pixelSize: 15
                    font.weight: Font.Medium
                    color: Colors.md3.primary
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    WeatherIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        code: parent.parent.day?.code ?? 0
                        isDay: true
                        iconSize: 22
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: (parent.parent.day?.high ?? 0) + "°"
                        font.family: Config.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: Colors.md3.primary
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: (parent.parent.day?.low ?? 0) + "°"
                        font.family: Config.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: Colors.md3.on_surface_variant
                    }
                }
            }
        }
    }
}
