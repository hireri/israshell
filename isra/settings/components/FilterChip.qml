import QtQuick
import qs.style

Rectangle {
    id: root

    property string label: ""
    property bool active: false
    signal toggled(bool active)

    implicitHeight: 32
    implicitWidth: label_text.implicitWidth + (mouseArea.pressed ? 28 : 22)
    radius: height / 2
    color: root.active ? Colors.md3.primary_container : Colors.md3.surface_container_high

    Behavior on color {
        ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    Text {
        id: label_text
        anchors.centerIn: parent
        text: root.label
        font.family: Config.fontFamily
        font.pixelSize: 12
        font.weight: root.active ? Font.Medium : Font.Normal
        color: root.active ? Colors.md3.on_primary_container : Colors.md3.on_surface_variant

        Behavior on color {
            ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.active = !root.active;
            root.toggled(root.active);
        }
    }

    Behavior on implicitWidth {
        NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
    }
}
