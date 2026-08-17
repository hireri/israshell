import QtQuick
import QtQuick.Shapes

import "../components/shapes/material-shapes.js" as MaterialShapes
import "../components/shapes/shapes/morph.js" as Morph

Item {
    id: root

    property string name: ""
    property var shapes: []
    property bool random: false
    property int cycleInterval: 0
    property real shapeSize: 24
    property real rotationDegrees: 0
    property color color: "white"
    property bool outlined: false
    property color strokeColor: "white"
    property real strokeWidth: 2

    implicitWidth: shapeSize
    implicitHeight: shapeSize
    width: shapeSize
    height: shapeSize
    rotation: root.rotationDegrees

    Behavior on rotation {
        id: rotationBehavior
        NumberAnimation {
            duration: 350
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.42, 1.67, 0.21, 0.90, 1, 1]
        }
    }

    property alias rotationAnimates: rotationBehavior.enabled

    readonly property var _catalog: ({
        circle: MaterialShapes.getCircle,
        square: MaterialShapes.getSquare,
        slanted: MaterialShapes.getSlanted,
        arch: MaterialShapes.getArch,
        fan: MaterialShapes.getFan,
        arrow: MaterialShapes.getArrow,
        semiCircle: MaterialShapes.getSemiCircle,
        oval: MaterialShapes.getOval,
        pill: MaterialShapes.getPill,
        triangle: MaterialShapes.getTriangle,
        diamond: MaterialShapes.getDiamond,
        clamShell: MaterialShapes.getClamShell,
        pentagon: MaterialShapes.getPentagon,
        gem: MaterialShapes.getGem,
        sunny: MaterialShapes.getSunny,
        verySunny: MaterialShapes.getVerySunny,
        cookie4: MaterialShapes.getCookie4Sided,
        cookie6: MaterialShapes.getCookie6Sided,
        cookie7: MaterialShapes.getCookie7Sided,
        cookie9: MaterialShapes.getCookie9Sided,
        cookie12: MaterialShapes.getCookie12Sided,
        ghostish: MaterialShapes.getGhostish,
        clover4: MaterialShapes.getClover4Leaf,
        clover8: MaterialShapes.getClover8Leaf,
        burst: MaterialShapes.getBurst,
        softBurst: MaterialShapes.getSoftBurst,
        boom: MaterialShapes.getBoom,
        softBoom: MaterialShapes.getSoftBoom,
        flower: MaterialShapes.getFlower,
        puffy: MaterialShapes.getPuffy,
        puffyDiamond: MaterialShapes.getPuffyDiamond,
        pixelCircle: MaterialShapes.getPixelCircle,
        pixelTriangle: MaterialShapes.getPixelTriangle,
        bun: MaterialShapes.getBun,
        heart: MaterialShapes.getHeart
    })

    readonly property var catalogNames: Object.keys(root._catalog)
    readonly property var _symmetrySteps: ({
        cookie4: 360 / 4,
        cookie6: 360 / 6,
        cookie7: 360 / 7,
        cookie9: 360 / 9,
        cookie12: 360 / 12,
        sunny: 360 / 8,
        verySunny: 360 / 8,
        clover8: 360 / 8
    })

    readonly property real symmetryStep: root._symmetrySteps[root.name] ?? 0

    readonly property var _pool: {
        const keys = (root.shapes && root.shapes.length > 0) ? root.shapes : Object.keys(root._catalog);
        return keys.map(k => root._catalog[k]).filter(g => g !== undefined);
    }

    property var _lastGetter: null

    function _pick() {
        if (!root._pool || root._pool.length === 0) return null;
        const candidates = (root._pool.length > 1 && root._lastGetter) ? root._pool.filter(g => g !== root._lastGetter) : root._pool;
        const getter = candidates[Math.floor(Math.random() * candidates.length)];
        root._lastGetter = getter;
        return getter();
    }

    property bool _ready: false

    function reshape() {
        if (!root._ready || !root._pool || root._pool.length === 0) return;
        if (root.random || root.cycleInterval > 0 || !root.name) {
            root._applyPolygon(root._pick());
            return;
        }
        const getter = root._catalog[root.name];
        root._applyPolygon(getter ? getter() : root._pick());
    }

    onNameChanged: root.reshape()
    onShapesChanged: root.reshape()
    onRandomChanged: root.reshape()
    Component.onCompleted: {
        root._ready = true;
        Qt.callLater(root.reshape);
    }

    Timer {
        interval: root.cycleInterval
        running: root.cycleInterval > 0
        repeat: true
        onTriggered: root._applyPolygon(root._pick())
    }

    property var _polygon: null
    property var _morph: null
    property real _progress: 1

    function _applyPolygon(poly) {
        if (!poly) return;
        const from = root._polygon;
        root._morph = new Morph.Morph(from ?? poly, poly);
        root._polygon = poly;

        morphBehavior.enabled = false;
        root._progress = from ? 0 : 1;
        morphBehavior.enabled = true;
        if (from) root._progress = 1;
    }

    Behavior on _progress {
        id: morphBehavior
        NumberAnimation {
            duration: 350
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.42, 1.67, 0.21, 0.90, 1, 1]
        }
    }

    readonly property string _svgPath: {
        const morph = root._morph;
        const size = Math.min(root.width, root.height);
        if (!morph || size <= 0) return "";

        const cubics = morph.asCubics(root._progress);
        if (cubics.length === 0) return "";

        let d = "M " + (cubics[0].anchor0X * size) + " " + (cubics[0].anchor0Y * size);
        for (const c of cubics) {
            d += " C " + (c.control0X * size) + " " + (c.control0Y * size)
               + " "   + (c.control1X * size) + " " + (c.control1Y * size)
               + " "   + (c.anchor1X  * size) + " " + (c.anchor1Y  * size);
        }
        return d + " Z";
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        asynchronous: false

        ShapePath {
            fillColor: root.color
            strokeColor: root.outlined ? root.strokeColor : "transparent"
            strokeWidth: root.outlined ? root.strokeWidth : -1
            PathSvg { path: root._svgPath }
        }
    }
}
