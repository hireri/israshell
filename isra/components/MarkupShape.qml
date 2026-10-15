pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import qs.style
import "markup.js" as Markup

Item {
    id: root

    property var shape: null
    property real originX: 0
    property real originY: 0
    property Item backgroundSource: null

    anchors.fill: parent

    readonly property var box: shape ? Markup.normRect(shape) : ({ x: 0, y: 0, w: 0, h: 0 })
    readonly property var lbox: ({ x: box.x - originX, y: box.y - originY, w: box.w, h: box.h })
    readonly property var localPoints: shape && shape.points ? shape.points.map(p => toLocal(p.x, p.y)) : []

    function toLocal(gx, gy) {
        return Qt.point(gx - originX, gy - originY);
    }

    Loader {
        anchors.fill: parent
        sourceComponent: {
            if (!root.shape)
                return null;
            const boxed = root.lbox.w > 0 && root.lbox.h > 0;
            switch (root.shape.type) {
            case "rect": return boxed ? rectC : null;
            case "ellipse": return boxed ? ellipseC : null;
            case "line": return lineC;
            case "arrow": return arrowC;
            case "pen":
            case "highlighter": return polyC;
            case "text": return textC;
            case "step": return stepC;
            case "blur": return boxed ? blurC : null;
            case "pixelate": return boxed ? pixelateC : null;
            default: return null;
            }
        }
    }

    Component {
        id: rectC
        Item {
            anchors.fill: parent
            Rectangle {
                x: root.lbox.x
                y: root.lbox.y
                width: root.lbox.w
                height: root.lbox.h
                color: "transparent"
                border.color: root.shape.color
                border.width: root.shape.width
            }
        }
    }

    Component {
        id: ellipseC
        Item {
            anchors.fill: parent
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: root.shape.color
                    strokeWidth: root.shape.width
                    fillColor: "transparent"
                    PathAngleArc {
                        centerX: root.lbox.x + root.lbox.w / 2
                        centerY: root.lbox.y + root.lbox.h / 2
                        radiusX: root.lbox.w / 2
                        radiusY: root.lbox.h / 2
                        startAngle: 0
                        sweepAngle: 360
                    }
                }
            }
        }
    }

    Component {
        id: lineC
        Item {
            id: lineRoot
            anchors.fill: parent
            readonly property var p1: root.toLocal(root.shape.x1, root.shape.y1)
            readonly property var p2: root.toLocal(root.shape.x2, root.shape.y2)
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: root.shape.color
                    strokeWidth: root.shape.width
                    capStyle: ShapePath.RoundCap
                    fillColor: "transparent"
                    PathPolyline { path: [lineRoot.p1, lineRoot.p2] }
                }
            }
        }
    }

    Component {
        id: arrowC
        Item {
            anchors.fill: parent
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: root.shape.color
                    strokeWidth: 1
                    fillColor: root.shape.color
                    joinStyle: ShapePath.RoundJoin
                    PathPolyline { path: Markup.arrowPolygon(root.shape.x1, root.shape.y1, root.shape.x2, root.shape.y2, root.shape.width).map(p => root.toLocal(p.x, p.y)) }
                }
            }
        }
    }

    Component {
        id: polyC
        Item {
            id: polyRoot
            anchors.fill: parent
            readonly property bool marker: root.shape.type === "highlighter"
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: polyRoot.marker ? Qt.alpha(root.shape.color, 0.4) : root.shape.color
                    strokeWidth: polyRoot.marker ? root.shape.width * 4 : root.shape.width
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    fillColor: "transparent"
                    PathPolyline { path: root.localPoints }
                }
            }
        }
    }

    Component {
        id: textC
        Item {
            id: textRoot
            anchors.fill: parent
            readonly property var p1: root.toLocal(root.shape.x1, root.shape.y1)
            Text {
                x: textRoot.p1.x
                y: textRoot.p1.y
                text: root.shape.text
                color: root.shape.color
                font.family: Config.fontFamily
                font.pixelSize: Markup.fontSize(root.shape.width)
                font.weight: Font.Bold
                style: Text.Outline
                styleColor: Markup.contrastColor(root.shape.color)
            }
        }
    }

    Component {
        id: stepC
        Item {
            id: stepRoot
            anchors.fill: parent
            readonly property var c: root.toLocal(root.shape.x1, root.shape.y1)
            readonly property real d: Markup.stepDiameter(root.shape.width)
            Rectangle {
                x: stepRoot.c.x - stepRoot.d / 2
                y: stepRoot.c.y - stepRoot.d / 2
                width: stepRoot.d
                height: stepRoot.d
                radius: stepRoot.d / 2
                color: root.shape.color
                Text {
                    anchors.centerIn: parent
                    text: String(root.shape.n)
                    color: Markup.contrastColor(root.shape.color)
                    font.pixelSize: stepRoot.d * 0.55
                    font.weight: Font.Bold
                }
            }
        }
    }

    Component {
        id: blurC
        Item {
            id: blurRoot
            anchors.fill: parent
            readonly property int pad: 32
            Rectangle {
                x: root.lbox.x
                y: root.lbox.y
                width: root.lbox.w
                height: root.lbox.h
                color: Colors.md3.surface_container
                visible: root.backgroundSource === null
            }
            Item {
                x: root.lbox.x
                y: root.lbox.y
                width: root.lbox.w
                height: root.lbox.h
                clip: true
                visible: root.backgroundSource !== null
                ShaderEffectSource {
                    id: blurSource
                    sourceItem: root.backgroundSource
                    sourceRect: Qt.rect(root.lbox.x - blurRoot.pad, root.lbox.y - blurRoot.pad, root.lbox.w + 2 * blurRoot.pad, root.lbox.h + 2 * blurRoot.pad)
                    live: true
                    hideSource: false
                    visible: false
                }
                MultiEffect {
                    x: -blurRoot.pad
                    y: -blurRoot.pad
                    width: root.lbox.w + 2 * blurRoot.pad
                    height: root.lbox.h + 2 * blurRoot.pad
                    source: blurSource
                    blurEnabled: true
                    blurMax: 64
                    blur: 1.0
                    autoPaddingEnabled: false
                }
            }
        }
    }

    Component {
        id: pixelateC
        Item {
            anchors.fill: parent
            Rectangle {
                x: root.lbox.x
                y: root.lbox.y
                width: root.lbox.w
                height: root.lbox.h
                color: Colors.md3.surface_container
                visible: root.backgroundSource === null
            }
            ShaderEffectSource {
                x: root.lbox.x
                y: root.lbox.y
                width: root.lbox.w
                height: root.lbox.h
                visible: root.backgroundSource !== null
                sourceItem: root.backgroundSource
                sourceRect: Qt.rect(root.lbox.x, root.lbox.y, root.lbox.w, root.lbox.h)
                textureSize: Qt.size(Math.max(1, Math.ceil(root.lbox.w / 12)), Math.max(1, Math.ceil(root.lbox.h / 12)))
                smooth: false
                live: true
                hideSource: false
            }
        }
    }
}
