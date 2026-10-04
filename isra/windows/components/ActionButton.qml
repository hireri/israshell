import QtQuick
import qs.icons
import qs.style

Rectangle {
    id: root

    property string icon
    property string label

    signal clicked

    implicitHeight: 34
    implicitWidth: row.implicitWidth + 24
    radius: 12
    color: area.containsMouse ? Config.dim(Colors.md3.surface_container_highest) : Config.dim(Colors.md3.surface_container_high)

    Behavior on color {
        ColorAnimation {
            duration: 120
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.icon !== ""
            name: root.icon
            iconSize: 18
            color: Colors.md3.on_surface
            transitionType: "none"
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            font.family: Config.fontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
            color: Colors.md3.on_surface
            renderType: Text.NativeRendering
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
