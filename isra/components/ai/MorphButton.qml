import QtQuick
import qs.icons
import qs.style

Rectangle {
    id: root

    property string icon: ""
    property bool filled: false
    property real size: 40
    property real iconSize: 20
    property real restRadius: root.size / 2
    property real pressedRadius: root.restRadius
    property color container: Colors.md3.secondary_container
    property color content: Colors.md3.on_secondary_container
    readonly property bool hovered: area.containsMouse

    signal clicked

    implicitWidth: root.size
    implicitHeight: root.size
    radius: area.pressed ? root.pressedRadius : root.restRadius
    color: root.container

    Behavior on radius {
        NumberAnimation {
            duration: 120
            easing.type: Easing.OutCubic
        }
    }
    Behavior on color {
        ColorAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: root.content
        opacity: area.pressed ? 0.10 : (area.containsMouse ? 0.08 : 0)

        Behavior on opacity {
            NumberAnimation {
                duration: 100
                easing.type: Easing.OutCubic
            }
        }
    }

    MaterialIcon {
        anchors.centerIn: parent
        name: root.icon
        filled: root.filled
        iconSize: root.iconSize
        transitionType: "none"
        color: root.content
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
