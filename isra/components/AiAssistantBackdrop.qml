import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import qs.style
import qs.services

PanelWindow {
    id: root

    required property var modelData
    screen: modelData
    visible: modelData.name === CompositorService.focusedMonitor?.name
    color: Qt.alpha(Colors.md3.background, root.isFresh ? 0.45 : 0.65)
    exclusionMode: ExclusionMode.Ignore

    Behavior on color {
        ColorAnimation {
            duration: 420
        }
    }

    WlrLayershell.namespace: "quickshell:aiassistant-backdrop"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    property bool revealed: false
    readonly property bool isFresh: AiAssistantService.history.length === 0 && !AiAssistantService.hasError && AiAssistantService.streamedAnswer === ""

    Component.onCompleted: Qt.callLater(() => root.revealed = true)

    Item {
        id: content
        anchors.fill: parent
        opacity: root.revealed ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 420
                easing.type: Easing.OutQuint
            }
        }

        Item {
            id: gradientLayer
            anchors.fill: parent
            visible: false

            property color colorA: Colors.md3.primary
            property color colorB: Colors.md3.secondary
            property color colorC: Colors.md3.tertiary

            SequentialAnimation on colorA {
                loops: Animation.Infinite
                ColorAnimation { to: Colors.md3.secondary; duration: 4000 }
                ColorAnimation { to: Colors.md3.tertiary; duration: 4000 }
                ColorAnimation { to: Colors.md3.primary; duration: 4000 }
            }
            SequentialAnimation on colorB {
                loops: Animation.Infinite
                ColorAnimation { to: Colors.md3.tertiary; duration: 4000 }
                ColorAnimation { to: Colors.md3.primary; duration: 4000 }
                ColorAnimation { to: Colors.md3.secondary; duration: 4000 }
            }
            SequentialAnimation on colorC {
                loops: Animation.Infinite
                ColorAnimation { to: Colors.md3.primary; duration: 4000 }
                ColorAnimation { to: Colors.md3.secondary; duration: 4000 }
                ColorAnimation { to: Colors.md3.tertiary; duration: 4000 }
            }

            property real gradientAngle: 0

            NumberAnimation on gradientAngle {
                from: 0
                to: 360
                duration: 9000
                loops: Animation.Infinite
                running: true
            }

            Rectangle {
                id: gradientRect
                
                width: Math.max(root.width, root.height) * 1.5
                height: width
                anchors.centerIn: parent
                rotation: gradientLayer.gradientAngle

                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: gradientLayer.colorA }
                    GradientStop { position: 0.34; color: gradientLayer.colorB }
                    GradientStop { position: 0.67; color: gradientLayer.colorC }
                    GradientStop { position: 1.0; color: gradientLayer.colorA }
                }
            }
        }

        HueSaturation {
            id: coloredGradient
            anchors.fill: gradientLayer
            source: gradientLayer
            saturation: 0.6
            lightness: 0.05
            visible: false
        }

        Item {
            id: maskShape
            anchors.fill: parent
            visible: false
            readonly property real band: 20

            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: maskShape.band
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: "white" }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }
            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: maskShape.band
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: "white" }
                }
            }
            Rectangle {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: maskShape.band
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "white" }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }
            Rectangle {
                anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                width: maskShape.band
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: "white" }
                }
            }
        }

        OpacityMask {
            id: maskedGlow
            anchors.fill: parent
            source: coloredGradient
            maskSource: maskShape
            visible: false
        }

        FastBlur {
            anchors.fill: parent
            source: maskedGlow
            radius: 38
            opacity: root.isFresh ? 1.0 : 0.4

            Behavior on opacity {
                NumberAnimation {
                    duration: 750
                    easing.type: Easing.OutCubic
                }
            }
        }

        Canvas {
            id: dotCanvas
            anchors.fill: parent
            renderStrategy: Canvas.Cooperative

            readonly property real cellSize: 30
            readonly property real baseRadius: 1.3
            readonly property real maxAlpha: 0.35
            readonly property color dotColor: Colors.md3.on_surface
            readonly property real noiseScale: 0.11

            readonly property real islandThreshold: 0.6
            readonly property real coreDepth: 0.22

            readonly property real minIslandCeiling: 0.35

            property real t: 0

            property var lattice: []
            readonly property int latticeSize: 24

            opacity: root.isFresh ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: 750
                    easing.type: Easing.OutCubic
                }
            }

            function regenLattice() {
                const size = latticeSize + 2;
                const arr = new Array(size * size);
                for (let i = 0; i < arr.length; i++)
                    arr[i] = Math.random();
                lattice = arr;
            }
            Component.onCompleted: regenLattice()

            function latticeAt(ix, iy) {
                const size = latticeSize + 2;
                const wx = ((ix % size) + size) % size;
                const wy = ((iy % size) + size) % size;
                return lattice[wy * size + wx];
            }

            function smoothstep(a, b, x) {
                const t = Math.max(0, Math.min(1, (x - a) / (b - a)));
                return t * t * (3 - 2 * t);
            }

            function valueNoise(x, y) {
                const ix = Math.floor(x);
                const iy = Math.floor(y);
                const fx = x - ix;
                const fy = y - iy;

                const a = latticeAt(ix, iy);
                const b = latticeAt(ix + 1, iy);
                const c = latticeAt(ix, iy + 1);
                const d = latticeAt(ix + 1, iy + 1);

                const ux = smoothstep(0, 1, fx);
                const uy = smoothstep(0, 1, fy);

                const top = a + (b - a) * ux;
                const bottom = c + (d - c) * ux;
                return top + (bottom - top) * uy;
            }

            function density(nx, ny) {
                const n1 = valueNoise(nx + t * 0.18, ny + t * 0.12);
                const n2 = valueNoise(nx * 2.1 - t * 0.1, ny * 2.1 + t * 0.15);
                return n1 * 0.7 + n2 * 0.3;
            }

            function ceilingField(nx, ny) {
                return valueNoise(nx * 0.6 + 100 + t * 0.08, ny * 0.6 - 50 + t * 0.05);
            }

            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                if (opacity <= 0.001)
                    return;

                const cols = Math.ceil(width / cellSize) + 1;
                const rows = Math.ceil(height / cellSize) + 1;
                const c = dotColor;
                const thresh = islandThreshold;
                const core = coreDepth;

                for (let j = 0; j < rows; j++) {
                    for (let i = 0; i < cols; i++) {
                        const nx = i * noiseScale;
                        const ny = j * noiseScale;
                        const d = density(nx, ny);

                        if (d <= thresh)
                            continue;

                        const ceiling = minIslandCeiling + (1 - minIslandCeiling) * ceilingField(nx, ny);

                        const depth = Math.min(1, (d - thresh) / (core * ceiling));
                        const eased = depth * depth * (3 - 2 * depth);

                        const radius = baseRadius * (1.5 - 0.5 * eased);
                        const alpha = maxAlpha * eased;

                        if (radius <= 0.3 || alpha <= 0.015)
                            continue;

                        const ox = i * cellSize;
                        const oy = j * cellSize;

                        ctx.beginPath();
                        ctx.arc(ox, oy, radius, 0, Math.PI * 2);
                        ctx.fillStyle = Qt.rgba(c.r, c.g, c.b, alpha);
                        ctx.fill();
                    }
                }
            }

            Timer {
                interval: 66
                repeat: true
                running: dotCanvas.visible && dotCanvas.opacity > 0
                onTriggered: {
                    dotCanvas.t += 0.08;
                    dotCanvas.requestPaint();
                }
            }
        }
    }
}