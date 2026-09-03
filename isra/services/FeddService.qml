pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.style

Singleton {
    id: root

    readonly property string _assetDir: Quickshell.shellDir + "/assets"

    function trigger() {
        flashTimer.restart();
        SoundService.playUrl("file://" + root._assetDir + "/fedd.mp3");
    }

    Timer {
        interval: 1000
        repeat: true
        running: Config.fedd.enabled
        onTriggered: {
            if (LockscreenService.locked || LockscreenService.lockAnimating)
                return;
            if (Math.floor(Math.random() * Config.fedd.chance) === 0)
                root.trigger();
        }
    }

    Timer {
        id: flashTimer
        interval: 250
    }

    PanelWindow {
        id: popup

        visible: flashTimer.running
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:fedd"
        mask: Region {}

        Image {
            anchors.fill: parent
            source: "file://" + root._assetDir + "/fedd.webp"
            smooth: false
        }
    }
}
