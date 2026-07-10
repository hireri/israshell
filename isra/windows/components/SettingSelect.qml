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
            Behavior on border.color {
                ColorAnimation {
                    duration: 120
                }
            }
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
                Behavior on color {
                    ColorAnimation {
                        duration: 100
                    }
                }
            }
        }

        popup: Popup {
            y: combo.height + 4
            width: combo.width
            padding: 0

            enter: Transition {
                NumberAnimation {
                    property: "opacity"
                    from: 0.0
                    to: 1.0
                    duration: 150
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    property: "y"
                    from: combo.height
                    to: combo.height + 4
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
            exit: Transition {
                NumberAnimation {
                    property: "opacity"
                    from: 1.0
                    to: 0.0
                    duration: 100
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    property: "y"
                    from: combo.height + 4
                    to: combo.height
                    duration: 100
                    easing.type: Easing.InCubic
                }
            }

            background: Item {}

            contentItem: ClippingRectangle {
                implicitHeight: listView.contentHeight
                color: Colors.md3.surface_container_high
                radius: 8
                border.width: 1
                border.color: Colors.md3.surface_variant

                ListView {
                    id: listView
                    anchors.fill: parent
                    model: combo.delegateModel
                    clip: false
                }
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
