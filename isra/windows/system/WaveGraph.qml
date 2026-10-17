import QtQuick
import QtQuick.Shapes
import qs.style

Shape {
    id: root

    property var points: []
    property real scaleMax: 100
    property color color: Colors.md3.primary
    property real thickness: 3.5
    property int sampleCount: 40

    readonly property real _pad: root.thickness
    readonly property string _curve: {
        const pts = root.points || [];
        if (pts.length < 2 || root.width <= 0 || root.height <= 0)
            return "";
        const step = root.width / Math.max(1, root.sampleCount - 1);
        const usable = root.height - root._pad * 2;
        const p = pts.map((v, i) => ({
            x: root.width - (pts.length - 1 - i) * step,
            y: root._pad + usable - Math.max(0, Math.min(root.scaleMax, v)) / root.scaleMax * usable
        }));
        const lo = root._pad, hi = root.height - root._pad;
        const clampY = y => Math.max(lo, Math.min(hi, y));
        let d = "M " + p[0].x + " " + p[0].y;
        for (let i = 0; i < p.length - 1; i++) {
            const a = p[i - 1] ?? p[i], b = p[i], c = p[i + 1], e = p[i + 2] ?? c;
            d += " C " + (b.x + (c.x - a.x) / 6) + " " + clampY(b.y + (c.y - a.y) / 6) + " " + (c.x - (e.x - b.x) / 6) + " " + clampY(c.y - (e.y - b.y) / 6) + " " + c.x + " " + c.y;
        }
        return d;
    }

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeColor: "transparent"
        fillGradient: LinearGradient {
            x1: 0
            y1: 0
            x2: 0
            y2: root.height
            GradientStop { position: 0; color: Qt.alpha(root.color, 0.28) }
            GradientStop { position: 1; color: Qt.alpha(root.color, 0) }
        }
        PathSvg {
            path: root._curve === "" ? "" : root._curve + " L " + root.width + " " + root.height + " L " + (root.width - (root.points.length - 1) * (root.width / Math.max(1, root.sampleCount - 1))) + " " + root.height + " Z"
        }
    }

    ShapePath {
        strokeColor: root.color
        strokeWidth: root.thickness
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin
        fillColor: "transparent"
        PathSvg {
            path: root._curve
        }
    }
}
