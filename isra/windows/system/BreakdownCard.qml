pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.style
import "format.js" as Fmt

Rectangle {
    id: root

    property string title: ""
    property var items: []
    property color accent: Colors.md3.primary

    readonly property real peak: root.items.reduce((a, i) => Math.max(a, i.secs), 1)

    implicitHeight: col.implicitHeight + 36
    radius: 24
    color: Config.dim(Colors.md3.surface_container)

    ColumnLayout {
        id: col
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 18
        }
        spacing: 12

        Text {
            text: root.title
            font.family: Config.fontFamily
            font.pixelSize: 14
            font.weight: Font.Medium
            color: Colors.md3.on_surface
        }

        Repeater {
            model: root.items.slice(0, 5)

            ColumnLayout {
                id: row
                required property var modelData
                Layout.fillWidth: true
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        text: row.modelData.label
                        font.family: Config.fontFamily
                        font.pixelSize: 13
                        color: Colors.md3.on_surface_variant
                        elide: Text.ElideRight
                    }

                    Text {
                        text: Fmt.duration(row.modelData.secs)
                        font.family: Config.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: Colors.md3.on_surface
                    }
                }

                UsageBar {
                    Layout.fillWidth: true
                    implicitHeight: 6
                    value: row.modelData.secs / root.peak
                    fillColor: root.accent
                }
            }
        }
    }
}
