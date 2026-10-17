pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.style

Rectangle {
    id: root

    property var sources: []

    radius: 22
    color: Config.dim(Colors.md3.surface_container)

    ColumnLayout {
        anchors {
            fill: parent
            leftMargin: 16
            rightMargin: 18
            topMargin: 10
            bottomMargin: 10
        }
        spacing: 4

        Repeater {
            model: root.sources

            RowLayout {
                id: src
                required property var modelData

                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12
                opacity: src.modelData.n > 0 ? 1 : 0.5

                Item {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34

                    ShapeIcon {
                        anchors.centerIn: parent
                        size: 34
                        shape: src.modelData.shape
                        fill: src.modelData.n > 0 ? Colors.md3.primary : Config.dim(Colors.md3.surface_container_highest)
                    }

                    Text {
                        anchors.centerIn: parent
                        text: String(src.modelData.n)
                        font.family: Config.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: src.modelData.n > 0 ? Colors.md3.on_primary : Colors.md3.on_surface_variant
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: src.modelData.name
                    font.family: Config.fontFamily
                    font.pixelSize: 14
                    color: Colors.md3.on_surface
                    elide: Text.ElideRight
                }
            }
        }
    }
}
