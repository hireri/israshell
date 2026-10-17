import QtQuick
import QtQuick.Layouts
import qs.style

Rectangle {
    id: root

    property string label: ""
    property string icon: ""
    property string shape: "circle"
    property string value: ""
    property string sublabel: ""
    property string tone: "neutral"
    property bool clickable: true

    signal clicked

    default property alias viz: vizSlot.data

    readonly property bool tonal: root.tone !== "neutral"
    readonly property color ink: root.tone === "bad" ? Colors.md3.on_error_container : root.tone === "warn" ? Colors.md3.on_tertiary_container : root.tone === "primary" ? Colors.md3.on_primary_container : Colors.md3.on_surface
    readonly property color accent: root.tone === "bad" ? Colors.md3.error : root.tone === "warn" ? Colors.md3.tertiary : Colors.md3.primary
    readonly property color accentInk: root.tone === "bad" ? Colors.md3.on_error : root.tone === "warn" ? Colors.md3.on_tertiary : Colors.md3.on_primary

    radius: 20
    color: root.tone === "bad" ? Colors.md3.error_container : root.tone === "warn" ? Colors.md3.tertiary_container : root.tone === "primary" ? Colors.md3.primary_container : Config.dim(root.clickable && area.containsMouse ? Colors.md3.surface_container_high : Colors.md3.surface_container)
    scale: root.clickable && area.pressed ? 0.97 : 1

    Behavior on color {
        ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    Behavior on scale {
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.ink
        opacity: root.clickable && area.containsMouse && root.tonal ? 0.08 : 0
        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        enabled: root.clickable
        hoverEnabled: true
        cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: 14
        }
        spacing: 2

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ShapeIcon {
                size: 28
                shape: root.shape
                icon: root.icon
                fill: root.tonal ? root.accent : Colors.md3.primary_container
                ink: root.tonal ? root.accentInk : Colors.md3.on_primary_container
            }

            Text {
                Layout.fillWidth: true
                text: root.label
                font.family: Config.fontFamily
                font.pixelSize: 12
                font.weight: Font.Medium
                color: root.ink
                elide: Text.ElideRight
            }
        }

        Item {
            id: vizSlot
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        Text {
            Layout.fillWidth: true
            visible: root.value !== ""
            text: root.value
            font.family: Config.fontFamily
            font.pixelSize: 16
            font.weight: Font.Medium
            color: root.ink
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            visible: root.sublabel !== ""
            text: root.sublabel
            font.family: Config.fontFamily
            font.pixelSize: 11
            color: Qt.alpha(root.ink, 0.75)
            elide: Text.ElideRight
        }
    }
}
