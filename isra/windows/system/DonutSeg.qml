import QtQuick
import QtQuick.Shapes

ShapePath {
    id: s

    property real cx: 0
    property real cy: 0
    property real outer: 0
    property real inner: 0
    property real start: 0
    property real end: 0
    property real corner: 4
    property real gap: 2
    property color color: "white"

    readonly property bool full: s.end - s.start >= 359.9
    readonly property real ro: s.outer - s.corner
    readonly property real ri: s.inner + s.corner
    readonly property real off: s.corner + s.gap / 2
    readonly property real a0: s.start * Math.PI / 180
    readonly property real a1: s.end * Math.PI / 180
    readonly property real t0o: s.a0 + Math.asin(Math.min(1, s.off / s.ro))
    readonly property real t1o: s.a1 - Math.asin(Math.min(1, s.off / s.ro))
    readonly property real t0i: s.a0 + Math.asin(Math.min(1, s.off / s.ri))
    readonly property real t1i: s.a1 - Math.asin(Math.min(1, s.off / s.ri))
    readonly property bool empty: !s.full && s.t1o <= s.t0o

    function pt(rho: real, theta: real): string {
        return (s.cx + rho * Math.sin(theta)).toFixed(2) + " " + (s.cy - rho * Math.cos(theta)).toFixed(2);
    }

    readonly property string d: {
        if (s.full)
            return "M " + s.pt(s.outer, 0) + " A " + s.outer + " " + s.outer + " 0 1 1 " + s.pt(s.outer, Math.PI) + " A " + s.outer + " " + s.outer + " 0 1 1 " + s.pt(s.outer, 2 * Math.PI) + " Z M " + s.pt(s.inner, 0) + " A " + s.inner + " " + s.inner + " 0 1 0 " + s.pt(s.inner, -Math.PI) + " A " + s.inner + " " + s.inner + " 0 1 0 " + s.pt(s.inner, -2 * Math.PI) + " Z";
        if (s.empty)
            return "";
        return "M " + s.pt(s.ro, s.t0o) + " A " + s.ro + " " + s.ro + " 0 " + (s.t1o - s.t0o > Math.PI ? 1 : 0) + " 1 " + s.pt(s.ro, s.t1o) + " L " + s.pt(s.ri, s.t1i) + " A " + s.ri + " " + s.ri + " 0 " + (s.t1i - s.t0i > Math.PI ? 1 : 0) + " 0 " + s.pt(s.ri, s.t0i) + " Z";
    }

    fillColor: s.color
    strokeColor: s.full || s.empty ? "transparent" : s.color
    strokeWidth: s.full || s.empty ? 0 : s.corner * 2
    joinStyle: ShapePath.RoundJoin

    PathSvg {
        path: s.d
    }
}
