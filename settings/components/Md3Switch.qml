import QtQuick
import qs.style

Item {
    id: root

    property bool checked: false
    signal toggled(bool checked)

    implicitWidth: 50
    implicitHeight: 30

    opacity: root.enabled ? 1.0 : 0.38
    Behavior on opacity {
        NumberAnimation {
            duration: 150
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
            ColorAnimation {
                duration: 150
            }
        }
        Behavior on border.color {
            ColorAnimation {
                duration: 150
            }
        }

        Rectangle {
            id: thumb
            width: 14
            height: 14
            scale: root.checked ? 1.5 : 1
            radius: height / 2
            color: root.checked && root.enabled ? Colors.md3.on_primary : Colors.md3.outline
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width - width - 8 : 8

            Behavior on scale {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on x {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (!root.enabled)
                return;
            root.toggled(!root.checked);
        }
    }
}
