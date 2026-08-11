import QtQuick
import QtQuick.Layouts
import qs.style

SettingRow {
    id: root

    property string action: ""
    property var keys: []

    label: root.action
    implicitHeight: 48

    Row {
        spacing: 4
        Layout.alignment: Qt.AlignVCenter

        Repeater {
            model: root.keys

            Rectangle {
                required property string modelData
                height: 24
                width: keyText.implicitWidth + 16
                radius: 4
                color: (Config.dim(Colors.md3.surface_container_high))
                border.width: 1
                border.color: Colors.md3.surface_variant

                Text {
                    id: keyText
                    anchors.centerIn: parent
                    text: modelData
                    font.family: Config.fontMonospace
                    font.pixelSize: 11
                    color: Colors.md3.on_surface_variant
                }
            }
        }
    }
}
