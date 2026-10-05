import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property string style: "capsule"
    property real   length: 0
    property real   thickness: 0
    property color  color

    readonly property bool dotted: root.style === "dot"
    readonly property bool tailed: root.style === "tail"
    readonly property real needleWidth: Math.max(1.5, root.thickness * 0.4)
    readonly property real tail: root.thickness * 2.5

    readonly property real overhang: root.dotted ? 0 : (root.tailed ? root.tail : root.thickness / 2)
    readonly property real reach: root.length + root.thickness / 2

    width:  root.thickness
    height: root.reach + root.overhang
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom:           parent.verticalCenter
    anchors.bottomMargin:     -root.overhang

    Rectangle {
        visible: root.style === "capsule"
        anchors.fill: parent
        radius: width / 2
        color: root.color
        antialiasing: true
    }

    Rectangle {
        visible: root.style === "hollow"
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.width: Math.max(1.5, root.thickness * 0.22)
        border.color: root.color
        antialiasing: true
    }

    Rectangle {
        visible: root.style === "needle" || root.tailed
        width: root.needleWidth
        height: parent.height
        anchors.horizontalCenter: parent.horizontalCenter
        radius: width / 2
        color: root.color
        antialiasing: true
    }

    Rectangle {
        visible: root.dotted
        width: root.thickness
        height: root.thickness
        radius: width / 2
        color: root.color
        antialiasing: true
    }

    Shape {
        id: taper
        visible: root.style === "tapered"
        width:  root.thickness
        height: root.height
        preferredRendererType: Shape.CurveRenderer

        readonly property real r0: root.thickness / 2
        readonly property real r1: Math.max(1, root.thickness * 0.15)
        readonly property real c0y: taper.height - taper.r0
        readonly property real c1y: taper.r1
        readonly property real alpha: Math.asin(Math.max(0, Math.min(1, (taper.r0 - taper.r1) / Math.max(1, taper.c0y - taper.c1y))))
        property bool ready: false
        Component.onCompleted: Qt.callLater(() => taper.ready = true)

        readonly property string svg: {
            if (!taper.ready || taper.height <= 0 || taper.width <= 0) return "";
            const cx = taper.width / 2, cos = Math.cos(taper.alpha), sin = Math.sin(taper.alpha);
            const p0r = (cx + taper.r0 * cos) + " " + (taper.c0y - taper.r0 * sin);
            const p0l = (cx - taper.r0 * cos) + " " + (taper.c0y - taper.r0 * sin);
            const p1r = (cx + taper.r1 * cos) + " " + (taper.c1y - taper.r1 * sin);
            const p1l = (cx - taper.r1 * cos) + " " + (taper.c1y - taper.r1 * sin);
            return "M " + p0r + " L " + p1r + " A " + taper.r1 + " " + taper.r1 + " 0 0 0 " + p1l
                 + " L " + p0l + " A " + taper.r0 + " " + taper.r0 + " 0 1 0 " + p0r + " Z";
        }

        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"
            strokeWidth: -1
            PathSvg { path: taper.svg }
        }
    }
}
