import QtQuick
import QtQuick.Layouts
import qs.style

Rectangle {
    id: root

    property alias checkId: info.checkId
    property string value: ""
    property string sublabel: ""
    property string icon: ""

    default property alias actions: actionRow.data

    readonly property color ink: info.tone === "bad" ? Colors.md3.on_error_container : info.tone === "warn" ? Colors.md3.on_tertiary_container : Colors.md3.on_surface

    CheckInfo {
        id: info
    }

    implicitHeight: 92
    radius: 24
    color: info.tone === "bad" ? Colors.md3.error_container : info.tone === "warn" ? Colors.md3.tertiary_container : Config.dim(Colors.md3.surface_container)

    Behavior on color {
        ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 18
            rightMargin: 16
        }
        spacing: 14

        ShapeIcon {
            Layout.alignment: Qt.AlignVCenter
            size: 46
            shape: info.tone === "bad" ? "burst" : info.tone === "warn" ? "softBurst" : "cookie6"
            icon: root.icon
            fill: info.tone === "bad" ? Colors.md3.error : info.tone === "warn" ? Colors.md3.tertiary : Colors.md3.primary_container
            ink: info.tone === "bad" ? Colors.md3.on_error : info.tone === "warn" ? Colors.md3.on_tertiary : Colors.md3.on_primary_container
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: info.label
                font.family: Config.fontFamily
                font.pixelSize: 12
                color: root.ink
                opacity: 0.8
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.value
                font.family: Config.fontFamily
                font.pixelSize: 22
                font.weight: Font.Medium
                color: root.ink
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.sublabel
                font.family: Config.fontFamily
                font.pixelSize: 11
                color: root.ink
                opacity: 0.7
                elide: Text.ElideRight
            }
        }

        Row {
            id: actionRow
            Layout.alignment: Qt.AlignVCenter
            spacing: 8
        }
    }
}
