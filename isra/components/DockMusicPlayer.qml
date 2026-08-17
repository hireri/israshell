pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
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
    readonly property bool hasPlayer: root.player !== null
    readonly property bool isPlaying: root.player?.playbackState === MprisPlaybackState.Playing
    readonly property string artUrl: root.player?.trackArtUrl ?? ""

    function _matchesAppId(runningId, targetId) {
        if (!runningId || !targetId)
            return false;
        let r = runningId.toLowerCase();
        let t = targetId.toLowerCase();
        if (r === t)
            return true;
        if (r.endsWith("." + t))
            return true;
        if (r.endsWith(".desktop"))
            r = r.slice(0, -8);
        if (t.endsWith(".desktop"))
            t = t.slice(0, -8);
        return r === t;
    }

    readonly property string _entryId: {
        if (!root.player)
            return "";
        const de = (root.player.desktopEntry ?? "").trim();
        const entry = de !== "" ? DesktopEntries.heuristicLookup(de) : null;
        return entry?.id ?? de;
    }

    readonly property var _matchedToplevel: {
        if (root._entryId === "")
            return null;
        const list = ToplevelManager.toplevels?.values ?? [];
        for (const tl of list)
            if (root._matchesAppId(tl.appId, root._entryId))
                return tl;
        return null;
    }
    readonly property bool hasWindow: root._matchedToplevel !== null

    function focusMatchedWindow() {
        const tl = root._matchedToplevel;
        if (!tl)
            return;
        if (typeof tl.activate === "function")
            tl.activate();
        else if (tl.address !== undefined)
            CompositorService.focusWindow(tl.address);
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

    implicitWidth: isVertical ? cellSize : (hasPlayer ? horizontalExtent : 0)
    implicitHeight: isVertical ? (hasPlayer ? verticalExtent : 0) : cellSize
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
            ColorAnimation { duration: 400 }
        }
        visible: root.width > 0 && root.height > 0

        MouseArea {
            anchors.fill: parent
            enabled: root.hasWindow
            cursorShape: root.hasWindow ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: root.focusMatchedWindow()
        }

        component TransportButton: Item {
            id: btn
            width: root.controlBtn
            height: root.controlBtn

            property string icon: ""
            property bool iconFilled: false
            property bool btnEnabled: true
            signal tapped

            opacity: btnEnabled ? 1.0 : 0.4

            MaterialIcon {
                anchors.centerIn: parent
                name: btn.icon
                filled: btn.iconFilled
                iconSize: root.btnIconSize
                color: root.colOnSurface
            }

            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: btn.btnEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: if (btn.btnEnabled) btn.tapped()
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

            ClippingRectangle {
                id: cover
                width: root.cellSize - root.pad * 2
                height: width
                radius: 9
                color: Qt.alpha(root.colOnSurface, 0.1)
                Layout.alignment: Qt.AlignCenter

                Image {
                    anchors.fill: parent
                    source: root.artUrl
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(48, 48)
                    asynchronous: true
                    cache: true
                    opacity: status === Image.Ready && root.artUrl !== "" ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    name: "music-note"
                    iconSize: parent.width * 0.5
                    color: root.colOnSurfaceVariant
                    visible: root.artUrl === ""
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
                        width: parent.width
                        text: root.player?.trackTitle ?? ""
                        font.pixelSize: 10
                        font.family: Config.fontFamily
                        color: root.colOnSurface
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: root.player?.trackArtist ?? ""
                        font.pixelSize: 9
                        font.family: Config.fontFamily
                        color: root.colOnSurfaceVariant
                        elide: Text.ElideRight
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
                    onTapped: root.player?.togglePlaying()
                }

                TransportButton {
                    icon: "next-prev"
                    iconFilled: true
                    btnEnabled: root.player?.canGoNext ?? false
                    onTapped: root.player.next()
                }
            }
        }

        Rectangle {
            visible: root.hasWindow
            anchors.horizontalCenter: root.isVertical ? undefined : parent.horizontalCenter
            anchors.verticalCenter: root.isVertical ? parent.verticalCenter : undefined
            anchors.right: root.isVertical ? parent.right : undefined
            anchors.bottom: root.isVertical ? undefined : parent.bottom
            anchors.rightMargin: root.isVertical ? 1 : 0
            anchors.bottomMargin: root.isVertical ? 0 : 1
            width: root.isVertical ? 3 : 5
            height: root.isVertical ? 5 : 3
            radius: 1.5
            color: root.colOnSurfaceVariant
        }
    }
}