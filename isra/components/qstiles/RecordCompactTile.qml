import QtQuick
import qs.style
import qs.icons

Item {
    id: root

    property bool active: false
    property bool forceOff: false
    signal toggled
    signal rightClicked

    readonly property bool _on: active && !forceOff

    readonly property color bgColor: _on
        ? Colors.md3.error
        : ((mouseArea.containsMouse && !forceOff)
            ? Qt.alpha(Colors.md3.surface_container_highest, Config.blurOpacity)
            : Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity))
    readonly property real bgRadius: _on ? 24 : 32

    anchors.fill: parent

    MaterialIcon {
        anchors.centerIn: parent
        name: "record"
        iconSize: 22
        transitionType: "none"
        color: root._on ? Colors.md3.on_error : Colors.md3.on_surface_variant
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        onClicked: mouse => mouse.button === Qt.RightButton ? root.rightClicked() : root.toggled()
    }
}
