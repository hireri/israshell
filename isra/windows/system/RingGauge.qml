import QtQuick
import QtQuick.Shapes
import qs.style

Item {
    id: root

    property real value: 0
    property color color: Colors.md3.primary
    property color trackColor: Config.dim(Colors.md3.surface_container_highest)
    property real thickness: 8
    property int cap: ShapePath.RoundCap
    property real start: -90
    property real sweep: 360
    property string text: ""

    property real shown: root.value

    implicitWidth: 76
    implicitHeight: 76

    Behavior on shown {
        NumberAnimation { duration: 450; easing.type: Easing.OutCubic }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.trackColor
            strokeWidth: root.thickness
            fillColor: "transparent"
            capStyle: root.cap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: (root.width - root.thickness) / 2
                radiusY: (root.height - root.thickness) / 2
                startAngle: root.start
                sweepAngle: root.sweep - 0.1
            }
        }

        ShapePath {
            strokeColor: root.color
            strokeWidth: root.thickness
            fillColor: "transparent"
            capStyle: root.cap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: (root.width - root.thickness) / 2
                radiusY: (root.height - root.thickness) / 2
                startAngle: root.start
                sweepAngle: Math.max(0.1, (root.sweep - 0.1) * Math.max(0, Math.min(1, root.shown || 0)))
            }
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.text
        font.family: Config.fontFamily
        font.pixelSize: 13
        font.weight: Font.Medium
        color: Colors.md3.on_surface
    }
}
