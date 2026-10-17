import QtQuick
import QtQuick.Layouts
import qs.style

Rectangle {
    id: root

    property string title: ""
    property string subtitle: ""

    default property alias content: body.data
    property alias actions: actionRow.data

    implicitHeight: col.implicitHeight + 28
    radius: 18
    color: Config.dim(Colors.md3.surface_container)

    ColumnLayout {
        id: col
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: 16
            rightMargin: 16
            topMargin: 14
        }
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            visible: root.title !== "" || actionRow.children.length > 0
            spacing: 10

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    visible: root.title !== ""
                    text: root.title
                    font.family: Config.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: Colors.md3.on_surface
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.subtitle !== ""
                    text: root.subtitle
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    color: Colors.md3.outline
                    elide: Text.ElideRight
                }
            }

            Row {
                id: actionRow
                spacing: 8
            }
        }

        ColumnLayout {
            id: body
            Layout.fillWidth: true
            spacing: 0
        }
    }
}
