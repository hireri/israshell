import QtQuick
import qs.style
import qs.icons

Item {
    id: root

    property bool checked: false
    property bool settled: false
    signal toggled(bool checked)

    implicitWidth: 52
    implicitHeight: 32

    opacity: root.enabled ? 1.0 : 0.38
    Behavior on opacity {
        enabled: root.settled
        NumberAnimation {
            duration: 150
        }
    }

    Component.onCompleted: Qt.callLater(() => settled = true)

    Component {
        id: checkIconComp
        CheckIcon {
            color: root.checked && root.enabled ? Colors.md3.primary : Colors.md3.outline
            iconSize: 18
        }
    }

    Component {
        id: crossIconComp
        CloseIcon {
            color: Colors.md3.surface_variant
            iconSize: 18
        }
    }

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked && root.enabled ? Colors.md3.primary : Colors.md3.surface_variant
        border.width: 2
        border.color: root.checked && root.enabled ? Colors.md3.primary : Colors.md3.outline

        Behavior on color {
            enabled: root.settled
            ColorAnimation {
                duration: 150
            }
        }
        Behavior on border.color {
            enabled: root.settled
            ColorAnimation {
                duration: 150
            }
        }

        Rectangle {
            id: thumb

            readonly property int margin: 4
            readonly property int baseSize: 24
            readonly property int stretchAmount: 8
            readonly property bool stretching: mouseArea.pressed && mouseArea.containsMouse

            readonly property real targetWidth: baseSize + (stretching ? stretchAmount : 0)
            readonly property real targetX: root.checked
                ? (track.width - targetWidth - margin)
                : margin

            height: baseSize
            radius: height / 2
            color: root.checked && root.enabled ? Colors.md3.on_primary : Colors.md3.outline
            anchors.verticalCenter: parent.verticalCenter

            width: baseSize
            x: margin

            Behavior on color {
                enabled: root.settled
                ColorAnimation {
                    duration: 150
                }
            }

            ParallelAnimation {
                id: moveAnim
                NumberAnimation {
                    target: thumb
                    property: "width"
                    to: thumb.targetWidth
                    duration: 200
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: thumb
                    property: "x"
                    to: thumb.targetX
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            function sync() {
                moveAnim.stop();
                moveAnim.start();
            }

            onTargetWidthChanged: {
                if (root.settled) sync();
                else width = targetWidth;
            }
            onTargetXChanged: {
                if (root.settled) sync();
                else x = targetX;
            }
            Component.onCompleted: {
                width = targetWidth;
                x = targetX;
            }

            Loader {
                id: checkLoader
                anchors.centerIn: parent
                sourceComponent: checkIconComp
                visible: opacity > 0.01
                opacity: root.checked ? (thumb.stretching ? 0.5 : 1) : 0
                scale: root.checked ? (thumb.stretching ? 0.7 : 1) : 0.7

                Behavior on opacity { enabled: root.settled; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on scale { enabled: root.settled; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            }

            Loader {
                id: crossLoader
                anchors.centerIn: parent
                sourceComponent: crossIconComp
                visible: opacity > 0.01
                opacity: root.checked ? 0 : (thumb.stretching ? 0.5 : 1)
                scale: root.checked ? 0.7 : (thumb.stretching ? 1 : 1)

                Behavior on opacity { enabled: root.settled; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on scale { enabled: root.settled; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (!root.enabled)
                return;
            root.toggled(!root.checked);
        }
    }
}
