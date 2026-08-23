import QtQuick
import QtQuick.Shapes
import qs.style

Item {
    id: root

    property real illumination: 0.5
    property bool mirrored: false
    property color litColor: Colors.md3.tertiary
    property color darkColor: Qt.alpha(Colors.md3.on_surface, 0.14)

    readonly property real _r: Math.max(0.5, Math.min(root.width, root.height) / 2)
    readonly property real _illum: Math.max(0, Math.min(1, root.illumination))

    readonly property real _t: 1 - 2 * root._illum

    readonly property real _rx: Math.max(0.01, root._r * Math.abs(root._t))

    Rectangle {
        anchors.centerIn: parent
        width: root._r * 2
        height: root._r * 2
        radius: width / 2
        color: root.darkColor
        antialiasing: true
    }

    Shape {
        anchors.centerIn: parent
        width: root._r * 2
        height: root._r * 2

        visible: root._illum > 0.015

        preferredRendererType: Shape.CurveRenderer

        transform: Scale {
            xScale: root.mirrored ? -1 : 1
            origin.x: root._r
        }

        ShapePath {
            fillColor: root.litColor
            strokeWidth: 0
            strokeColor: "transparent"

            startX: root._r
            startY: 0

            PathArc {
                x: root._r
                y: root._r * 2
                radiusX: root._r
                radiusY: root._r
                direction: PathArc.Clockwise
            }

            PathArc {
                x: root._r
                y: 0
                radiusX: root._rx
                radiusY: root._r
                direction: root._t >= 0 ? PathArc.Counterclockwise : PathArc.Clockwise
            }
        }
    }
}
