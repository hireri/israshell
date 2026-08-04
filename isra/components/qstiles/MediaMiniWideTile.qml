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

    readonly property bool _pillHovered: pillMa.containsMouse
        || artMa.containsMouse
        || prevBtn.hovered
        || nextBtn.hovered
    property bool _showVolume: false

    anchors.fill: parent

    Timer {
        id: volumeHideTimer
        interval: 1000
        onTriggered: root._showVolume = false
    }

    function _adjustVolume(wheel) {
        if (!root.player || root.forceOff)
            return;
        root.player.volume = Math.max(0, Math.min(1, root.player.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)));
        root._showVolume = true;
        volumeHideTimer.restart();
    }

    MouseArea {
        id: pillMa
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onWheel: wheel => root._adjustVolume(wheel)
    }

    component TransportButton: Item {
        id: btn
        required property string iconName
        required property bool iconFilled
        required property bool canUse
        required property bool isOuterEdge
        readonly property bool hovered: btnMa.containsMouse
        signal activated

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignVCenter
        opacity: (btn.canUse && !root.forceOff) ? 1 : 0.35

        Rectangle {
            anchors.fill: parent
            readonly property real outerRadius: 18
            readonly property real innerRadius: 6
            topLeftRadius: innerRadius
            bottomLeftRadius: innerRadius
            topRightRadius: btn.isOuterEdge ? outerRadius : innerRadius
            bottomRightRadius: btn.isOuterEdge ? outerRadius : innerRadius
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

        ClippingRectangle {
            id: artBox
            Layout.preferredWidth: height * 1.2
            Layout.fillHeight: true
            radius: 6
            topLeftRadius: 18
            bottomLeftRadius: 18
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
                opacity: (root._pillHovered && !root.forceOff) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }

            Rectangle {
                id: playFab
                anchors.centerIn: parent
                width: 40
                height: 40
                color: "transparent"
                opacity: (root._pillHovered && !!root.player && !root.forceOff && !root._showVolume) ? 1 : 0
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
                propagateComposedEvents: true
                onClicked: root.player?.togglePlaying()
                onWheel: wheel => wheel.accepted = false
            }
        }

        TransportButton {
            id: prevBtn
            iconName: "next-prev"
            iconFilled: false
            canUse: root.canPrev
            isOuterEdge: false
            onActivated: root.player?.previous()
        }

        TransportButton {
            id: nextBtn
            iconName: "next-prev"
            iconFilled: true
            canUse: root.canNext
            isOuterEdge: true
            onActivated: root.player?.next()
        }
    }
}