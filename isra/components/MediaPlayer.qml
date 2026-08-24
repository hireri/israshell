pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.style
import qs.services
import qs.icons

ClippingRectangle {
    id: root

    required property var panelScreen
    required property var panelWindow
    property var controllerRegistry: null

    readonly property string panelType: "media"

    color: {
        if (root.isOpen) {
            Colors.md3.secondary_container
        } else if (Config.bar.transparentPills) {
            Qt.alpha(Colors.md3.secondary_container, 0)
        } else {
            Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    radius: Config.bar.playerMode === 1 ? height / 2 : 18
    implicitWidth: {
        if (Config.bar.playerMode === 1)
            return 32;
        if (Config.bar.playerMode === 2)
            return 216;
        return 240;
    }
    height: 32

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    readonly property bool isOpen: MediaPlayerState.openScreen === panelScreen

    onIsOpenChanged: {
        if (isOpen) {
            PanelService.opened(root, root.panelScreen);
        } else {
            PanelService.closed(root);
        }
    }

    function close(): void {
        if (root.isOpen)
            MediaPlayerState.close();
    }

    Component.onCompleted: PanelService.register(root, root.controllerRegistry, null, "")

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                MediaPlayerState.toggle(root.panelScreen);
                return;
            }
            const p = MediaPlayerState.displayPlayer;
            if (!p)
                return;
            if (mouse.button === Qt.RightButton)
                p.next();
            if (mouse.button === Qt.MiddleButton)
                p.playbackState === MprisPlaybackState.Playing ? p.pause() : p.play();
        }
        onWheel: wheel => {
            const p = MediaPlayerState.displayPlayer;
            if (!p)
                return;
            p.volume = Math.max(0, Math.min(1, p.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)));
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: (Config.bar.playerMode === 1 || Config.bar.playerMode === 2) ? 0 : 8

        Item {
            id: pillCover
            visible: Config.bar.playerMode !== 2
            implicitWidth: Config.bar.playerMode === 1 ? root.height - 4 : 24
            height: Config.bar.playerMode === 1 ? root.height - 4 : 24
            anchors.verticalCenter: parent.verticalCenter

            readonly property bool isPlaying: MediaPlayerState.displayPlayer?.playbackState === MprisPlaybackState.Playing
            readonly property bool shouldSpin: Config.bar.spinningCover && isPlaying

            readonly property bool hasPlayer: MediaPlayerState.displayPlayer !== null && MediaPlayerState.displayPlayer !== undefined
            readonly property bool showRing: hasPlayer && (Config.bar.playerRing ?? false)

            property real coverMargin: showRing ? 4 : 0
            property real ringStrokeWidth: showRing ? 2.2 : 0

            Behavior on coverMargin {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on ringStrokeWidth {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }

            MprisProgress {
                id: pillProgress
                player: MediaPlayerState.displayPlayer
                active: root.visible
            }

            Connections {
                target: MediaPlayerState
                function onDisplayPlayerChanged() {
                    MediaPlayerState.ensureArt(MediaPlayerState.displayPlayer?.trackArtUrl ?? "");
                }
            }

            Connections {
                target: MediaPlayerState.displayPlayer ?? null
                function onTrackArtUrlChanged() {
                    MediaPlayerState.ensureArt(MediaPlayerState.displayPlayer?.trackArtUrl ?? "");
                }
            }

            Component.onCompleted: MediaPlayerState.ensureArt(MediaPlayerState.displayPlayer?.trackArtUrl ?? "")

            ProgressRing {
                anchors.fill: parent
                progress: pillProgress.progress
                strokeWidth: pillCover.ringStrokeWidth
            }

            ClippingRectangle {
                anchors.fill: parent
                anchors.margins: pillCover.coverMargin
                radius: 30
                color: Colors.md3.surface_container_highest
                MaterialIcon {
                    anchors.centerIn: parent
                    name: "music-note"
                    color: Colors.md3.on_surface_variant
                    iconSize: 14
                }
            }

            CrossfadeArt {
                id: pillArt
                anchors.fill: parent
                anchors.margins: pillCover.coverMargin
                radius: 30
                antialiasing: true
                url: MediaPlayerState.displayPlayer?.trackArtUrl ?? ""
                renderSize: Qt.size(60, 60)

                property real angle: 0
                property real velocity: pillCover.shouldSpin ? 0.5 : 0
                rotation: angle

                Behavior on velocity {
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.OutCubic
                    }
                }

                Timer {
                    interval: 16
                    running: true
                    repeat: true
                    onTriggered: {
                        if (Math.abs(pillArt.velocity) > 0.001)
                            pillArt.angle = (pillArt.angle + pillArt.velocity) % 360;
                    }
                }
            }
        }

        Item {
            id: marqueeContainer
            visible: Config.bar.playerMode !== 1
            implicitWidth: Config.bar.playerMode !== 1 ? (Config.bar.playerMode === 2 ? 176 : 200) : 0
            height: 20
            clip: true
            anchors.verticalCenter: parent.verticalCenter

            readonly property bool shouldScroll: marqueeText.implicitWidth > implicitWidth
            property real scrollPos: 0

            Component.onCompleted: {
                if (shouldScroll)
                    marqueeAnim.restart();
            }

            NumberAnimation {
                id: marqueeAnim
                target: marqueeContainer
                property: "scrollPos"
                from: 0
                to: marqueeText.implicitWidth + 20
                duration: (marqueeText.implicitWidth + 20) * 1000 / Config.carouselSpeed
                loops: Animation.Infinite
            }

            Text {
                id: marqueeText
                anchors.verticalCenter: parent.verticalCenter
                x: marqueeContainer.shouldScroll ? -marqueeContainer.scrollPos : (marqueeContainer.width - implicitWidth) / 2
                color: Colors.md3.on_surface
                font.family: Config.fontFamily
                font.pixelSize: 14
                renderType: Text.NativeRendering
                text: {
                    const p = MediaPlayerState.displayPlayer;
                    if (!p)
                        return "nothing playing   ᓚ₍ ^. .^₎";
                    return p.trackTitle + "  •  " + p.trackArtist;
                }
                onTextChanged: {
                    if (marqueeContainer.shouldScroll)
                        marqueeAnim.restart();
                    else {
                        marqueeAnim.stop();
                        marqueeContainer.scrollPos = 0;
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                x: marqueeText.x + marqueeText.implicitWidth + 20
                visible: marqueeContainer.shouldScroll
                color: Colors.md3.on_surface
                font.family: Config.fontFamily
                font.pixelSize: 14
                renderType: Text.NativeRendering
                text: marqueeText.text
            }
        }
    }
}
