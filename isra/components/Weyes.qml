pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import qs.services
import qs.style

Item {
    id: root
    required property var modelData

    x: localX
    y: localY
    width: localWidth
    height: localHeight

    property real localX: 100
    property real localY: 100
    property real localWidth: 220
    property real localHeight: 120

    readonly property real minWidth: 40
    readonly property real minHeight: 25

    readonly property bool tinted: !!(Config.weyes && Config.weyes.tinted)

    readonly property color socketColor: root.tinted
        ? (Colors.md3.surface_container_high ?? "#e8e8e8")
        : "#ffffff"
    readonly property color borderColor: root.tinted
        ? (Colors.md3.outline ?? "#888888")
        : "#000000"
    readonly property color pupilColor: root.tinted
        ? (Colors.md3.on_surface ?? "#202020")
        : "#000000"

    function loadGeometry(): void {
        if (!Config.weyes) return;
        
        const mirror = Config.weyes.mirror ?? true;
        if (mirror) {
            localX = Config.weyes.x ?? 100;
            localY = Config.weyes.y ?? 100;
            localWidth = Config.weyes.width ?? 220;
            localHeight = Config.weyes.height ?? 120;
        } else if (modelData && modelData.name) {
            const pos = Config.weyesPositions?.[modelData.name];
            if (pos) {
                localX = pos.x ?? 100;
                localY = pos.y ?? 100;
                localWidth = pos.width ?? 220;
                localHeight = pos.height ?? 120;
            } else {
                localX = Config.weyes.x ?? 100;
                localY = Config.weyes.y ?? 100;
                localWidth = Config.weyes.width ?? 220;
                localHeight = Config.weyes.height ?? 120;
            }
        }
    }

    onModelDataChanged: loadGeometry()

    Connections {
        target: Config
        function onWeyesChanged() {
            root.loadGeometry();
        }
        function onWeyesPositionsChanged() {
            root.loadGeometry();
        }
    }

    Component.onCompleted: {
        CursorService.acquire();
        root.loadGeometry();
    }
    Component.onDestruction: CursorService.release()

    property real smoothedCursorX: CursorService.x
    property real smoothedCursorY: CursorService.y

    Behavior on smoothedCursorX {
        NumberAnimation { duration: root.smoothingDuration; easing.type: Easing.OutQuad }
    }
    Behavior on smoothedCursorY {
        NumberAnimation { duration: root.smoothingDuration; easing.type: Easing.OutQuad }
    }

    readonly property int smoothingDuration: CursorService.intervalMs + 20

    readonly property real screenOffsetX: modelData ? modelData.x : 0
    readonly property real screenOffsetY: modelData ? modelData.y : 0

    Row {
        id: eyesRow
        anchors.centerIn: parent
        spacing: Math.max(4, root.width * 0.03)

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

            readonly property real eyeScreenCenterX: root.screenOffsetX + root.localX + eyeCenterX
            readonly property real eyeScreenCenterY: root.screenOffsetY + root.localY + eyeCenterY

            readonly property real dx: root.smoothedCursorX - eyeScreenCenterX
            readonly property real dy: root.smoothedCursorY - eyeScreenCenterY

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

    MouseArea {
        id: interactionArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        
        cursorShape: {
            if (pressedButtons & Qt.RightButton) return Qt.SizeFDiagCursor;
            if (pressedButtons & Qt.LeftButton) return Qt.ClosedHandCursor;
            return Qt.OpenHandCursor;
        }

        property real startMouseX: 0
        property real startMouseY: 0
        property real startX: 0
        property real startY: 0
        property real startWidth: 0
        property real startHeight: 0
        property int activeDragButton: 0 

        onPressed: mouse => {
            const g = mapToItem(null, mouse.x, mouse.y);
            startMouseX = g.x;
            startMouseY = g.y;
            startX = root.localX;
            startY = root.localY;
            startWidth = root.localWidth;
            startHeight = root.localHeight;
            activeDragButton = mouse.button;
        }

        onPositionChanged: mouse => {
            if (activeDragButton === 0)
                return;

            const g = mapToItem(null, mouse.x, mouse.y);
            const deltaX = g.x - startMouseX;
            const deltaY = g.y - startMouseY;

            if (activeDragButton === Qt.LeftButton) {
                root.localX = startX + deltaX;
                root.localY = startY + deltaY;
            } else if (activeDragButton === Qt.RightButton) {
                root.localWidth = Math.max(root.minWidth, startWidth + deltaX);
                root.localHeight = Math.max(root.minHeight, startHeight + deltaY);
            }
        }

        onReleased: {
            activeDragButton = 0;
            root.commitGeometry();
        }
    }

    function commitGeometry(): void {
        const mirror = Config.weyes.mirror ?? true;
        if (mirror) {
            Config.update({
                weyes: {
                    enabled: Config.weyes.enabled,
                    tinted: Config.weyes.tinted,
                    mirror: true,
                    x: Math.round(root.localX),
                    y: Math.round(root.localY),
                    width: Math.round(root.localWidth),
                    height: Math.round(root.localHeight)
                }
            });
        } else {
            const positions = Object.assign({}, Config.weyesPositions ?? {});
            positions[root.modelData.name] = {
                x: Math.round(root.localX),
                y: Math.round(root.localY),
                width: Math.round(root.localWidth),
                height: Math.round(root.localHeight)
            };
            Config.update({
                weyesPositions: positions
            });
        }
    }
}