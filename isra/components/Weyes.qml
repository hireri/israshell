pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import Quickshell
import qs.services
import qs.style
import qs.icons

Item {
    id: root
    required property var modelData

    anchors.fill: parent

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

    readonly property var referenceScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    readonly property real referenceWidth: referenceScreen?.width ?? modelData?.width ?? 1920
    readonly property real referenceHeight: referenceScreen?.height ?? modelData?.height ?? 1080

    function _screenTransform(curW: real, curH: real): var {
        const scale = Math.max(curW / root.referenceWidth, curH / root.referenceHeight);
        return {
            scale: scale,
            cropX: (root.referenceWidth * scale - curW) / 2,
            cropY: (root.referenceHeight * scale - curH) / 2
        };
    }

    function _applyScaledDefault(): void {
        const curW = modelData?.width ?? root.referenceWidth;
        const curH = modelData?.height ?? root.referenceHeight;
        const t = _screenTransform(curW, curH);

        localX = (Config.weyes.x ?? 100) * t.scale - t.cropX;
        localY = (Config.weyes.y ?? 100) * t.scale - t.cropY;
        localWidth = (Config.weyes.width ?? 220) * t.scale;
        localHeight = (Config.weyes.height ?? 120) * t.scale;
    }

    function loadGeometry(): void {
        if (!Config.weyes) return;

        const mirror = Config.weyes.mirror ?? true;
        if (mirror) {
            _applyScaledDefault();
        } else if (modelData && modelData.name) {
            const pos = Config.weyesPositions?.[modelData.name];
            if (pos) {
                localX = pos.x ?? 100;
                localY = pos.y ?? 100;
                localWidth = pos.width ?? 220;
                localHeight = pos.height ?? 120;
            } else {
                _applyScaledDefault();
            }
        }
    }

    onModelDataChanged: loadGeometry()

    property bool _mirrorInitialized: false
    property bool _prevMirror: true

    function _seedMirrorBaseFromReferenceMonitor(): void {
        if (root.modelData !== root.referenceScreen) return;
        const pos = Config.weyesPositions?.[root.modelData?.name];
        if (!pos) return;
        Config.update({
            weyes: Object.assign({}, Config.weyes, {
                x: pos.x,
                y: pos.y,
                width: pos.width,
                height: pos.height
            })
        });
    }

    function _captureCurrentAsIndividualPosition(): void {
        if (!root.modelData || !root.modelData.name) return;
        const positions = Object.assign({}, Config.weyesPositions ?? {});
        positions[root.modelData.name] = {
            x: Math.round(root.localX),
            y: Math.round(root.localY),
            width: Math.round(root.localWidth),
            height: Math.round(root.localHeight)
        };
        Config.update({ weyesPositions: positions });
    }

    Connections {
        target: Config
        function onWeyesChanged() {
            const mirror = Config.weyes.mirror ?? true;
            const enabling = root._mirrorInitialized && !root._prevMirror && mirror;
            const disabling = root._mirrorInitialized && root._prevMirror && !mirror;
            root._prevMirror = mirror;
            root._mirrorInitialized = true;
            if (enabling) {
                root._seedMirrorBaseFromReferenceMonitor();
            } else if (disabling) {
                root._captureCurrentAsIndividualPosition();
            }
            root.loadGeometry();
        }
        function onWeyesPositionsChanged() {
            if (root._mirrorInitialized && root._prevMirror !== (Config.weyes.mirror ?? true))
                return;
            root.loadGeometry();
        }
    }

    Component.onCompleted: {
        CursorService.acquire();
        root._prevMirror = Config.weyes?.mirror ?? true;
        root._mirrorInitialized = true;
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

    Item {
        id: weyesRoot
        x: root.localX
        y: root.localY
        width: root.localWidth
        height: root.localHeight

        Row {
            id: eyesRow
            anchors.centerIn: parent
            spacing: Math.max(4, weyesRoot.width * 0.07)

            Eye {
                width: (weyesRoot.width - eyesRow.spacing) / 2
                height: weyesRoot.height
            }
            Eye {
                width: (weyesRoot.width - eyesRow.spacing) / 2
                height: weyesRoot.height
            }
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

            readonly property real eyeCenterX: eye.x + eye.width / 2 + (weyesRoot.width - eyesRow.width) / 2
            readonly property real eyeCenterY: eye.y + eye.height / 2 + (weyesRoot.height - eyesRow.height) / 2

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

    EditableFrame {
        id: weyesEditFrame
        trackX: weyesRoot.x
        trackY: weyesRoot.y
        trackWidth: weyesRoot.width
        trackHeight: weyesRoot.height
        label: "Weyes"
        interactive: EditModeService.active
        showChrome: EditModeService.active
        movable: true
        resizable: true
        uniformScale: false
        cornerRadius: 8

        quickActions: Component {
            Rectangle {
                width: 16
                height: 16
                radius: 8
                color: removeMouse.containsMouse ? Qt.alpha(Colors.md3.error, 0.15) : "transparent"

                Behavior on color {
                    ColorAnimation { duration: 100 }
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    name: "delete"
                    iconSize: 12
                    color: Colors.md3.error
                }

                MouseArea {
                    id: removeMouse
                    anchors.fill: parent
                    anchors.margins: -3
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Config.update({
                        weyes: Object.assign({}, Config.weyes, { enabled: false })
                    })
                }
            }
        }

        property real _startX: 0
        property real _startY: 0
        property real _startWidth: 0
        property real _startHeight: 0

        onMoveStarted: {
            _startX = root.localX;
            _startY = root.localY;
        }
        onMoveDelta: (dx, dy) => {
            root.localX = _startX + dx;
            root.localY = _startY + dy;
        }
        onMoveCommitted: root.commitGeometry()

        onResizeStarted: {
            _startWidth = root.localWidth;
            _startHeight = root.localHeight;
        }
        onResizeDelta: (dw, dh) => {
            root.localWidth = Math.max(root.minWidth, _startWidth + dw);
            root.localHeight = Math.max(root.minHeight, _startHeight + dh);
        }
        onResizeCommitted: root.commitGeometry()
    }

    function commitGeometry(): void {
        const mirror = Config.weyes.mirror ?? true;
        if (mirror) {
            const curW = root.modelData?.width ?? root.referenceWidth;
            const curH = root.modelData?.height ?? root.referenceHeight;
            const t = root._screenTransform(curW, curH);

            Config.update({
                weyes: Object.assign({}, Config.weyes, {
                    mirror: true,
                    x: Math.round((root.localX + t.cropX) / t.scale),
                    y: Math.round((root.localY + t.cropY) / t.scale),
                    width: Math.round(root.localWidth / t.scale),
                    height: Math.round(root.localHeight / t.scale)
                })
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
