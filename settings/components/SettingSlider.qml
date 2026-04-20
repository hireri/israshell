import QtQuick
import QtQuick.Controls.Basic
import qs.style

SettingRow {
    id: root

    property real value: 0
    property real from: 0
    property real to: 100
    property real stepSize: 1
    property string unit: ""
    property int decimals: 0

    signal moved(real value)

    property bool isLast: false

    Row {
        spacing: 10
        anchors.verticalCenter: parent?.verticalCenter

        Slider {
            id: slider
            from: root.from
            to: root.to
            stepSize: root.stepSize
            value: root.value
            implicitWidth: 150
            anchors.verticalCenter: parent.verticalCenter

            onMoved: {
                root.value = slider.value
                root.moved(slider.value)
            }

            background: Rectangle {
                x: slider.leftPadding
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: slider.availableWidth
                height: 4
                radius: 2
                color: Colors.md3.surface_variant

                Rectangle {
                    width: slider.visualPosition * parent.width
                    height: parent.height
                    radius: 2
                    color: Colors.md3.primary
                }
            }

            handle: Rectangle {
                x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: 20
                height: 20
                radius: 10
                color: Colors.md3.primary
                border.width: 3
                border.color: Colors.md3.surface
            }
        }

        Text {
            text: root.decimals > 0
                ? root.value.toFixed(root.decimals) + root.unit
                : Math.round(root.value) + root.unit
            font.family: Config.fontMonospace
            font.pixelSize: 11
            color: Colors.md3.outline
            width: 42
            horizontalAlignment: Text.AlignRight
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
