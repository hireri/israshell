import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.icons
import qs.services
import qs.style

Rectangle {
    id: root

    readonly property var player: MediaPlayerState.displayPlayer
    readonly property bool hasPlayer: player !== null && player !== undefined
    readonly property bool isPlaying: hasPlayer && player.playbackState === MprisPlaybackState.Playing
    readonly property string artUrl: hasPlayer ? (player.trackArtUrl ?? "") : ""

    onArtUrlChanged: MediaPlayerState.ensureColors(artUrl)
    Component.onCompleted: MediaPlayerState.ensureColors(artUrl)

    readonly property var _dominant: MediaPlayerState.resolvedColor(artUrl)
    readonly property bool _dark: typeof Config.darkMode !== "undefined" ? Config.darkMode : true
    readonly property var _scheme: _dominant ? ColorUtils.m3CardScheme(_dominant, _dark) : null

    readonly property color cSurface: _scheme?.surfaceContainer ?? Colors.md3.surface_container
    readonly property color cHigh: _scheme?.surfaceContainerHigh ?? Colors.md3.surface_container_high
    readonly property color cTonal: _scheme?.primaryContainer ?? Colors.md3.secondary_container
    readonly property color cOnTonal: _scheme?.onPrimaryContainer ?? Colors.md3.on_secondary_container
    readonly property color cPrimary: _scheme?.primary ?? Colors.md3.primary
    readonly property color cOnPrimary: _scheme?.onPrimary ?? Colors.md3.on_primary
    readonly property color cOnSurface: _scheme?.onSurface ?? Colors.md3.on_surface
    readonly property color cOnVariant: _scheme?.onSurfaceVariant ?? Colors.md3.on_surface_variant
    readonly property color cOutline: _scheme?.outline ?? Colors.md3.outline_variant

    implicitWidth: 380
    implicitHeight: 64
    radius: height / 2
    color: cSurface
    border.width: 1
    border.color: cOutline
    visible: hasPlayer

    Behavior on color {
        ColorAnimation { duration: 400; easing.type: Easing.InOutQuad }
    }
    Behavior on border.color {
        ColorAnimation { duration: 400; easing.type: Easing.InOutQuad }
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 9
            rightMargin: 9
        }
        spacing: 10

        Item {
            id: cover

            readonly property bool showRing: Config.bar.playerRing ?? false
            readonly property real inset: showRing ? 4 : 0

            Layout.preferredWidth: 46
            Layout.preferredHeight: 46

            MprisProgress {
                id: progress
                player: root.player
                active: root.visible && cover.showRing
            }

            ProgressRing {
                anchors.fill: parent
                visible: cover.showRing
                progress: progress.progress
                strokeWidth: 2.6
                activeColor: root.cPrimary
                trackColor: Qt.alpha(root.cPrimary, 0.25)
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: cover.inset
                radius: height / 2
                color: root.cHigh

                MaterialIcon {
                    anchors.centerIn: parent
                    visible: root.artUrl === ""
                    name: "music-note"
                    iconSize: 18
                    color: root.cOnVariant
                }
            }

            CrossfadeArt {
                id: art

                readonly property bool spinEnabled: Config.bar.spinningCover ?? false
                readonly property bool spin: root.isPlaying && spinEnabled
                settleUpright: !spinEnabled
                property real velocity: spin ? 0.5 : 0

                anchors.fill: parent
                anchors.margins: cover.inset
                radius: height / 2
                antialiasing: true
                url: root.artUrl
                renderSize: Qt.size(92, 92)

                Behavior on velocity {
                    NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
                }

                Timer {
                    interval: 16
                    repeat: true
                    running: art.spinEnabled && (art.spin || art.velocity > 0.001)
                    onTriggered: art.contentRotation = (art.contentRotation + art.velocity) % 360
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            implicitHeight: titles.implicitHeight

            Column {
                id: titles
                width: parent.width
                spacing: 1

                Text {
                    width: parent.width
                    text: root.hasPlayer ? root.player.trackTitle : ""
                    color: root.cOnSurface
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    visible: text !== ""
                    text: root.hasPlayer ? (root.player.trackArtist ?? "") : ""
                    color: root.cOnVariant
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }
        }

        RowLayout {
            spacing: 4

            LockButton {
                size: 44
                iconSize: 20
                restRadius: root.isPlaying ? 14 : 22
                icon: "play-pause"
                filled: root.isPlaying
                container: root.cPrimary
                content: root.cOnPrimary
                enabled: root.hasPlayer && !!root.player.canTogglePlaying
                onClicked: root.isPlaying ? root.player.pause() : root.player.play()
            }
            LockButton {
                size: 44
                iconSize: 18
                icon: "next-prev"
                filled: true
                container: root.cTonal
                content: root.cOnTonal
                enabled: root.hasPlayer && !!root.player.canGoNext
                onClicked: root.player.next()
            }
        }
    }
}
