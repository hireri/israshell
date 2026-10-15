import QtQuick
import qs.icons
import qs.style
import qs.components

Rectangle {
    id: root

    property string icon
    property string label
    property string tooltip: ""
    property bool danger: false

    signal clicked

    implicitHeight: 34
    implicitWidth: row.implicitWidth + 24
    radius: 12
    color: root.danger ? Colors.md3.error_container : (area.containsMouse ? Config.dim(Colors.md3.surface_container_highest) : Config.dim(Colors.md3.surface_container_high))
    opacity: root.enabled ? 1 : 0.38

    Behavior on color {
        ColorAnimation {
            duration: 120
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
        scale: area.pressed ? 0.92 : 1
        Behavior on scale {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.icon !== ""
            name: root.icon
            iconSize: 18
            color: root.danger ? Colors.md3.on_error_container : Colors.md3.on_surface
            transitionType: "none"
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            font.family: Config.fontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
            color: root.danger ? Colors.md3.on_error_container : Colors.md3.on_surface
            renderType: Text.NativeRendering
        }
    }

    Tooltip {
        text: root.tooltip
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
