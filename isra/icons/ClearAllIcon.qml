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
                path: root.filled ? "M200-200q-33 0-56.5-23.5T120-280v-360q-17 0-28.5-11.5T80-680q0-17 11.5-28.5T120-720h120v-20q0-17 11.5-28.5T280-780h80q17 0 28.5 11.5T400-740v20h120q17 0 28.5 11.5T560-680q0 17-11.5 28.5T520-640v360q0 33-23.5 56.5T440-200H200Zm440-40q-17 0-28.5-11.5T600-280q0-17 11.5-28.5T640-320h80q17 0 28.5 11.5T760-280q0 17-11.5 28.5T720-240h-80Zm0-160q-17 0-28.5-11.5T600-440q0-17 11.5-28.5T640-480h160q17 0 28.5 11.5T840-440q0 17-11.5 28.5T800-400H640Zm0-160q-17 0-28.5-11.5T600-600q0-17 11.5-28.5T640-640h200q17 0 28.5 11.5T880-600q0 17-11.5 28.5T840-560H640Z" : "M200-200q-33 0-56.5-23.5T120-280v-360q-17 0-28.5-11.5T80-680q0-17 11.5-28.5T120-720h120v-20q0-17 11.5-28.5T280-780h80q17 0 28.5 11.5T400-740v20h120q17 0 28.5 11.5T560-680q0 17-11.5 28.5T520-640v360q0 33-23.5 56.5T440-200H200Zm440-40q-17 0-28.5-11.5T600-280q0-17 11.5-28.5T640-320h80q17 0 28.5 11.5T760-280q0 17-11.5 28.5T720-240h-80Zm0-160q-17 0-28.5-11.5T600-440q0-17 11.5-28.5T640-480h160q17 0 28.5 11.5T840-440q0 17-11.5 28.5T800-400H640Zm0-160q-17 0-28.5-11.5T600-600q0-17 11.5-28.5T640-640h200q17 0 28.5 11.5T880-600q0 17-11.5 28.5T840-560H640Zm-440-80v360h240v-360H200Z"
            }
        }
    }
}

