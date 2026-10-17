import QtQuick
import QtQuick.Layouts
import qs.style

Rectangle {
    id: root

    property string shape: "cookie9"
    property string icon: ""
    property string value: ""
    property string label: ""
    property color fill: Colors.md3.secondary_container
    property color ink: Colors.md3.on_secondary_container

    implicitHeight: 84
    radius: 24
    color: Config.dim(Colors.md3.surface_container)

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 16
            rightMargin: 16
        }
        spacing: 14

        ShapeIcon {
            Layout.alignment: Qt.AlignVCenter
            size: 48
            shape: root.shape
            icon: root.icon
            fill: root.fill
            ink: root.ink
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: root.value
                font.family: Config.fontFamily
                font.pixelSize: 22
                font.weight: Font.Medium
                color: Colors.md3.on_surface
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.label
                font.family: Config.fontFamily
                font.pixelSize: 12
                color: Colors.md3.on_surface_variant
                elide: Text.ElideRight
            }
        }
    }
}
