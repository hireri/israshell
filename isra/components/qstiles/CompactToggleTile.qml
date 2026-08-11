import QtQuick
import qs.style

Item {
    id: root

    property Component iconComponent: null
    property bool active: false
    property bool forceOff: false
    property color accentColor: Colors.md3.primary
    property color onAccentColor: Colors.md3.on_primary
    signal toggled
    signal rightClicked

    readonly property bool _on: active && !forceOff

    readonly property color bgColor: _on
        ? root.accentColor
        : ((mouseArea.containsMouse && !forceOff)
            ? Qt.alpha(Colors.md3.surface_container_highest, Config.blurOpacity)
            : Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity))
    readonly property real bgRadius: _on ? 24 : 32

    anchors.fill: parent

    Loader {
        id: iconLoader
        anchors.centerIn: parent
        sourceComponent: root.iconComponent

        Binding {
            target: iconLoader.item
            property: "color"
            value: root._on ? root.onAccentColor : Colors.md3.on_surface_variant
            when: iconLoader.status === Loader.Ready && iconLoader.item && iconLoader.item.hasOwnProperty("color")
        }
        Binding {
            target: iconLoader.item
            property: "filled"
            value: false
            when: root.forceOff && iconLoader.status === Loader.Ready && iconLoader.item && iconLoader.item.hasOwnProperty("filled")
        }
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
