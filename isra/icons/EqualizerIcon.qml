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
                path: "M183.5-183.5Q160-207 160-240v-160q0-33 23.5-56.5T240-480q33 0 56.5 23.5T320-400v160q0 33-23.5 56.5T240-160q-33 0-56.5-23.5ZM480-160q-33 0-56.5-23.5T400-240v-480q0-33 23.5-56.5T480-800q33 0 56.5 23.5T560-720v480q0 33-23.5 56.5T480-160Zm183.5-23.5Q640-207 640-240v-280q0-33 23.5-56.5T720-600q33 0 56.5 23.5T800-520v280q0 33-23.5 56.5T720-160q-33 0-56.5-23.5Z"
            }
        }
    }
}
