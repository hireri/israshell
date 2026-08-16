import QtQuick
import QtQuick.Shapes
import qs.style

Item {
    id: root

    property bool tracking: true
    property real targetX: 0
    property real targetY: 0

    readonly property bool tinted: !!(Config.weyes && Config.weyes.tinted)

    readonly property color socketColor: root.tinted ? (Colors.md3.surface_container_high ?? "#e8e8e8") : "#ffffff"
    readonly property color borderColor: root.tinted ? (Colors.md3.outline ?? "#888888") : "#000000"
    readonly property color pupilColor: root.tinted ? (Colors.md3.on_surface ?? "#202020") : "#000000"

    Row {
        id: eyesRow
        anchors.centerIn: parent
        spacing: Math.max(4, root.width * 0.07)

        Eye {
            width: (root.width - eyesRow.spacing) / 2
            height: root.height
        }
        Eye {
            width: (root.width - eyesRow.spacing) / 2
            height: root.height
        }
    }

    component Eye: Item {
        id: eye

        readonly property real borderWidth: Math.max(3.0, Math.min(eye.width, eye.height) * 0.1)
        readonly property real pupilMargin: Math.max(3.0, Math.min(eye.width, eye.height) * 0.07)

        Shape {
            id: socket
            anchors.fill: parent
            layer.enabled: true
            layer.samples: 4

            ShapePath {
                fillColor: root.socketColor
                strokeColor: root.borderColor
                strokeWidth: eye.borderWidth

                PathAngleArc {
                    centerX: eye.width / 2
                    centerY: eye.height / 2
                    radiusX: Math.max(1, (eye.width / 2) - (eye.borderWidth / 2))
                    radiusY: Math.max(1, (eye.height / 2) - (eye.borderWidth / 2))
                    startAngle: 0
                    sweepAngle: 360
                }
            }
        }

        Shape {
            id: pupilShape
            width: eye.width * 0.20
            height: eye.height * 0.20
            layer.enabled: true
            layer.samples: 4

            readonly property real eyeCenterX: eye.x + eye.width / 2 + (root.width - eyesRow.width) / 2
            readonly property real eyeCenterY: eye.y + eye.height / 2 + (root.height - eyesRow.height) / 2

            readonly property real dx: root.tracking ? root.targetX - eyeCenterX : 0
            readonly property real dy: root.tracking ? root.targetY - eyeCenterY : 0

            readonly property real constA: Math.max(1, (eye.width / 2) - (pupilShape.width / 2) - eye.borderWidth - eye.pupilMargin)
            readonly property real constB: Math.max(1, (eye.height / 2) - (pupilShape.height / 2) - eye.borderWidth - eye.pupilMargin)

            readonly property real normDistSq: (dx * dx) / (constA * constA) + (dy * dy) / (constB * constB)

            readonly property real xp: normDistSq <= 1.0 ? dx : dx / Math.sqrt(normDistSq)
            readonly property real yp: normDistSq <= 1.0 ? dy : dy / Math.sqrt(normDistSq)

            x: (eye.width / 2) + xp - (pupilShape.width / 2)
            y: (eye.height / 2) + yp - (pupilShape.height / 2)

            ShapePath {
                fillColor: root.pupilColor
                strokeColor: "transparent"

                PathAngleArc {
                    centerX: pupilShape.width / 2
                    centerY: pupilShape.height / 2
                    radiusX: pupilShape.width / 2
                    radiusY: pupilShape.height / 2
                    startAngle: 0
                    sweepAngle: 360
                }
            }
        }
    }
}
