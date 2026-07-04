
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
                path: "M480-300q75 0 127.5-52.5T660-480q0-75-52.5-127.5T480-660q-75 0-127.5 52.5T300-480q0 75 52.5 127.5T480-300Zm-28.5-151.5Q440-463 440-480t11.5-28.5Q463-520 480-520t28.5 11.5Q520-497 520-480t-11.5 28.5Q497-440 480-440t-28.5-11.5ZM480-80q-83 0-156-31.5T197-197q-54-54-85.5-127T80-480q0-83 31.5-156T197-763q54-54 127-85.5T480-880q83 0 156 31.5T763-763q54 54 85.5 127T880-480q0 83-31.5 156T763-197q-54 54-127 85.5T480-80Z"
            }
        }
    }
}
