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
                path: "M447-207q-47-47-47-113t47-113q47-47 113-47 23 0 42.5 5.5T640-458v-302q0-17 11.5-28.5T680-800h160q17 0 28.5 11.5T880-760v40q0 17-11.5 28.5T840-680H720v360q0 66-47 113t-113 47q-66 0-113-47ZM200-493.5Q170-432 162-362q-2 17-13.5 29.5T120-320q-17 0-28.5-13T82-363q8-87 44.5-162.5T221-659q58-58 133.5-94.5T517-798q17-2 30 9.5t13 28.5q0 17-12.5 28.5T518-718q-70 8-131 37.5T278-603q-48 48-78 109.5Zm147 63Q329-397 323-359q-3 17-14.5 28T280-320q-17 0-28-12.5t-9-29.5q7-54 30.5-100.5T334-546q37-37 83.5-60.5T518-637q17-2 29.5 9t12.5 28q0 17-11 28.5T521-557q-38 6-71 23.5T391-490q-26 26-44 59.5Z"
            }
        }
    }
}
