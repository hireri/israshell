pragma ComponentBehavior: Bound
import QtQuick
import qs.style
import qs.icons

Grid {
    id: root

    readonly property var keys: ["uvi", "humidity", "aqi", "feelsLike", "rain", "astro"]

    property var iconFor: null
    property var iconColorFor: null
    property var textFor: null

    property real cellHeight: 26
    property real fontSize: 12
    property real cornerSmall: 4
    property real cornerLarge: 12
    property int colorDuration: 0

    columns: 3
    spacing: 4

    readonly property real cellWidth: (width - spacing * 2) / 3

    Repeater {
        model: root.keys

        delegate: Rectangle {
            required property string modelData
            required property int index

            width: root.cellWidth
            height: root.cellHeight
            color: Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)
            radius: root.cornerSmall

            topLeftRadius: index === 0 ? root.cornerLarge : radius
            topRightRadius: index === 2 ? root.cornerLarge : radius
            bottomLeftRadius: index === 3 ? root.cornerLarge : radius
            bottomRightRadius: index === 5 ? root.cornerLarge : radius

            Row {
                anchors.centerIn: parent
                spacing: 6

                MaterialIcon {
                    name: root.iconFor(modelData)
                    iconSize: 14
                    color: root.iconColorFor(modelData)
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on color {
                        enabled: root.colorDuration > 0
                        ColorAnimation {
                            duration: root.colorDuration
                        }
                    }
                }

                Text {
                    text: root.textFor(modelData)
                    color: Colors.md3.on_surface_variant
                    font.family: Config.fontFamily
                    font.pixelSize: root.fontSize
                    font.weight: Font.Medium
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on color {
                        enabled: root.colorDuration > 0
                        ColorAnimation {
                            duration: root.colorDuration
                        }
                    }
                }
            }
        }
    }
}
