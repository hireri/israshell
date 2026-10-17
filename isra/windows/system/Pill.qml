import QtQuick
import qs.style
import qs.components

Rectangle {
    id: root

    property string text: ""
    property string tone: "neutral"
    property bool dot: true
    property string tooltip: ""
    property bool clickable: false

    signal clicked

    readonly property color _bg: root.tone === "bad" ? Colors.md3.error_container : root.tone === "warn" ? Colors.md3.tertiary_container : root.tone === "ok" ? Colors.md3.secondary_container : root.tone === "primary" ? Colors.md3.primary_container : Config.dim(Colors.md3.surface_container_high)
    readonly property color _fg: root.tone === "bad" ? Colors.md3.on_error_container : root.tone === "warn" ? Colors.md3.on_tertiary_container : root.tone === "ok" ? Colors.md3.on_secondary_container : root.tone === "primary" ? Colors.md3.on_primary_container : Colors.md3.on_surface_variant

    implicitHeight: 30
    implicitWidth: row.implicitWidth + 22
    radius: height / 2
    color: root._bg
    scale: root.clickable && area.pressed ? 0.94 : 1

    Behavior on color {
        ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    Behavior on scale {
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root._fg
        opacity: root.clickable && area.containsMouse ? 0.12 : 0
        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 7

        Rectangle {
            visible: root.dot
            anchors.verticalCenter: parent.verticalCenter
            width: 8
            height: 8
            radius: 4
            color: root._fg
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            font.family: Config.fontFamily
            font.pixelSize: 12
            color: root._fg
        }
    }

    Tooltip {
        text: root.tooltip
    }

    MouseArea {
        id: area
        anchors.fill: parent
        enabled: root.clickable
        hoverEnabled: true
        cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
