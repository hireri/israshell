import QtQuick
import Quickshell.Widgets
import QtQuick.Controls.Basic
import qs.style

SettingRow {
    id: root

    property var options: []
    property var currentValue: null
    signal selected(var value)

    property bool isLast: false

    ComboBox {
        id: combo
        model: root.options.map(o => o.label)
        currentIndex: root.options.findIndex(o => o.value === root.currentValue)
        anchors.verticalCenter: parent?.verticalCenter
        implicitWidth: 140
        implicitHeight: 36

        onActivated: idx => {
            root.currentValue = root.options[idx].value;
            root.selected(root.options[idx].value);
        }

        contentItem: Text {
            leftPadding: 12
            text: combo.displayText
            font.family: Config.fontFamily
            font.pixelSize: 12
            color: Colors.md3.on_surface
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            radius: 8
            color: Colors.md3.surface_container_high
            border.width: 1
            border.color: combo.pressed ? Colors.md3.primary : Colors.md3.surface_variant
        }

        delegate: ItemDelegate {
            required property string modelData
            required property int index
            width: combo.width
            contentItem: Text {
                text: modelData
                font.family: Config.fontFamily
                font.pixelSize: 12
                color: Colors.md3.on_surface
                verticalAlignment: Text.AlignVCenter
                leftPadding: 12
            }
            background: Rectangle {
                color: hovered ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high
            }
        }

        popup: Popup {
            y: combo.height + 4
            width: combo.width
            padding: 0

            background: ClippingRectangle {
                color: Colors.md3.surface_container_high
                radius: 8
                border.width: 1
                border.color: Colors.md3.surface_variant
            }

            contentItem: ListView {
                implicitHeight: contentHeight
                model: combo.delegateModel
                clip: true
            }
        }

        indicator: Text {
            text: "⌄"
            font.pixelSize: 14
            color: Colors.md3.outline
            anchors {
                right: parent.right
                rightMargin: 10
                verticalCenter: parent.verticalCenter
            }
        }
    }
}
