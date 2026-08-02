import QtQuick
import QtQuick.Layouts
import qs.style

Item {
    id: root

    property Component iconComponent: null
    property string label: ""
    property bool active: false
    property bool forceOff: false
    signal toggled
    signal rightClicked

    readonly property bool _on: active && !forceOff

    readonly property color bgColor: _on
        ? Colors.md3.primary
        : ((mouseArea.containsMouse && !forceOff)
            ? Qt.alpha(Colors.md3.surface_container_highest, Config.blurOpacity)
            : Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity))
    readonly property real bgRadius: _on ? 24 : 32

    anchors.fill: parent

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        anchors.leftMargin: 21
        spacing: 12

        Loader {
            id: iconLoader
            sourceComponent: root.iconComponent

            Binding {
                target: iconLoader.item
                property: "color"
                value: root._on ? Colors.md3.on_primary : Colors.md3.on_surface_variant
                when: iconLoader.status === Loader.Ready && iconLoader.item && iconLoader.item.hasOwnProperty("color")
            }
            Binding {
                target: iconLoader.item
                property: "filled"
                value: false
                when: root.forceOff && iconLoader.status === Loader.Ready && iconLoader.item && iconLoader.item.hasOwnProperty("filled")
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.label
            font.family: Config.fontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
            color: root._on ? Colors.md3.on_primary : Colors.md3.on_surface
            elide: Text.ElideRight
            renderType: Text.NativeRendering
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => mouse.button === Qt.RightButton ? root.rightClicked() : root.toggled()
    }
}
