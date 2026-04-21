import QtQuick
import qs.style

Rectangle {
    id: root

    property string label: ""
    property color dotColor: "transparent"
    property bool active: false
    signal clicked

    implicitHeight: 52
    implicitWidth: row.implicitWidth + 24
    radius: 12
    color: root.active ? Colors.md3.secondary_container : Colors.md3.surface_container_high

    Behavior on color {
        ColorAnimation {
            duration: 120
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: root.label
            font.family: Config.fontFamily
            font.pixelSize: 12
            font.weight: root.active ? Font.Medium : Font.Normal
            color: root.active ? Colors.md3.on_secondary_container : Colors.md3.on_surface_variant
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
