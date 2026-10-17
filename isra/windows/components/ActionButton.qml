import QtQuick
import qs.icons
import qs.style
import qs.components

Rectangle {
    id: root

    property string icon
    property string label
    property string tooltip: ""
    property bool danger: false
    property bool primary: false
    // "" | "ok" | "warn" | "bad": tints the button to a status instead of the neutral surface
    property string tone: ""

    readonly property color toneFill: root.tone === "bad" ? Colors.md3.error : root.tone === "warn" ? Colors.md3.tertiary : Colors.md3.primary
    readonly property color toneInk: root.tone === "bad" ? Colors.md3.on_error : root.tone === "warn" ? Colors.md3.on_tertiary : Colors.md3.on_primary
    readonly property color neutral: area.containsMouse ? Config.dim(Colors.md3.surface_container_highest) : Config.dim(Colors.md3.surface_container_high)

    signal clicked

    implicitHeight: 34
    implicitWidth: row.implicitWidth + 24
    radius: 12
    color: root.danger ? Colors.md3.error_container : root.primary ? root.toneFill : root.tone !== "" ? Qt.tint(root.neutral, Qt.alpha(root.toneFill, area.containsMouse ? 0.3 : 0.2)) : root.neutral
    opacity: root.enabled ? 1 : 0.38

    Behavior on color {
        ColorAnimation {
            duration: 120
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
        scale: area.pressed ? 0.92 : 1
        Behavior on scale {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.icon !== ""
            name: root.icon
            iconSize: 18
            color: root.danger ? Colors.md3.on_error_container : root.primary ? root.toneInk : root.tone !== "" ? root.toneFill : Colors.md3.on_surface
            transitionType: "none"
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.label !== ""
            text: root.label
            font.family: Config.fontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
            color: root.danger ? Colors.md3.on_error_container : root.primary ? root.toneInk : root.tone !== "" ? root.toneFill : Colors.md3.on_surface
            renderType: Text.NativeRendering
        }
    }

    Tooltip {
        text: root.tooltip
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
