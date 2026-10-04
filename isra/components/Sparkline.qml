import QtQuick
import QtQuick.Shapes

Shape {
    id: root

    property var points: []
    property real scaleMax: 100
    property color lineColor: "white"
    property int sampleCount: 40
    property bool smoothScroll: false
    property int interval: 2000

    readonly property real sampleSpacing: root.width / Math.max(1, root.sampleCount - 1)
    readonly property color gridColor: Qt.alpha(root.lineColor, 0.15)
    readonly property real _pad: 2

    property real smoothOffset: 0
    property var _prevPoints: []
    property var extendedPoints: []

    NumberAnimation {
        id: glide
        target: root
        property: "smoothOffset"
        from: root.sampleSpacing
        to: 0
        duration: root.interval
        easing.type: Easing.Linear
    }

    onPointsChanged: {
        const pts = root.points || [];
        if (root.smoothScroll && pts.length > 1 && root._prevPoints.length > 0) {
            root.extendedPoints = [root._prevPoints[0]].concat(pts);
            glide.restart();
        } else {
            root.extendedPoints = pts;
        }
        root._prevPoints = pts;
    }

    onSmoothScrollChanged: root.extendedPoints = root.points || []

    readonly property var _linePoints: {
        const pts = root.extendedPoints || [];
        if (pts.length < 2 || root.width <= 0 || root.height <= 0)
            return [];
        const rightIdx = pts.length - 1;
        const offset = root.smoothScroll ? root.smoothOffset : 0;
        const usableH = root.height - root._pad * 2;
        const arr = [];
        for (let i = 0; i < pts.length; i++) {
            const x = root.width - (rightIdx - i) * root.sampleSpacing + offset;
            const clamped = Math.max(0, Math.min(root.scaleMax, pts[i]));
            const y = root._pad + usableH - (clamped / root.scaleMax) * usableH;
            arr.push(Qt.point(x, y));
        }
        return arr;
    }

    readonly property var _fillPoints: {
        const lp = root._linePoints;
        if (lp.length < 2)
            return [];
        const last = lp[lp.length - 1];
        const first = lp[0];
        return lp.concat([Qt.point(last.x, root.height), Qt.point(first.x, root.height)]);
    }

    readonly property var _gridPaths: {
        const w = root.width, h = root.height;
        if (w <= 0 || h <= 0)
            return [];
        const rows = 4, cols = 6;
        const rowHeight = h / rows, colWidth = w / cols;
        const lines = [];
        for (let g = 1; g < rows; g++) {
            const gy = Math.round(rowHeight * g) + 0.5;
            lines.push([Qt.point(0, gy), Qt.point(w, gy)]);
        }
        for (let c = 1; c < cols; c++) {
            const gx = Math.round(colWidth * c) + 0.5;
            lines.push([Qt.point(gx, 0), Qt.point(gx, h)]);
        }
        return lines;
    }

    ShapePath {
        strokeColor: root.gridColor
        strokeWidth: 1
        fillColor: "transparent"
        PathMultiline {
            paths: root._gridPaths
        }
    }

    ShapePath {
        strokeColor: "transparent"
        fillColor: Qt.alpha(root.lineColor, 0.18)
        PathPolyline {
            path: root._fillPoints
        }
    }

    ShapePath {
        strokeColor: root.lineColor
        strokeWidth: 1.5
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin
        fillColor: "transparent"
        PathPolyline {
            path: root._linePoints
        }
    }
}
