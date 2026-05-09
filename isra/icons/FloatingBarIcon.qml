import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property color color: "white"
    property real iconSize: 24

    width: iconSize
    height: iconSize

    layer.enabled: true
    layer.samples: 4

    Shape {
        width: parent.width
        height: parent.height
        y: parent.height

        antialiasing: true

        ShapePath {
            strokeWidth: 0
            fillColor: root.color
            scale: Qt.size(root.width / 960, root.height / 960)

            PathSvg {
                path: "M160-760q-17 0-28.5-11.5T120-800q0-17 11.5-28.5T160-840h640q17 0 28.5 11.5T840-800q0 17-11.5 28.5T800-760H160Zm600 80q33 0 56.5 23.5T840-600v400q0 33-23.5 56.5T760-120H200q-33 0-56.5-23.5T120-200v-400q0-33 23.5-56.5T200-680h560Zm0 80H200v400h560v-400Zm-560 0v400-400Z"
            }
        }
    }
}
