import QtQuick
import QtQuick.Layouts
import qs.style

Rectangle {
    id: root

    property string name: ""
    property string sublabel: ""
    property string tone: "ok"
    property bool selected: false

    signal clicked

    readonly property color ink: root.tone === "bad" ? Colors.md3.on_error_container : root.tone === "ok" && root.selected ? Colors.md3.on_primary_container : root.selected ? Colors.md3.on_secondary_container : Colors.md3.on_surface

    implicitHeight: 64
    radius: root.selected ? 24 : 18
    color: root.tone === "bad" ? Colors.md3.error_container : root.selected ? (root.tone === "ok" ? Colors.md3.primary_container : Colors.md3.secondary_container) : Config.dim(area.containsMouse ? Colors.md3.surface_container_high : Colors.md3.surface_container)
    scale: area.pressed ? 0.97 : 1

    Behavior on color {
        ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    Behavior on radius {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    Behavior on scale {
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.ink
        opacity: area.containsMouse && (root.selected || root.tone === "bad") ? 0.08 : 0
        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 14
            rightMargin: 14
        }
        spacing: 12

        ShapeIcon {
            size: 36
            immediate: false
            shape: root.tone === "bad" ? "burst" : root.tone === "ok" ? "cookie6" : "circle"
            icon: root.tone === "bad" ? "error" : root.tone === "ok" ? "check" : "close"
            fill: root.tone === "bad" ? Colors.md3.error : root.tone === "ok" ? Colors.md3.primary : Colors.md3.surface_container_highest
            ink: root.tone === "bad" ? Colors.md3.on_error : root.tone === "ok" ? Colors.md3.on_primary : Colors.md3.on_surface_variant
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: root.name
                font.family: Config.fontFamily
                font.pixelSize: 13
                font.weight: Font.Medium
                color: root.ink
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.sublabel
                font.family: Config.fontFamily
                font.pixelSize: 11
                color: Qt.alpha(root.ink, 0.7)
                elide: Text.ElideRight
            }
        }
    }
}
