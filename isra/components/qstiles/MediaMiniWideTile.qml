import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
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
    readonly property bool canPrev: player?.canGoPrevious ?? false
    readonly property bool canNext: player?.canGoNext ?? false

    property bool _showVolume: false

    readonly property color bgColor: Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)
    readonly property real bgRadius: 24

    anchors.fill: parent

    Timer {
        id: volumeHideTimer
        interval: 1000
        onTriggered: root._showVolume = false
    }

    component TransportButton: Item {
        id: btn
        required property string iconName
        required property bool iconFilled
        required property bool canUse
        required property bool innerOnRight
        signal activated

        Layout.preferredWidth: 24
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignVCenter
        opacity: (btn.canUse && !root.forceOff) ? 1 : 0.35

        Rectangle {
            anchors.fill: parent
            readonly property real outerRadius: width / 2
            readonly property real innerRadius: 6
            topLeftRadius: btn.innerOnRight ? outerRadius : innerRadius
            bottomLeftRadius: btn.innerOnRight ? outerRadius : innerRadius
            topRightRadius: btn.innerOnRight ? innerRadius : outerRadius
            bottomRightRadius: btn.innerOnRight ? innerRadius : outerRadius
            color: btnMa.containsMouse
                ? Colors.md3.surface_container_highest
                : Qt.alpha(Colors.md3.surface_container_highest, Config.blurOpacity)
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        MaterialIcon {
            anchors.centerIn: parent
            name: btn.iconName
            iconSize: 16
            filled: btn.iconFilled
            color: Colors.md3.on_surface_variant
        }

        MouseArea {
            id: btnMa
            anchors.fill: parent
            hoverEnabled: true
            enabled: btn.canUse && !root.forceOff
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.activated()
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 4

        TransportButton {
            iconName: "next-prev"
            iconFilled: false
            canUse: root.canPrev
            innerOnRight: true
            onActivated: root.player?.previous()
        }

        ClippingRectangle {
            id: artBox
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 6
            color: root.hasArt ? "transparent" : Qt.alpha(Colors.md3.surface_container, Config.blurOpacity)

            MediaArtCrossfade {
                anchors.fill: parent
                visible: root.hasArt
                url: root.player?.trackArtUrl ?? ""
            }

            MaterialIcon {
                anchors.centerIn: parent
                visible: !root.hasArt
                name: "music-note"
                iconSize: 24
                color: Colors.md3.on_surface_variant
            }

            Rectangle {
                anchors.fill: parent
                visible: root.hasArt
                color: Qt.alpha("black", 0.35)
                opacity: (artMa.containsMouse && !root.forceOff) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }

            Rectangle {
                id: playFab
                anchors.centerIn: parent
                width: 40
                height: 40
                color: "transparent"
                opacity: (artMa.containsMouse && !!root.player && !root.forceOff && !root._showVolume) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                MaterialIcon {
                    anchors.centerIn: parent
                    name: "play-pause"
                    iconSize: 20
                    filled: root.isPlaying
                    transitionType: "wipe-right"
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root._showVolume
                text: Math.round((root.player?.volume ?? 0) * 100) + "%"
                font.pixelSize: 15
                font.weight: Font.Medium
                font.family: Config.fontFamily
                font.features: ({ "tnum": 1 })
                color: "white"
                renderType: Text.NativeRendering
            }

            MouseArea {
                id: artMa
                anchors.fill: parent
                hoverEnabled: true
                enabled: !!root.player && !root.forceOff
                cursorShape: Qt.PointingHandCursor
                onClicked: root.player?.togglePlaying()
                onWheel: wheel => {
                    if (!root.player)
                        return;
                    root.player.volume = Math.max(0, Math.min(1, root.player.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)));
                    root._showVolume = true;
                    volumeHideTimer.restart();
                }
            }
        }

        TransportButton {
            iconName: "next-prev"
            iconFilled: true
            canUse: root.canNext
            innerOnRight: false
            onActivated: root.player?.next()
        }
    }
}
