import QtQuick
import qs.style

Rectangle {
    id: root

    property string text: ""
    property string tone: "neutral"

    readonly property color _bg: root.tone === "bad" ? Colors.md3.error_container : root.tone === "warn" ? Colors.md3.tertiary_container : root.tone === "ok" ? Colors.md3.secondary_container : root.tone === "primary" ? Colors.md3.primary_container : Config.dim(Colors.md3.surface_container_highest)
    readonly property color _fg: root.tone === "bad" ? Colors.md3.on_error_container : root.tone === "warn" ? Colors.md3.on_tertiary_container : root.tone === "ok" ? Colors.md3.on_secondary_container : root.tone === "primary" ? Colors.md3.on_primary_container : Colors.md3.on_surface_variant

    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    implicitHeight: 22
    implicitWidth: label.implicitWidth + 18
    radius: height / 2
    color: root._bg
    visible: root.text !== ""

    Behavior on color {
        ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        font.family: Config.fontFamily
        font.pixelSize: 11
        font.weight: Font.Medium
        color: root._fg
    }
}
