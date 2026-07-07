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

        TrackSlider {
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
