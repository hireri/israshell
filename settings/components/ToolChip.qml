import QtQuick
import qs.style

Rectangle {
    id: root

    property string label: ""
    property bool active: false
    signal toggled(bool active)

    implicitHeight: 32
    implicitWidth: row.implicitWidth + 24
    radius: height / 2
    color: root.active ? Colors.md3.primary_container : "transparent"
    border.width: 1
    border.color: root.active ? "transparent" : Colors.md3.outline_variant

    Behavior on color { ColorAnimation { duration: 120 } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 7

        Rectangle {
            width: 7
            height: 7
            radius: 4
            anchors.verticalCenter: parent.verticalCenter
            color: root.active ? Colors.md3.primary : Colors.md3.outline_variant
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        Text {
            text: root.label
            font.family: Config.fontFamily
            font.pixelSize: 12
            font.weight: root.active ? Font.Medium : Font.Normal
            color: root.active ? Colors.md3.on_primary_container : Colors.md3.on_surface_variant
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.active = !root.active
            root.toggled(root.active)
        }
    }
}
