import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs.style
import qs.services
import qs.icons

Item {
    id: root

    function _mmss(ms) {
        const totalSec = Math.max(0, Math.round(ms / 1000));
        const m = Math.floor(totalSec / 60);
        const s = totalSec % 60;
        return m + ":" + String(s).padStart(2, "0");
    }

    readonly property int cycleIndex: PomodoroService.cycleIndex
    readonly property int cycleTotal: PomodoroService.cycleTotal

    readonly property string _phaseLabel: {
        switch (PomodoroService.stepType) {
        case "short_break":
            return Localization.t("pomodoro.short_break");
        case "long_break":
            return Localization.t("pomodoro.long_break");
        default:
            return Localization.t("pomodoro.focus");
        }
    }
    readonly property string _cycleStr: root.cycleIndex + " " + Localization.t("pomodoro.of") + " " + root.cycleTotal

    readonly property real _pad: Math.max(8, root.height * 0.045)
    readonly property real _gap: Math.max(8, root.height * 0.045)
    readonly property real _controlsH: Math.max(28, root.height * 0.2)
    readonly property real _innerW: Math.max(0, root.width - root._pad * 2)
    readonly property real _ringH: Math.max(1, root.height - root._pad * 2 - root._gap - root._controlsH)
    readonly property bool _isWide: root._innerW > root._ringH * 1.2
    readonly property rect _ringBox: Qt.rect(root._pad, root._pad, root._innerW, root._ringH)
    readonly property real _controlsY: root._pad + root._ringH + root._gap

    readonly property real _strokeW: Math.max(4, root._ringH * 0.055)
    readonly property rect _rb: Qt.rect(root._ringBox.x + root._strokeW / 2, root._ringBox.y + root._strokeW / 2, Math.max(1, root._ringBox.width - root._strokeW), Math.max(1, root._ringBox.height - root._strokeW))
    readonly property real _dotRadius: Math.max(3, root._strokeW * 0.62)
    readonly property real _ringRx: root._rb.height / 2

    readonly property real _controlUnit: root._controlsH
    readonly property real _controlGap: Math.max(4, root._controlUnit * 0.14)
    readonly property real _primaryW: Math.max(root._controlUnit * 1.4, root.height * 0.42)
    readonly property real _secondaryMin: root._controlUnit * 0.62

    function _ringSegments(box, rxIn) {
        const rx = Math.max(0, Math.min(rxIn, box.width / 2, box.height / 2));
        const cx = box.x + box.width / 2;
        const halfTop = Math.max(0, box.width / 2 - rx);
        const vertSide = Math.max(0, box.height - 2 * rx);
        const bottomLen = Math.max(0, box.width - 2 * rx);
        const quarter = rx * Math.PI / 2;
        return [
            { kind: "line", x1: cx, y1: box.y, x2: box.x + box.width - rx, y2: box.y, len: halfTop },
            { kind: "arc", cx: box.x + box.width - rx, cy: box.y + rx, r: rx, a1: -Math.PI / 2, a2: 0, len: quarter },
            { kind: "line", x1: box.x + box.width, y1: box.y + rx, x2: box.x + box.width, y2: box.y + box.height - rx, len: vertSide },
            { kind: "arc", cx: box.x + box.width - rx, cy: box.y + box.height - rx, r: rx, a1: 0, a2: Math.PI / 2, len: quarter },
            { kind: "line", x1: box.x + box.width - rx, y1: box.y + box.height, x2: box.x + rx, y2: box.y + box.height, len: bottomLen },
            { kind: "arc", cx: box.x + rx, cy: box.y + box.height - rx, r: rx, a1: Math.PI / 2, a2: Math.PI, len: quarter },
            { kind: "line", x1: box.x, y1: box.y + box.height - rx, x2: box.x, y2: box.y + rx, len: vertSide },
            { kind: "arc", cx: box.x + rx, cy: box.y + rx, r: rx, a1: Math.PI, a2: Math.PI * 1.5, len: quarter },
            { kind: "line", x1: box.x + rx, y1: box.y, x2: cx, y2: box.y, len: halfTop }
        ];
    }

    function _ringTotalLen(box, rxIn) {
        const rx = Math.max(0, Math.min(rxIn, box.width / 2, box.height / 2));
        return 2 * Math.max(0, box.width - 2 * rx) + 2 * Math.max(0, box.height - 2 * rx) + 2 * Math.PI * rx;
    }

    function _pointAtLength(segs, total, len) {
        if (total <= 0)
            return { x: 0, y: 0 };
        let L = ((len % total) + total) % total;
        for (let i = 0; i < segs.length; i++) {
            const s = segs[i];
            if (L <= s.len || i === segs.length - 1) {
                const t = s.len > 0 ? Math.min(1, L / s.len) : 0;
                if (s.kind === "line")
                    return { x: s.x1 + (s.x2 - s.x1) * t, y: s.y1 + (s.y2 - s.y1) * t };
                const a = s.a1 + (s.a2 - s.a1) * t;
                return { x: s.cx + Math.cos(a) * s.r, y: s.cy + Math.sin(a) * s.r };
            }
            L -= s.len;
        }
        return { x: 0, y: 0 };
    }

    function _drawRingPath(ctx, segs, fromLen, toLen) {
        let acc = 0;
        let started = false;
        for (let i = 0; i < segs.length; i++) {
            const s = segs[i];
            const segStart = acc;
            const segEnd = acc + s.len;
            acc = segEnd;
            if (toLen <= segStart)
                break;
            if (fromLen >= segEnd)
                continue;
            const df = Math.max(fromLen, segStart) - segStart;
            const dt = Math.min(toLen, segEnd) - segStart;
            const t0 = s.len > 0 ? df / s.len : 0;
            const t1 = s.len > 0 ? dt / s.len : 1;
            if (s.kind === "line") {
                const p0x = s.x1 + (s.x2 - s.x1) * t0, p0y = s.y1 + (s.y2 - s.y1) * t0;
                const p1x = s.x1 + (s.x2 - s.x1) * t1, p1y = s.y1 + (s.y2 - s.y1) * t1;
                if (!started) { ctx.moveTo(p0x, p0y); started = true; }
                ctx.lineTo(p1x, p1y);
            } else {
                const a0 = s.a1 + (s.a2 - s.a1) * t0;
                const a1v = s.a1 + (s.a2 - s.a1) * t1;
                if (!started) { ctx.moveTo(s.cx + Math.cos(a0) * s.r, s.cy + Math.sin(a0) * s.r); started = true; }
                ctx.arc(s.cx, s.cy, s.r, a0, a1v, false);
            }
        }
    }

    readonly property var _dotPoint: {
        const segs = root._ringSegments(root._rb, root._ringRx);
        const total = root._ringTotalLen(root._rb, root._ringRx);
        return root._pointAtLength(segs, total, PomodoroService.progress * total);
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Math.min(20, Math.min(root.width, root.height) * 0.2)
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

    Canvas {
        id: ringCanvas
        anchors.fill: parent
        renderTarget: Canvas.FramebufferObject

        property rect box: root._rb
        property real rx: root._ringRx
        property real strokeW: root._strokeW
        property color trackColor: Qt.alpha(Colors.md3.primary, 0.16)
        property color fillColor: Colors.md3.primary
        property real prog: PomodoroService.progress

        onBoxChanged: requestPaint()
        onRxChanged: requestPaint()
        onStrokeWChanged: requestPaint()
        onTrackColorChanged: requestPaint()
        onFillColorChanged: requestPaint()
        onProgChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const segs = root._ringSegments(box, rx);
            const total = root._ringTotalLen(box, rx);

            ctx.lineCap = "round";
            ctx.lineWidth = strokeW;

            ctx.strokeStyle = trackColor;
            ctx.beginPath();
            root._drawRingPath(ctx, segs, 0, total);
            ctx.stroke();

            if (prog > 0.001) {
                ctx.strokeStyle = fillColor;
                ctx.beginPath();
                root._drawRingPath(ctx, segs, 0, prog * total);
                ctx.stroke();
            }
        }
    }

    Item {
        id: ringFrame
        x: root._ringBox.x
        y: root._ringBox.y
        width: root._ringBox.width
        height: root._ringBox.height

        Column {
            anchors.centerIn: parent
            spacing: Math.max(2, root._ringH * 0.03)

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root._mmss(PomodoroService.remainingMs)
                font.family: Config.fontFamily
                font.pixelSize: Math.max(13, root._ringH * 0.32)
                font.weight: Font.Bold
                font.letterSpacing: -0.5
                color: Colors.md3.on_surface
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Math.max(3, root._ringH * 0.025)

                Text {
                    visible: root._isWide
                    text: root._phaseLabel
                    font.family: Config.fontFamily
                    font.pixelSize: Math.max(9, root._ringH * 0.32 * 0.34)
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.2
                    color: Colors.md3.primary
                }

                Text {
                    visible: root._isWide
                    text: "·"
                    font.family: Config.fontFamily
                    font.pixelSize: Math.max(9, root._ringH * 0.32 * 0.34)
                    font.weight: Font.Medium
                    color: Colors.md3.on_surface_variant
                }

                Text {
                    text: root._cycleStr
                    font.family: Config.fontFamily
                    font.pixelSize: Math.max(9, root._ringH * 0.32 * 0.34)
                    font.weight: Font.Medium
                    color: Colors.md3.on_surface_variant
                }
            }
        }
    }

    Item {
        id: controls

        readonly property real neededW: root._primaryW + root._controlGap * 2 + root._secondaryMin * 2
        readonly property real scale: Math.min(1, root._innerW / Math.max(1, neededW))
        readonly property real primaryW: root._primaryW * scale
        readonly property real gap: root._controlGap * scale
        readonly property real secondaryEach: Math.max(0, (root._innerW - primaryW - gap * 2) / 2)
        readonly property real totalW: primaryW + gap * 2 + secondaryEach * 2

        x: root._pad + (root._innerW - totalW) / 2
        y: root._controlsY
        width: totalW
        height: root._controlUnit

        Rectangle {
            x: 0
            y: 0
            width: controls.primaryW
            height: controls.height
            radius: PomodoroService.running ? height * 0.32 : height / 2
            color: PomodoroService.running ? Colors.md3.primary : Colors.md3.surface_container_highest

            Behavior on radius {
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
            }
            Behavior on color {
                ColorAnimation { duration: 160; easing.type: Easing.OutCubic }
            }

            MaterialIcon {
                anchors.centerIn: parent
                name: "play-pause"
                filled: PomodoroService.running
                iconSize: parent.height * 0.5
                color: PomodoroService.running ? Colors.md3.on_primary : Colors.md3.on_surface_variant
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: PomodoroService.toggle()
            }
        }

        Rectangle {
            x: controls.primaryW + controls.gap
            y: 0
            width: controls.secondaryEach
            height: controls.height
            topLeftRadius: Math.min(width, height) / 2
            bottomLeftRadius: Math.min(width, height) / 2
            topRightRadius: Math.min(width, height) * 0.25
            bottomRightRadius: Math.min(width, height) * 0.25
            color: Colors.md3.surface_container_highest

            MaterialIcon {
                anchors.centerIn: parent
                name: "restart"
                iconSize: Math.min(parent.width, parent.height) * 0.46
                color: Colors.md3.on_surface_variant
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: PomodoroService.restart()
            }
        }

        Rectangle {
            x: controls.primaryW + controls.gap * 2 + controls.secondaryEach
            y: 0
            width: controls.secondaryEach
            height: controls.height
            topLeftRadius: Math.min(width, height) * 0.2
            bottomLeftRadius: Math.min(width, height) * 0.2
            topRightRadius: Math.min(width, height) / 2
            bottomRightRadius: Math.min(width, height) / 2
            color: Colors.md3.surface_container_highest

            MaterialIcon {
                anchors.centerIn: parent
                name: "next-prev"
                rotation: 180
                iconSize: Math.min(parent.width, parent.height) * 0.6
                color: Colors.md3.on_surface_variant
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: PomodoroService.skip()
            }
        }
    }
}
