import QtQuick
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

    readonly property bool blurEnabled: Config.blurAllowed()
    BackgroundEffect.blurRegion: blurEnabled ? backdropBlurRegion : null

    Region {
        id: backdropBlurRegion
        item: glow
    }

    Component.onCompleted: Qt.callLater(() => root.revealed = true)

    ShaderEffect {
        id: glow
        anchors.fill: parent
        fragmentShader: Qt.resolvedUrl("../shaders/aiBackdrop.frag.qsb")

        opacity: root.revealed ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 420
                easing.type: Easing.OutQuint
            }
        }

        property vector2d resolution: Qt.vector2d(width, height)

        property color colorA: Colors.md3.primary
        property color colorB: Colors.md3.secondary
        property color colorC: Colors.md3.tertiary
        property color dotColor: Colors.md3.on_surface

        property real time: 0
        property real gradientAngle: 0

        property real saturation: 0.6
        property real lightness: 0.05

        property real edgeSigma: 11.8
        property real edgeIntensity: 0.64

        property real cellSize: 48
        property real baseRadius: 1.3
        property real maxAlpha: 0.6
        property real noiseScale: 0.11
        property real islandThreshold: 0.6
        property real coreDepth: 0.5
        property real minIslandCeiling: 0.5

        property real glowOpacity: root.isFresh ? 1.0 : 0.4
        property real dotOpacity: root.isFresh ? 1.0 : 0.0

        Behavior on glowOpacity {
            NumberAnimation {
                duration: 750
                easing.type: Easing.OutCubic
            }
        }
        Behavior on dotOpacity {
            NumberAnimation {
                duration: 750
                easing.type: Easing.OutCubic
            }
        }

        SequentialAnimation on colorA {
            loops: Animation.Infinite
            running: root.visible
            ColorAnimation { to: Colors.md3.secondary; duration: 4000 }
            ColorAnimation { to: Colors.md3.tertiary; duration: 4000 }
            ColorAnimation { to: Colors.md3.primary; duration: 4000 }
        }
        SequentialAnimation on colorB {
            loops: Animation.Infinite
            running: root.visible
            ColorAnimation { to: Colors.md3.tertiary; duration: 4000 }
            ColorAnimation { to: Colors.md3.primary; duration: 4000 }
            ColorAnimation { to: Colors.md3.secondary; duration: 4000 }
        }
        SequentialAnimation on colorC {
            loops: Animation.Infinite
            running: root.visible
            ColorAnimation { to: Colors.md3.primary; duration: 4000 }
            ColorAnimation { to: Colors.md3.secondary; duration: 4000 }
            ColorAnimation { to: Colors.md3.tertiary; duration: 4000 }
        }

        NumberAnimation on gradientAngle {
            from: 0
            to: 360
            duration: 9000
            loops: Animation.Infinite
            running: root.visible
        }

        NumberAnimation on time {
            from: 0
            to: 3600
            duration: 3600000
            loops: Animation.Infinite
            running: root.visible
        }
    }
}
