import QtQuick
import qs.icons
import qs.style

Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property string trailing: ""
    property bool filled: false
    property bool trailingFlipped: false
    property real size: 40
    property real iconSize: 20
    property real restRadius: height / 2
    property color container: Colors.md3.secondary_container
    property color content: Colors.md3.on_secondary_container

    signal clicked

    implicitHeight: size
    implicitWidth: label === "" ? size : row.implicitWidth + 32
    radius: restRadius
    color: enabled ? container : Qt.alpha(Colors.md3.on_surface, 0.12)
    readonly property color _content: enabled ? content : Qt.alpha(Colors.md3.on_surface, 0.38)

    Behavior on radius {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }
    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: root._content
        opacity: area.containsMouse ? 0.08 : 0
        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        x: (root.width - width) / 2
        spacing: 8

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.icon !== ""
            name: root.icon
            filled: root.filled
            iconSize: root.iconSize
            color: root._content
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.label !== ""
            text: root.label
            color: root._content
            font.pixelSize: 13
            font.weight: Font.Medium
        }
        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.trailing !== ""
            name: root.trailing
            iconSize: 16
            color: root._content
            rotation: root.trailingFlipped ? 180 : 0
            Behavior on rotation {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }
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
