pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.style
import qs.services

Item {
    id: root

    property bool showCard: true
    property bool showTrackInfo: true
    property real artSize: 36
    property string align: "left"
    property real idleBlur: 0

    property string fontFamily: "Google Sans Flex"
    property real idleWeight: 380
    property real activeWeight: 620
    property real activeGrad: 70
    property real fontWidth: 100
    property real fontRoundness: 0
    property int lyricSize: 20

    property bool wordMode: true
    property int lineDuration: 620
    property int wordDuration: 260
    property int leadIn: 120
    property real activeScale: 1.04

    readonly property bool isFlex: root.fontFamily === "Google Sans Flex"
    readonly property int pad: 16

    readonly property int window: 4

    readonly property var lines: LyricsService.lines
    readonly property int idx: LyricsService.activeIndex

    readonly property color textColor: Colors.md3.on_surface
    readonly property color dimColor: Colors.md3.on_surface_variant

    readonly property color shadowColor: root.showCard ? "transparent" : Qt.alpha("black", 0.55)

    readonly property int hAlign: root.align === "right" ? Text.AlignRight : root.align === "center" ? Text.AlignHCenter : Text.AlignLeft

    readonly property string artUrl: LyricsService.player?.trackArtUrl ?? ""
    onArtUrlChanged: MediaPlayerState.ensureArt(root.artUrl)

    function qz(value, step) {
        return Math.round(value / step) * step;
    }

    function axes(weight, grad) {
        return {
            "wght": root.qz(weight, 20),
            "GRAD": root.qz(grad, 10),
            "wdth": root.fontWidth,
            "ROND": root.fontRoundness
        };
    }

    readonly property int axisSteps: 8

    function axesAt(t) {
        const q = Math.round(Math.max(0, Math.min(1, t)) * root.axisSteps) / root.axisSteps;
        return {
            "wght": Math.round(root.idleWeight + (root.activeWeight - root.idleWeight) * q),
            "GRAD": Math.round(root.activeGrad * q),
            "wdth": root.fontWidth,
            "ROND": root.fontRoundness
        };
    }

    property real nowSec: 0

    FrameAnimation {
        running: root.visible && root.wordMode && LyricsService.hasLyrics && root.idx >= 0
        onTriggered: root.nowSec = LyricsService.position()
    }

    Rectangle {
        id: card
        anchors.fill: parent
        visible: root.showCard
        radius: 22
        color: Config.desktopWidgetsBlurActive ? Config.dim(Colors.md3.surface_container_high) : Colors.md3.surface_container_high
        border.width: 1
        border.color: Qt.alpha(Colors.md3.outline, 0.5)

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: !Config.desktopWidgetsBlurActive
            shadowBlur: 0.5
            shadowColor: Qt.alpha("black", 0.2)
            shadowVerticalOffset: 4
        }
    }

    Item {
        id: meta

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.pad

        visible: root.showTrackInfo
        height: visible ? Math.max(root.artSize, metaText.implicitHeight) : 0

        CrossfadeArt {
            id: art

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            width: root.artSize
            height: root.artSize
            radius: Math.round(root.artSize / 4.5)
            visible: root.artSize > 0
            color: Qt.alpha(root.textColor, 0.1)
            url: MediaPlayerState.resolvedArt(root.artUrl)
        }

        Column {
            id: metaText

            anchors.left: art.visible ? art.right : parent.left
            anchors.leftMargin: art.visible ? 12 : 0
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                width: parent.width
                elide: Text.ElideRight
                horizontalAlignment: root.hAlign
                color: root.textColor
                text: LyricsService.player?.trackTitle ?? Localization.t("mediaPlayer.unknown_track")

                font.family: root.fontFamily
                font.pixelSize: 14
                font.weight: root.isFlex ? Font.Normal : Font.DemiBold
                font.variableAxes: root.isFlex ? root.axes(600, 0) : ({})

                style: root.showCard ? Text.Normal : Text.Raised
                styleColor: root.shadowColor
            }

            Text {
                width: parent.width
                elide: Text.ElideRight
                horizontalAlignment: root.hAlign
                color: root.dimColor
                text: LyricsService.player?.trackArtist ?? Localization.t("mediaPlayer.unknown_artist")

                font.family: root.fontFamily
                font.pixelSize: 12
                font.variableAxes: root.isFlex ? root.axes(420, 0) : ({})

                style: root.showCard ? Text.Normal : Text.Raised
                styleColor: root.shadowColor
            }
        }
    }

    Item {
        id: viewport

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: meta.visible ? meta.bottom : parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.pad
        anchors.rightMargin: root.pad
        anchors.topMargin: meta.visible ? 14 : root.pad
        anchors.bottomMargin: root.pad

        clip: true

        Text {
            anchors.centerIn: parent
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            visible: !LyricsService.hasLyrics
            color: root.dimColor
            font.family: root.fontFamily
            font.pixelSize: 13
            style: root.showCard ? Text.Normal : Text.Raised
            styleColor: root.shadowColor

            text: {
                switch (LyricsService.status) {
                case "loading":
                    return Localization.t("lyrics.loading");
                case "not_found":
                    return Localization.t("lyrics.not_found");
                case "no_info":
                    return Localization.t("lyrics.no_track");
                case "offline":
                    return Localization.t("lyrics.offline");
                case "error":
                    return Localization.t("lyrics.error");
                default:
                    return Localization.t("lyrics.no_track");
                }
            }
        }

        Item {
            id: track

            anchors.left: parent.left
            anchors.right: parent.right
            visible: LyricsService.hasLyrics

            readonly property int spacing: 10

            FontMetrics {
                id: fm
                font.family: root.fontFamily
                font.pixelSize: root.lyricSize
            }

            TextMetrics {
                id: measure
                font.family: root.fontFamily
                font.pixelSize: root.lyricSize
            }

            readonly property real lineH: Math.ceil(fm.height)

            property var layout: []
            property var offsets: []

            function relayout(): void {
                const avail = track.width;
                const rowsPerLine = [];
                const tops = [];
                let cursor = 0;

                if (avail <= 0) {
                    track.layout = [];
                    track.offsets = [];
                    return;
                }

                for (const line of root.lines) {
                    const rows = [];
                    let current = [];
                    let width = 0;
                    for (const word of line.words ?? []) {
                        measure.text = word.text;
                        const w = measure.advanceWidth;
                        if (current.length > 0 && width + w > avail) {
                            rows.push(current);
                            current = [];
                            width = 0;
                        }
                        current.push(word);
                        width += w;
                    }
                    if (current.length > 0)
                        rows.push(current);
                    if (rows.length === 0)
                        rows.push([]);

                    rowsPerLine.push(rows);
                    tops.push(cursor);
                    cursor += rows.length * track.lineH + track.spacing;
                }

                track.layout = rowsPerLine;
                track.offsets = tops;
            }

            onWidthChanged: relayout()
            onLineHChanged: relayout()
            Component.onCompleted: relayout()

            Connections {
                target: root
                function onLinesChanged(): void {
                    track.relayout();
                }
                function onFontFamilyChanged(): void {
                    track.relayout();
                }
            }

            Repeater {
                id: lineRepeater

                model: root.lines

                delegate: Item {
                    id: line

                    required property int index
                    required property var modelData

                    readonly property int offset: line.index - root.idx
                    readonly property bool isActive: line.offset === 0
                    readonly property bool isSung: line.offset < 0
                    readonly property bool nearby: Math.abs(line.offset) <= root.window

                    readonly property var rows: track.layout[line.index] ?? []

                    readonly property real lineNow: line.isActive ? root.nowSec : 0

                    readonly property int lineAlign: line.modelData.align === "left" ? Text.AlignLeft : line.modelData.align === "right" ? Text.AlignRight : root.hAlign

                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: Math.max(1, line.rows.length) * track.lineH

                    visible: line.nearby && line.rows.length > 0

                    y: {
                        const tops = track.offsets;
                        if (tops.length === 0)
                            return 0;
                        const mine = tops[line.index] ?? 0;
                        const active = tops[Math.max(0, Math.min(tops.length - 1, root.idx))] ?? 0;
                        const activeH = Math.max(1, (track.layout[Math.max(0, root.idx)] ?? []).length) * track.lineH;
                        return viewport.height / 2 - activeH / 2 + (mine - active);
                    }

                    Behavior on y {
                        NumberAnimation {
                            duration: root.lineDuration
                            easing.type: Easing.OutExpo
                        }
                    }

                    readonly property real edgeFade: {
                        const half = Math.max(1, viewport.height / 2);
                        const d = Math.min(1, Math.abs(line.y + line.height / 2 - half) / half);
                        return Math.max(0, 1 - d * d);
                    }

                    opacity: line.isActive ? 1 : line.edgeFade * (line.isSung ? 0.42 : 0.55)

                    layer.enabled: root.idleBlur > 0 && !line.isActive
                    layer.effect: MultiEffect {
                        blurEnabled: true
                        blur: Math.min(1, root.idleBlur / 32)
                        blurMax: 32
                    }

                    property real lineT: line.isActive && !root.wordMode ? 1 : 0

                    Behavior on lineT {
                        NumberAnimation {
                            duration: root.lineDuration
                            easing.type: Easing.OutExpo
                        }
                    }

                    Column {
                        id: rowStack

                        width: parent.width
                        spacing: 0

                        scale: line.isActive ? root.activeScale : 1
                        transformOrigin: line.lineAlign === Text.AlignRight ? Item.Right : line.lineAlign === Text.AlignHCenter ? Item.Center : Item.Left

                        Behavior on scale {
                            NumberAnimation {
                                duration: root.lineDuration
                                easing.type: Easing.OutExpo
                            }
                        }

                        Repeater {
                            model: line.nearby ? line.rows : []

                            delegate: Row {
                                id: wordRow

                                required property var modelData

                                height: track.lineH
                                spacing: 0

                                x: line.lineAlign === Text.AlignRight ? rowStack.width - width : line.lineAlign === Text.AlignHCenter ? (rowStack.width - width) / 2 : 0

                                Repeater {
                                    model: wordRow.modelData

                                    delegate: Text {
                                        id: word

                                        required property var modelData

                                        readonly property real p: {
                                            if (!root.wordMode || !line.isActive)
                                                return 0;
                                            const dur = Math.max(1, root.wordDuration) / 1000;
                                            const up = Math.max(0, Math.min(1, (line.lineNow - (word.modelData.start - root.leadIn / 1000)) / dur));
                                            const down = Math.max(0, Math.min(1, (line.lineNow - word.modelData.end) / (dur * 2.2)));
                                            const ease = x => 1 - Math.pow(1 - x, 3);
                                            return ease(up) * (1 - ease(down) * 0.62);
                                        }

                                        text: word.modelData.text
                                        color: root.textColor
                                        opacity: root.wordMode && line.isActive ? 0.42 + 0.58 * word.p : 1

                                        font.family: root.fontFamily
                                        font.pixelSize: root.lyricSize
                                        font.weight: root.isFlex ? Font.Normal : (line.isActive ? Font.DemiBold : Font.Normal)
                                        font.variableAxes: {
                                            if (!root.isFlex)
                                                return ({});
                                            return root.axesAt(root.wordMode && line.isActive ? word.p : line.lineT);
                                        }

                                        style: root.showCard ? Text.Normal : Text.Raised
                                        styleColor: root.shadowColor
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        LyricsService.subscribe();
        MediaPlayerState.ensureArt(root.artUrl);
    }
    Component.onDestruction: LyricsService.unsubscribe()
}
