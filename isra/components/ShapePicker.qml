import QtQuick
import qs.style
import qs.icons

Item {
    id: root

    property string currentShape: "circle"
    signal picked(string shape)

    readonly property real gap: 4
    readonly property real pad: 8
    readonly property real minCell: 34

    readonly property int cols: Math.max(1, Math.floor((root.width - root.pad * 2 + root.gap) / (root.minCell + root.gap)))
    readonly property real cell: Math.max(root.minCell, (root.width - root.pad * 2 - (root.cols - 1) * root.gap) / root.cols)
    readonly property real swatch: Math.min(26, root.cell * 0.7)

    implicitWidth: root.minCell * 7 + root.gap * 6 + root.pad * 2
    implicitHeight: shapeGrid.implicitHeight + root.pad * 2

    MaterialShape {
        id: catalogProbe
        visible: false
        width: 0
        height: 0
    }

    Grid {
        id: shapeGrid
        x: root.pad
        y: root.pad
        columns: root.cols
        spacing: root.gap

        Repeater {
            model: catalogProbe.catalogNames

            Rectangle {
                id: swatchCell
                required property string modelData
                readonly property bool isCurrent: swatchCell.modelData === root.currentShape

                width: root.cell
                height: root.cell
                radius: root.cell * 0.28
                color: "transparent"

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: Colors.md3.primary_container
                    opacity: swatchCell.isCurrent ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 100 }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: Colors.md3.on_surface
                    opacity: (!swatchCell.isCurrent && swatchMouse.containsMouse) ? 0.08 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 100 }
                    }
                }

                MaterialShape {
                    anchors.centerIn: parent
                    name: swatchCell.modelData
                    shapeSize: root.swatch
                    color: swatchCell.isCurrent ? Colors.md3.on_primary_container : Colors.md3.on_surface_variant
                }

                MouseArea {
                    id: swatchMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(swatchCell.modelData)
                }
            }
        }
    }
}
