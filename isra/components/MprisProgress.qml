pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.Mpris

QtObject {
    id: root

    property var player: null
    property bool active: true

    property real progress: 0

    function resetTo(target: real): void {
        resetAnim.stop();
        resetAnim.to = target;
        resetAnim.start();
    }

    function sync(): void {
        if (resetAnim.running)
            return;
        const p = root.player;
        if (!p || !p.length || p.length <= 0) {
            root.progress = 0;
            return;
        }
        const target = Math.max(0, Math.min(1, p.position / p.length));
        if (target < root.progress - 0.05)
            root.resetTo(target);
        else
            root.progress = target;
    }

    onPlayerChanged: root.resetTo(0)

    readonly property NumberAnimation _resetAnim: NumberAnimation {
        id: resetAnim
        target: root
        property: "progress"
        duration: 380
        easing.type: Easing.OutCubic
    }

    readonly property Connections _playerConn: Connections {
        target: root.player ?? null
        function onTrackTitleChanged(): void {
            root.resetTo(0);
        }
        function onPositionChanged(): void {
            root.sync();
        }
    }

    readonly property Timer _tick: Timer {
        interval: 16
        repeat: true
        running: root.active && root.player !== null && root.player.playbackState === MprisPlaybackState.Playing && !resetAnim.running
        onTriggered: {
            root.player.positionChanged();
            root.sync();
        }
    }
}
