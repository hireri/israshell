import QtQuick
import QtQuick.Shapes
import qs.style

Item {
    id: root

    property real progress: 0
    property real strokeWidth: 4
    property color activeColor: Colors.md3.primary
    property color trackColor: Qt.alpha(Colors.md3.primary, 0.25)

    readonly property real _p: Math.max(0, Math.min(1, root.progress))
    readonly property real _radius: Math.max(1, (Math.min(width, height) - root.strokeWidth) / 2)

    Rectangle {
        anchors.centerIn: parent
        width: root._radius * 2 + root.strokeWidth
        height: width
        radius: width / 2
        color: "transparent"
        border.color: root.trackColor
        border.width: root.strokeWidth
    }

    Shape {
        anchors.fill: parent
        visible: root._p > 0.001
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.activeColor
            strokeWidth: root.strokeWidth
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root._radius
                radiusY: root._radius
                startAngle: 270
                sweepAngle: root._p * 360
            }
        }
    }
}