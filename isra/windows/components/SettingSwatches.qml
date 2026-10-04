import QtQuick
import qs.icons
import qs.style

SettingRow {
    id: root

    property var swatches: []
    property bool custom: false
    property int current: 0

    signal picked(int index)

    settingType: "swatches"
    applySignal: "picked"

    Row {
        spacing: 8

        Repeater {
            model: root.swatches.concat(root.custom ? ["custom"] : [])

            delegate: Rectangle {
                id: swatch
                required property string modelData
                required property int index

                readonly property bool isCustom: modelData === "custom"
                readonly property bool selected: root.current === index

                width: 26
                height: 26
                radius: 13
                color: isCustom ? Colors.md3.surface_container_high : "#" + modelData
                border.width: selected ? 2 : 1
                border.color: selected ? Colors.md3.primary : Colors.md3.outline_variant

                MaterialIcon {
                    visible: swatch.isCustom
                    anchors.centerIn: parent
                    name: "palette"
                    iconSize: 14
                    color: Colors.md3.on_surface_variant
                    transitionType: "none"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(swatch.index)
                }
            }
        }
    }
}
