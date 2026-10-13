import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.style

PanelWindow {
    id: root
    required property var modelData
    screen: modelData

    readonly property real barHeight: Math.max(1, Config.cava.heightPct / 100 * modelData.height)

    visible: Config.cava.enabled
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region {}

    WlrLayershell.namespace: "quickshell:cava"
    WlrLayershell.layer: WlrLayer.Background
    anchors {
        left: true
        right: true
        top: Config.cava.position !== 1
        bottom: Config.cava.position === 1
    }
    implicitHeight: Math.ceil(barHeight) + 4

    BackgroundEffect.blurRegion: Config.desktopWidgetsBlurActive ? blurRegion : null

    Region {
        id: blurRegion
        width: root.width
        height: root.height
    }

    CavaVisualizer {
        anchors.fill: parent
        overrideMaxHeight: root.barHeight
        pause: LockscreenService.locked || GameModeService.active
    }
}
