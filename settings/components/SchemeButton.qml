import QtQuick
import qs.style

Rectangle {
    id: root

    default property alias content: row.data

    property string label: ""
    property bool active: false
    signal clicked

    implicitHeight: 64
    implicitWidth: row.implicitWidth + 24
    radius: 12

    color: {
        if (root.active)
            return Colors.md3.primary;
        if (mouseArea.containsMouse)
            return Colors.md3.surface_container_highest;
        return Colors.md3.surface_container_high;
    }

    Behavior on color {
        ColorAnimation {
            duration: 120
        }
    }

    Rectangle {
        id: hoverOverlay
        anchors.fill: parent
        radius: parent.radius
        color: mouseArea.containsMouse ? (root.active ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.04)) : "transparent"
        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
        layoutDirection: Qt.RightToLeft
        rightPadding: 8

        Text {
            text: root.label
            font.family: Config.fontFamily
            font.pixelSize: 12
            font.weight: root.active ? Font.Medium : Font.Normal
            color: root.active ? Colors.md3.on_primary : (mouseArea.containsMouse ? Colors.md3.on_surface : Colors.md3.on_surface_variant)
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
