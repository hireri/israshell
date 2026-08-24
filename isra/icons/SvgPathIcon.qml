import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property color color: "white"
    property real iconSize: 24
    property string path: ""

    width: iconSize
    height: iconSize
    layer.enabled: true
    layer.samples: 4

    Shape {
        width: parent.width
        height: parent.height
        antialiasing: true
        y: parent.height

        ShapePath {
            strokeWidth: 0
            fillColor: root.color
            scale: Qt.size(root.width / 960, root.height / 960)

            PathSvg {
                path: root.path
            }
        }
    }
}
