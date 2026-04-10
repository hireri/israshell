import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import QtQuick

import qs.style

Rectangle {
    color: Config.transparentBar ? Qt.alpha(Colors.md3.surface_container_high, 0.8) : Colors.md3.surface_container_high
    radius: 18
    implicitWidth: 240
    height: 32

    function activePlayer() {
        for (const p of Mpris.players.values) {
            if (p.trackTitle && p.trackTitle !== "")
                return p;
        }
        return null;
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton | Qt.MiddleButton

        onClicked: mouse => {
            const player = activePlayer();
            if (!player)
                return;
            if (mouse.button === Qt.RightButton)
                player.next();
            if (mouse.button === Qt.MiddleButton)
                player.playbackState === MprisPlaybackState.Playing ? player.pause() : player.play();
        }

        onWheel: wheel => {
            const player = activePlayer();
            if (!player)
                return;
            player.volume = Math.max(0, Math.min(1, player.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)));
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 8

        Item {
            id: coverRoot
            implicitWidth: 24
            height: 24
            anchors.verticalCenter: parent.verticalCenter

            property bool hasPlayer: false
            property bool isPlaying: false
            property bool shouldSpin: Config.spinningCover && hasPlayer && isPlaying

            Timer {
                interval: 100
                running: true
                repeat: true
                onTriggered: {
                    const player = activePlayer();
                    coverRoot.hasPlayer = !!player;
                    coverRoot.isPlaying = player?.playbackState === MprisPlaybackState.Playing;
                }
            }

            ClippingRectangle {
                anchors.fill: parent
                radius: 30
                color: Colors.md3.surface_container_highest

                Text {
                    anchors.centerIn: parent
                    text: "♪"
                    color: Colors.md3.on_surface_variant
                    font.pixelSize: 14
                    font.family: Config.fontFamily
                }
            }

            ClippingRectangle {
                id: rotatingCover
                anchors.fill: parent
                radius: 30
                visible: albumArt.status === Image.Ready
                color: "transparent"
                clip: true
                layer.enabled: true
                layer.smooth: true
                antialiasing: true

                property real rotationAngle: 0
                property real rotationVelocity: coverRoot.shouldSpin ? 0.5 : 0
                rotation: rotationAngle

                Behavior on rotationVelocity {
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.OutCubic
                    }
                }

                Timer {
                    interval: 16
                    running: rotatingCover.visible
                    repeat: true
                    onTriggered: {
                        if (Math.abs(rotatingCover.rotationVelocity) > 0.001)
                            rotatingCover.rotationAngle = (rotatingCover.rotationAngle + rotatingCover.rotationVelocity) % 360;
                    }
                }

                Image {
                    id: albumArt
                    anchors.fill: parent
                    source: activePlayer()?.trackArtUrl ?? ""
                    antialiasing: true
                    smooth: true
                }
            }
        }

        Item {
            id: mediaTextContainer
            implicitWidth: 200
            height: 20
            clip: true
            anchors.verticalCenter: parent.verticalCenter

            property bool shouldScroll: mediaText.implicitWidth > implicitWidth
            property real scrollPos: 0

            NumberAnimation {
                id: scrollAnim
                target: mediaTextContainer
                property: "scrollPos"
                from: 0
                to: mediaText.implicitWidth + 20
                duration: (mediaText.implicitWidth + 20) * 1000 / Config.carouselSpeed
                loops: Animation.Infinite
            }

            Text {
                id: mediaText
                anchors.verticalCenter: parent.verticalCenter
                x: mediaTextContainer.shouldScroll ? -mediaTextContainer.scrollPos : (mediaTextContainer.width - implicitWidth) / 2
                color: Colors.md3.on_surface
                font.family: Config.fontFamily
                font.pixelSize: 14
                text: {
                    const player = activePlayer();
                    if (!player)
                        return "nothing playing   ᓚ₍ ^. .^₎";
                    return player.trackTitle + "  •  " + player.trackArtist;
                }

                onTextChanged: {
                    if (mediaTextContainer.shouldScroll)
                        scrollAnim.restart();
                    else {
                        scrollAnim.stop();
                        mediaTextContainer.scrollPos = 0;
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                x: mediaText.x + mediaText.implicitWidth + 20
                visible: mediaTextContainer.shouldScroll
                color: Colors.md3.on_surface
                font.family: Config.fontFamily
                font.pixelSize: 14
                text: mediaText.text
            }

            Rectangle {
                anchors.left: parent.left
                implicitWidth: 20
                height: parent.height
                visible: mediaTextContainer.shouldScroll
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0.0
                        color: Colors.md3.surface_container_high
                    }
                    GradientStop {
                        position: 1.0
                        color: "transparent"
                    }
                }
            }

            Rectangle {
                anchors.right: parent.right
                implicitWidth: 20
                height: parent.height
                visible: mediaTextContainer.shouldScroll
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0.0
                        color: "transparent"
                    }
                    GradientStop {
                        position: 1.0
                        color: Colors.md3.surface_container_high
                    }
                }
            }
        }
    }
}
