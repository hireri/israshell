import QtQuick
import QtQuick.Shapes
import qs.style

Item {
    id: root

    property real progress: 0
    property real strokeWidth: 4
    property color activeColor: Colors.md3.primary
    property color trackColor: Qt.alpha(Colors.md3.primary, 0.25)
    property bool wavy: false
    property real waveAmplitude: 1
    property int waveCount: 6
    property real phase: 0

    readonly property real _p: Math.max(0, Math.min(1, root.progress))
    readonly property real _radius: Math.max(1, (Math.min(width, height) - root.strokeWidth) / 2 - (root.wavy ? root.waveAmplitude : 0))
    readonly property var _wave: {
        const cx = root.width / 2;
        const cy = root.height / 2;
        const sweep = root._p * 2 * Math.PI;
        const n = Math.max(2, Math.ceil(root.waveCount * 10 * root._p));
        const pts = [];
        for (let i = 0; i <= n; i++) {
            const a = -Math.PI / 2 + sweep * i / n;
            const r = root._radius + root.waveAmplitude * Math.sin(root.waveCount * a - root.phase);
            pts.push(Qt.point(cx + r * Math.cos(a), cy + r * Math.sin(a)));
        }
        return pts;
    }

    NumberAnimation on phase {
        from: 0
        to: 2 * Math.PI
        duration: 1500
        loops: Animation.Infinite
        running: root.wavy && root.visible
    }

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
            strokeColor: root.wavy ? "transparent" : root.activeColor
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

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.wavy ? root.activeColor : "transparent"
            strokeWidth: root.strokeWidth
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathPolyline {
                path: root.wavy ? root._wave : [Qt.point(0, 0), Qt.point(0.1, 0)]
            }
        }
    }
}