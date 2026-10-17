import QtQuick
import QtQuick.Layouts
import qs.style

Rectangle {
    id: root

    property string tone: "ok"
    property string shape: "cookie9"
    property string icon: ""
    property string image: ""
    property string title: ""
    property string sublabel: ""

    default property alias extra: extraRow.data
    property alias actions: actionRow.data

    readonly property color ink: root.tone === "bad" ? Colors.md3.on_error_container : root.tone === "warn" ? Colors.md3.on_tertiary_container : root.tone === "ok" ? Colors.md3.on_primary_container : Colors.md3.on_surface
    readonly property color fill: root.tone === "bad" ? Colors.md3.error : root.tone === "warn" ? Colors.md3.tertiary : Colors.md3.primary
    readonly property color fillInk: root.tone === "bad" ? Colors.md3.on_error : root.tone === "warn" ? Colors.md3.on_tertiary : Colors.md3.on_primary

    implicitHeight: 120
    radius: 22
    color: root.tone === "bad" ? Colors.md3.error_container : root.tone === "warn" ? Colors.md3.tertiary_container : root.tone === "ok" ? Colors.md3.primary_container : Config.dim(Colors.md3.surface_container_highest)

    Behavior on color {
        ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 22
            rightMargin: 22
        }
        spacing: 18

        ShapeIcon {
            Layout.alignment: Qt.AlignVCenter
            size: 72
            immediate: false
            shape: root.shape
            icon: root.icon
            image: root.image
            fill: root.fill
            ink: root.fillInk
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            Text {
                Layout.fillWidth: true
                text: root.title
                font.family: Config.fontFamily
                font.pixelSize: 24
                font.weight: Font.Medium
                color: root.ink
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.sublabel
                font.family: Config.fontFamily
                font.pixelSize: 13
                color: Qt.alpha(root.ink, 0.8)
                elide: Text.ElideRight
            }

            Flow {
                id: extraRow
                Layout.fillWidth: true
                Layout.topMargin: 2
                spacing: 6
                visible: children.length > 0
            }
        }

        Row {
            id: actionRow
            Layout.alignment: Qt.AlignVCenter
            spacing: 8
        }
    }
}
