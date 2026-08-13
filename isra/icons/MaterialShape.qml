import QtQuick
import qs.components.shapes

import "../components/shapes/material-shapes.js" as MaterialShapes

ShapeCanvas {
    id: root

    property string name: ""
    property var shapes: []
    property bool random: false
    property int cycleInterval: 0
    property real shapeSize: 24
    property real rotationDegrees: 0

    width: shapeSize
    height: shapeSize
    color: "white"
    rotation: root.rotationDegrees

    Behavior on rotation {
        NumberAnimation {
            duration: 350
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.42, 1.67, 0.21, 0.90, 1, 1]
        }
    }

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

    readonly property var _pool: {
        const keys = (root.shapes && root.shapes.length > 0) ? root.shapes : Object.keys(root._catalog);
        return keys.map(k => root._catalog[k]).filter(g => g !== undefined);
    }

    property var _lastGetter: null

    function _pick() {
        const candidates = (root._pool.length > 1 && root._lastGetter) ? root._pool.filter(g => g !== root._lastGetter) : root._pool;
        const getter = candidates[Math.floor(Math.random() * candidates.length)];
        root._lastGetter = getter;
        return getter();
    }

    roundedPolygon: {
        let base;
        if (root.random || root.cycleInterval > 0 || !root.name) {
            base = root._pick();
        } else {
            const getter = root._catalog[root.name];
            base = getter ? getter() : root._pick();
        }
        return base;
    }

    Timer {
        interval: root.cycleInterval
        running: root.cycleInterval > 0
        repeat: true
        onTriggered: root.roundedPolygon = root._pick()
    }
}
