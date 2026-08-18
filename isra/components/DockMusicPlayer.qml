pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import Quickshell.Services.Mpris

import qs.style
import qs.services
import qs.icons

Item {
    id: root

    required property Item dockRoot

    readonly property bool isVertical: dockRoot.orientation === 1
    readonly property int cellSize: dockRoot.itemCellSize ?? 28

    readonly property var player: MediaPlayerState.displayPlayer
    readonly property bool hasPlayer: !!root.player
    readonly property bool isPlaying: root.hasPlayer && root.player?.playbackState === MprisPlaybackState.Playing
    readonly property string artUrl: root.player?.trackArtUrl ?? ""

    function cyclePlayer() {
        const list = MediaPlayerState.players;
        if (list.length < 2)
            return;
        const cur = MediaPlayerState.displayPlayer;
        const idx = list.indexOf(cur);
        const next = list[(idx + 1) % list.length];

        MediaPlayerState.switchTo(next);
        MediaPlayerState.pin(next);
    }

    readonly property int pad: 4
    readonly property int trailPad: 8
    readonly property int groupGap: 6
    readonly property int btnGap: 0
    readonly property int btnIconSize: Math.round(cellSize * 0.4)
    readonly property int controlBtn: btnIconSize + 4
    readonly property int textWidth: 72

    readonly property int horizontalExtent: pad + trailPad + cellSize + groupGap + textWidth + groupGap + controlBtn * 2 + btnGap
    readonly property int verticalExtent: pad + trailPad + cellSize + groupGap + controlBtn * 2 + btnGap

    onArtUrlChanged: MediaPlayerState.ensureColors(artUrl)
    Component.onCompleted: MediaPlayerState.ensureColors(artUrl)

    readonly property var _dominantColor: MediaPlayerState.resolvedColor(artUrl)
    readonly property bool _darkMode: typeof Config.darkMode !== "undefined" ? Config.darkMode : true
    readonly property var _scheme: _dominantColor ? ColorUtils.m3CardScheme(_dominantColor, _darkMode) : null
    readonly property color cardColor: _scheme?.surfaceContainer ?? Colors.md3.surface_container_high
    readonly property color colOnSurface: _scheme?.onSurface ?? Colors.md3.on_surface
    readonly property color colOnSurfaceVariant: _scheme?.onSurfaceVariant ?? Colors.md3.on_surface_variant

    implicitWidth: isVertical ? cellSize : horizontalExtent
    implicitHeight: isVertical ? verticalExtent : cellSize
    width: implicitWidth
    height: implicitHeight
    clip: true

    Behavior on implicitWidth {
        enabled: !root.isVertical
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }
    Behavior on implicitHeight {
        enabled: root.isVertical
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    ClippingRectangle {
        id: card
        anchors.fill: parent
        radius: 12
        color: root.cardColor
        Behavior on color {
            ColorAnimation { duration: 400; easing.type: Easing.InOutQuad }
        }
        visible: root.width > 0 && root.height > 0

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            propagateComposedEvents: true
            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton && MediaPlayerState.players.length > 1) {
                    root.cyclePlayer();
                    mouse.accepted = true;
                } else {
                    mouse.accepted = false;
                }
            }
        }

        component TransportButton: Item {
            id: btn
            width: root.controlBtn
            height: root.controlBtn

            property string icon: ""
            property bool iconFilled: false
            property bool btnEnabled: true
            signal tapped

            opacity: btnEnabled ? 1.0 : 0.35
            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }

            MaterialIcon {
                anchors.centerIn: parent
                name: btn.icon
                filled: btn.iconFilled
                iconSize: root.btnIconSize
                color: root.colOnSurface
                Behavior on color { ColorAnimation { duration: 300 } }
            }

            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: btn.btnEnabled
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: btn.btnEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        if (MediaPlayerState.players.length > 1) {
                            root.cyclePlayer();
                        }
                    } else if (btn.btnEnabled) {
                        btn.tapped();
                    }
                }
            }
        }

        GridLayout {
            anchors.fill: parent
            anchors.leftMargin: root.pad
            anchors.topMargin: root.pad
            anchors.rightMargin: root.isVertical ? root.pad : root.trailPad
            anchors.bottomMargin: root.isVertical ? root.trailPad : root.pad
            columns: root.isVertical ? 1 : -1
            rows: root.isVertical ? -1 : 1
            columnSpacing: root.groupGap
            rowSpacing: root.groupGap

            Item {
                width: root.cellSize - root.pad * 2
                height: width
                Layout.alignment: Qt.AlignCenter

                CrossfadeArt {
                    id: cover
                    anchors.fill: parent
                    radius: 9
                    color: Qt.alpha(root.colOnSurface, 0.1)
                    url: root.artUrl
                    visible: root.hasPlayer
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 9
                    color: Qt.alpha(root.colOnSurface, 0.08)
                    visible: !root.hasPlayer

                    MaterialIcon {
                        anchors.centerIn: parent
                        name: "music-note"
                        iconSize: Math.round(parent.width * 0.5)
                        color: Qt.alpha(root.colOnSurface, 0.4)
                    }
                }
            }

            Item {
                id: textCol
                visible: !root.isVertical
                Layout.preferredWidth: root.textWidth
                Layout.fillHeight: true

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    spacing: 1

                    Text {
                        id: titleText
                        width: parent.width
                        text: root.hasPlayer 
                            ? (root.player?.trackTitle || Localization.t("mediaPlayer.unknown_track")) 
                            : Localization.t("mediaPlayer.no_media_playing")
                        font.pixelSize: 10
                        font.weight: root.hasPlayer ? Font.Medium : Font.Normal
                        font.family: Config.fontFamily
                        color: root.hasPlayer ? root.colOnSurface : Qt.alpha(root.colOnSurface, 0.6)
                        elide: Text.ElideRight

                        Behavior on text {
                            SequentialAnimation {
                                NumberAnimation { target: titleText; property: "opacity"; to: 0; duration: 100 }
                                PropertyAction { target: titleText; property: "text" }
                                NumberAnimation { target: titleText; property: "opacity"; to: 1; duration: 150 }
                            }
                        }
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }

                    Text {
                        id: artistText
                        width: parent.width
                        text: root.hasPlayer 
                            ? (root.player?.trackArtist || Localization.t("mediaPlayer.unknown_artist")) 
                            : Localization.t("mediaPlayer.no_players")
                        font.pixelSize: 9
                        font.family: Config.fontFamily
                        color: root.hasPlayer ? root.colOnSurfaceVariant : Qt.alpha(root.colOnSurfaceVariant, 0.4)
                        elide: Text.ElideRight

                        Behavior on text {
                            SequentialAnimation {
                                NumberAnimation { target: artistText; property: "opacity"; to: 0; duration: 100 }
                                PropertyAction { target: artistText; property: "text" }
                                NumberAnimation { target: artistText; property: "opacity"; to: 1; duration: 150 }
                            }
                        }
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }
                }
            }

            Grid {
                Layout.alignment: Qt.AlignCenter
                columns: root.isVertical ? 1 : 2
                rows: root.isVertical ? 2 : 1
                spacing: root.btnGap

                TransportButton {
                    icon: "play-pause"
                    iconFilled: root.isPlaying
                    btnEnabled: root.hasPlayer
                    onTapped: root.player?.togglePlaying()
                }

                TransportButton {
                    icon: "next-prev"
                    iconFilled: true
                    btnEnabled: root.hasPlayer && (root.player?.canGoNext ?? false)
                    onTapped: root.player?.next()
                }
            }
        }

        Row {
            visible: MediaPlayerState.players.length > 0 && !root.isVertical
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 1
            spacing: 3

            Repeater {
                model: MediaPlayerState.players

                delegate: Rectangle {
                    required property var modelData
                    readonly property bool isCurrent: modelData === MediaPlayerState.displayPlayer
                    width: isCurrent ? 5 : 3
                    height: 3
                    radius: 1.5
                    color: isCurrent ? root.colOnSurface : root.colOnSurfaceVariant

                    Behavior on width {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }
                }
            }
        }

        Column {
            visible: MediaPlayerState.players.length > 0 && root.isVertical
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 1
            spacing: 3

            Repeater {
                model: MediaPlayerState.players

                delegate: Rectangle {
                    required property var modelData
                    readonly property bool isCurrent: modelData === MediaPlayerState.displayPlayer
                    width: 3
                    height: isCurrent ? 5 : 3
                    radius: 1.5
                    color: isCurrent ? root.colOnSurface : root.colOnSurfaceVariant

                    Behavior on height {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }
                }
            }
        }
    }
}