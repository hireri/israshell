import qs.icons

import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property color color: "white"
    property real iconSize: 24
    property bool filled: false
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
                path: "M160-120q-17 0-28.5-11.5T120-160q0-17 11.5-28.5T160-200h640q17 0 28.5 11.5T840-160q0 17-11.5 28.5T800-120H160Zm0-160q-17 0-28.5-11.5T120-320q0-17 11.5-28.5T160-360h400q17 0 28.5 11.5T600-320q0 17-11.5 28.5T560-280H160Zm0-160q-17 0-28.5-11.5T120-480q0-17 11.5-28.5T160-520h640q17 0 28.5 11.5T840-480q0 17-11.5 28.5T800-440H160Zm0-160q-17 0-28.5-11.5T120-640q0-17 11.5-28.5T160-680h400q17 0 28.5 11.5T600-640q0 17-11.5 28.5T560-600H160Zm0-160q-17 0-28.5-11.5T120-800q0-17 11.5-28.5T160-840h640q17 0 28.5 11.5T840-800q0 17-11.5 28.5T800-760H160Z"
            }
        }
    }
}
