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

    function _format(v) {
        return root.decimals > 0
            ? v.toFixed(root.decimals) + root.unit
            : Math.round(v) + root.unit
    }

    function _parseAndCommit(str) {
        let s = str.trim();
        if (root.unit.length > 0 && s.endsWith(root.unit))
            s = s.slice(0, s.length - root.unit.length).trim();

        const v = parseFloat(s);
        if (!isNaN(v)) {
            const clamped = Math.max(root.from, Math.min(root.to, v));
            root.value = clamped;
            root.moved(clamped);
        }
        valueField.text = root._format(root.value);
    }

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

        Rectangle {
            implicitWidth: 48
            implicitHeight: 28
            anchors.verticalCenter: parent.verticalCenter
            radius: 6
            color: valueField.activeFocus ? Colors.md3.surface_container_high : Qt.alpha(Colors.md3.surface_container_high, 0)

            Behavior on border.color {
                ColorAnimation {
                    duration: 120
                }
            }
            Behavior on color {
                ColorAnimation {
                    duration: 80
                }
            }

            TextInput {
                id: valueField
                anchors.fill: parent
                anchors.margins: 1
                text: root._format(root.value)
                font.family: Config.fontMonospace
                font.pixelSize: 11
                color: Colors.md3.on_surface
                horizontalAlignment: TextInput.AlignHCenter
                verticalAlignment: TextInput.AlignVCenter
                selectByMouse: true
                clip: true

                Keys.onReturnPressed: {
                    root._parseAndCommit(valueField.text);
                    focus = false;
                }
                Keys.onEscapePressed: {
                    text = root._format(root.value);
                    focus = false;
                }
                onActiveFocusChanged: {
                    if (!activeFocus)
                        root._parseAndCommit(valueField.text);
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.IBeamCursor
                onClicked: {
                    valueField.forceActiveFocus();
                    valueField.selectAll();
                }
            }
        }
    }

    onValueChanged: {
        if (!valueField.activeFocus)
            valueField.text = _format(value)
    }
}
