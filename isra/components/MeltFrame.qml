import QtQuick

ShaderEffect {
    id: root

    property real innerX1: 0
    property real innerY1: 0
    property real innerX2: width
    property real innerY2: height
    property real innerRadiusTop: 0
    property real innerRadiusBottom: 0
    property var panels: []          // {x, y, width, height, edge, depth}, edge -1 = bar edge
    property int barEdge: 0          // 0 top, 1 bottom
    property real meltRadius: 18
    property real fillet: 26
    property color frameColor: "black"
    property color outlineColor: "transparent"

    readonly property int maxPanels: 6
    readonly property real _farCoord: -10000

    readonly property var _shapes: {
        const out = [];
        for (const m of panels) {
            const s = _shapeOf(m);
            if (s)
                out.push(s);
            if (out.length === maxPanels)
                break;
        }
        return out;
    }

    function _shapeOf(m) {
        const edge = m.edge >= 0 ? m.edge : barEdge;
        const along = edge < 2 ? m.width : m.height;
        const depth = m.depth >= 0 ? m.depth : (edge < 2 ? m.height : m.width);
        if (along <= 0.5 || depth <= 0.5)
            return null;
        const C = meltRadius;
        const e = 1.5;
        const L = innerX1 + e, R = innerX2 - e, T = innerY1 + e, B = innerY2 - e;
        let r, q;
        if (edge === 0) {
            r = [m.x, innerY1, m.x + m.width, Math.min(innerY2, innerY1 + depth)];
            q = [0, 0, r[2] >= R ? 0 : C, r[0] <= L ? 0 : C];
        } else if (edge === 1) {
            r = [m.x, Math.max(innerY1, innerY2 - depth), m.x + m.width, innerY2];
            q = [r[0] <= L ? 0 : C, r[2] >= R ? 0 : C, 0, 0];
        } else if (edge === 2) {
            r = [innerX1, m.y, Math.min(innerX2, innerX1 + depth), m.y + m.height];
            q = [0, r[1] <= T ? 0 : C, r[3] >= B ? 0 : C, 0];
        } else {
            r = [Math.max(innerX1, innerX2 - depth), m.y, innerX2, m.y + m.height];
            q = [r[1] <= T ? 0 : C, 0, 0, r[3] >= B ? 0 : C];
        }
        return { r: r, q: q };
    }

    function _slotRect(i) {
        const s = _shapes[i];
        return s ? Qt.vector4d(s.r[0], s.r[1], s.r[2], s.r[3]) : Qt.vector4d(_farCoord, _farCoord, _farCoord, _farCoord);
    }
    function _slotRadii(i) {
        const s = _shapes[i];
        return s ? Qt.vector4d(s.q[0], s.q[1], s.q[2], s.q[3]) : Qt.vector4d(0, 0, 0, 0);
    }

    readonly property vector2d winSize: Qt.vector2d(width, height)
    readonly property vector4d innerRect: Qt.vector4d(innerX1, innerY1, innerX2, innerY2)
    readonly property vector4d innerR: Qt.vector4d(innerRadiusTop, innerRadiusTop, innerRadiusBottom, innerRadiusBottom)
    readonly property vector4d p0: _slotRect(0)
    readonly property vector4d q0: _slotRadii(0)
    readonly property vector4d p1: _slotRect(1)
    readonly property vector4d q1: _slotRadii(1)
    readonly property vector4d p2: _slotRect(2)
    readonly property vector4d q2: _slotRadii(2)
    readonly property vector4d p3: _slotRect(3)
    readonly property vector4d q3: _slotRadii(3)
    readonly property vector4d p4: _slotRect(4)
    readonly property vector4d q4: _slotRadii(4)
    readonly property vector4d p5: _slotRect(5)
    readonly property vector4d q5: _slotRadii(5)

    vertexShader: Qt.resolvedUrl("../shaders/melt.vert.qsb")
    fragmentShader: Qt.resolvedUrl("../shaders/melt.frag.qsb")
}
