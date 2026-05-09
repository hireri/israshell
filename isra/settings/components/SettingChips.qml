import QtQuick
import qs.style

SettingRow {
    id: root

    property var options: []
    property var currentValue: null
    signal selected(var value)

    property bool isLast: false

    Row {
        spacing: 6
        anchors.verticalCenter: parent?.verticalCenter

        Repeater {
            model: root.options

            Rectangle {
                required property var modelData
                property bool active: root.currentValue === modelData.value

                height: 30
                width: chipLabel.implicitWidth + 24
                radius: height / 2
                color: active ? Colors.md3.primary : Colors.md3.surface_container_high

                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }

                Text {
                    id: chipLabel
                    anchors.centerIn: parent
                    text: modelData.label
                    font.family: Config.fontFamily
                    font.pixelSize: 12
                    font.weight: active ? Font.Medium : Font.Normal
                    color: active ? Colors.md3.on_primary : Colors.md3.on_surface_variant
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.currentValue = modelData.value;
                        root.selected(modelData.value);
                    }
                }
            }
        }
    }
}
