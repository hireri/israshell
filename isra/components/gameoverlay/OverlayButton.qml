import QtQuick
import qs.components
import qs.icons
import qs.style
import "tokens.js" as T

Rectangle {
    id: root

    property string icon
    property string label
    property string tip
    property bool toggled: false
    property bool danger: false
    property bool filled: false
    property string iconTransition: "none"
    property int size: 36

    signal clicked
    signal rightClicked

    readonly property bool hovered: area.containsMouse

    implicitWidth: root.label !== "" ? row.implicitWidth + 24 : root.size
    implicitHeight: root.size
    radius: root.label !== "" ? T.radiusControl : height / 2

    readonly property color _base: root.danger ? Colors.md3.error_container : root.toggled ? Colors.md3.secondary_container : Colors.md3.surface_container_high
    readonly property color _fg: root.danger ? Colors.md3.on_error_container : root.toggled ? Colors.md3.on_secondary_container : Colors.md3.on_surface

    color: {
        if (!area.containsMouse)
            return root._base;
        return (root.danger || root.toggled) ? Qt.lighter(root._base, 1.1) : Colors.md3.surface_container_highest;
    }

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
            filled: root.filled || root.toggled
            iconSize: root.label !== "" ? 20 : Math.round(root.size * 0.55)
            color: root._fg
            transitionType: root.iconTransition
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.label !== ""
            text: root.label
            font.family: Config.fontFamily
            font.pixelSize: 14
            font.weight: Font.Medium
            color: root._fg
            renderType: Text.NativeRendering
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => mouse.button === Qt.RightButton ? root.rightClicked() : root.clicked()
    }

    Tooltip {
        anchorItem: root
        text: root.tip
        open: area.containsMouse && root.tip !== ""
    }
}
