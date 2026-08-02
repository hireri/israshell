import QtQuick
import Quickshell.Services.Mpris
import qs.style
import qs.services
import qs.icons

Item {
    id: root

    property bool forceOff: false

    readonly property var player: MediaPlayerState.displayPlayer
    readonly property bool hasArt: !!player && (player.trackArtUrl ?? "") !== ""
    readonly property bool isPlaying: !!player && player.playbackState === MprisPlaybackState.Playing

    property bool _showVolume: false

    readonly property color bgColor: root.hasArt
        ? Colors.md3.surface_container_highest
        : ((mouseArea.containsMouse && !forceOff)
            ? Qt.alpha(Colors.md3.surface_container_highest, Config.blurOpacity)
            : Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity))
    readonly property real bgRadius: root.isPlaying ? 18 : 28

    anchors.fill: parent

    Timer {
        id: volumeHideTimer
        interval: 1000
        onTriggered: root._showVolume = false
    }

    MediaArtCrossfade {
        anchors.fill: parent
        visible: root.hasArt
        url: root.player?.trackArtUrl ?? ""
    }

    Rectangle {
        anchors.fill: parent
        visible: root.hasArt
        color: Qt.alpha("black", 0.35)
    }

    MaterialIcon {
        anchors.centerIn: parent
        visible: !root.hasArt && !root._showVolume
        name: "music-note"
        iconSize: 22
        color: root.player ? Colors.md3.on_surface : Colors.md3.on_surface_variant
    }

    MaterialIcon {
        anchors.centerIn: parent
        visible: root.hasArt && !root._showVolume
        name: "play-pause"
        iconSize: 20
        filled: root.isPlaying
        color: "white"
        transitionType: "wipe-right"
    }

    Text {
        anchors.centerIn: parent
        visible: root._showVolume
        text: Math.round((root.player?.volume ?? 0) * 100) + "%"
        font.pixelSize: 13
        font.weight: Font.Medium
        font.family: Config.fontFamily
        font.features: ({ "tnum": 1 })
        color: root.hasArt ? "white" : Colors.md3.on_surface
        renderType: Text.NativeRendering
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        enabled: !root.forceOff
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (!root.player)
                return;
            mouse.button === Qt.RightButton ? root.player.next() : root.player.togglePlaying();
        }
        onWheel: wheel => {
            if (!root.player)
                return;
            root.player.volume = Math.max(0, Math.min(1, root.player.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)));
            root._showVolume = true;
            volumeHideTimer.restart();
        }
    }
}
