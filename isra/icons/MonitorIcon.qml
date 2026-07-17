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
                path: root.filled ? "M160-240q-33 0-56.5-23.5T80-320v-440q0-33 23.5-56.5T160-840h640q33 0 56.5 23.5T880-760v440q0 33-23.5 56.5T800-240H680l28 28q6 6 9 13.5t3 15.5v23q0 17-11.5 28.5T680-120H280q-17 0-28.5-11.5T240-160v-23q0-8 3-15.5t9-13.5l28-28H160Z" : "M160-240q-33 0-56.5-23.5T80-320v-440q0-33 23.5-56.5T160-840h640q33 0 56.5 23.5T880-760v440q0 33-23.5 56.5T800-240H680l28 28q6 6 9 13.5t3 15.5v23q0 17-11.5 28.5T680-120H280q-17 0-28.5-11.5T240-160v-23q0-8 3-15.5t9-13.5l28-28H160Zm0-80h640v-440H160v440Zm0 0v-440 440Z"
            }
        }
    }
}
