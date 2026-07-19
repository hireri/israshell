import QtQuick
import qs.style
import qs.services

Item {
    id: visualizer

    property bool pause: false
    property var renderValues: []

    property bool useMock: false
    property real mockTime: 0
    property real overrideMaxHeight: -1

    function lerpColor(c1, c2, t) {
        return Qt.rgba(
            c1.r + (c2.r - c1.r) * t,
            c1.g + (c2.g - c1.g) * t,
            c1.b + (c2.b - c1.b) * t,
            c1.a + (c2.a - c1.a) * t
        );
    }

    readonly property color cavaColor: {
        var colOpt = Config.cava.color || "primary";
        if (colOpt.indexOf("#") === 0 || colOpt.indexOf("rgb") === 0 || colOpt.indexOf("rgba") === 0) {
            return colOpt;
        }
        if (typeof Colors !== "undefined" && Colors.md3 && Colors.md3[colOpt]) {
            return Colors.md3[colOpt];
        }
        return "#3b82f6";
    }

    readonly property color cavaColorAlt: {
        var colOpt = Config.cava.colorAlt || "error";
        if (colOpt.indexOf("#") === 0 || colOpt.indexOf("rgb") === 0 || colOpt.indexOf("rgba") === 0) {
            return colOpt;
        }
        if (typeof Colors !== "undefined" && Colors.md3 && Colors.md3[colOpt]) {
            return Colors.md3[colOpt];
        }
        return "#ef4444";
    }

    function localRearrange(fakeSweep, layout) {
        if (!fakeSweep || fakeSweep.length < 2) return fakeSweep;
        let right = fakeSweep;
        let left = fakeSweep.slice().reverse();

        if (layout === "edges") {
            let leftMirrored = left.slice().reverse();
            let rightMirrored = right.slice().reverse();
            return leftMirrored.concat(rightMirrored);
        }
        if (layout === "mono") {
            let leftAligned = left.slice().reverse();
            let combined = [];
            for (let i = 0; i < right.length; i++) {
                combined.push((leftAligned[i] + right[i]) / 2);
            }
            return combined;
        }
        return left.concat(right);
    }

    Component.onCompleted: {
        if (CavaService.targetValues && CavaService.targetValues.length > 0) {
            renderValues = CavaService.targetValues.slice();
        }
    }

    Timer {
        id: smoothTimer
        interval: 16
        running: (Config.cava.enabled || visualizer.useMock) && visualizer.visible && !visualizer.pause
        repeat: true
        onTriggered: {
            let targets = CavaService.targetValues;

            if (visualizer.useMock) {
                visualizer.mockTime += 0.05;
                let numBars = Config.cava.bars || 30;
                let fakeTargets = [];
                for (let i = 0; i < numBars; i++) {
                    let t = visualizer.mockTime;
                    let wave1 = Math.sin(i * 0.3 + t * 2.0) * 25;
                    let wave2 = Math.cos(i * 0.15 - t * 1.2) * 20;
                    let wave3 = Math.sin(i * 0.05 + t * 0.5) * 15;
                    let heightVal = Math.max(5, 35 + wave1 + wave2 + wave3);
                    
                    let envelope = 1.0;
                    if (i < numBars * 0.2) {
                        envelope = 0.4 + 0.6 * (i / (numBars * 0.2));
                    } else {
                        envelope = 1.0 - 0.7 * ((i - numBars * 0.2) / (numBars * 0.8));
                    }
                    fakeTargets.push(Math.round(heightVal * envelope));
                }
                targets = visualizer.localRearrange(fakeTargets, Config.cava.layout);
            }

            if (!targets || targets.length === 0) return;

            let current = visualizer.renderValues;
            if (!current || current.length !== targets.length) {
                visualizer.renderValues = targets.slice();
                return;
            }

            const next = [];
            let changed = false;
            const easingFactor = 0.15;

            for (let i = 0; i < targets.length; i++) {
                const diff = targets[i] - current[i];
                if (Math.abs(diff) > 0.05) {
                    next.push(current[i] + (diff * easingFactor));
                    changed = true;
                } else {
                    next.push(targets[i]);
                }
            }

            if (changed) {
                visualizer.renderValues = next;
            }
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        renderTarget: Canvas.FramebufferObject
        renderStrategy: Canvas.Threaded

        onWidthChanged: canvas.requestPaint()
        onHeightChanged: canvas.requestPaint()

        onPaint: {
            const ctx = canvas.getContext("2d");
            ctx.clearRect(0, 0, width, height);

            const n = visualizer.renderValues.length;
            if ((!Config.cava.enabled && !visualizer.useMock) || n < 2) return;

            const colBase = visualizer.cavaColor;
            const colAlt = visualizer.cavaColorAlt;
            const isBottom = Config.cava.position === 1;
            const maxHeight = visualizer.overrideMaxHeight > 0 ? visualizer.overrideMaxHeight : Config.cava.height;

            const colorStyle = Config.cava.colorStyle;
            const renderType = Config.cava.renderType;

            let loudness = 0.0;

            if (colorStyle === "loudness") {
                let sum = 0;
                for (let i = 0; i < n; i++) sum += (visualizer.renderValues[i] || 0);
                const avg = n > 0 ? (sum / n) : 0;
                loudness = Math.min(1.0, Math.max(0.0, avg / 50.0));
            }

            if (renderType === "blocks") {
                const spacing = 4;
                const barWidth = (width - (spacing * (n - 1))) / n;
                const blockHeight = 6;
                const blockGap = 2;
                const maxBlocks = Math.floor(maxHeight / (blockHeight + blockGap));

                const activeBlocksList = [];
                const peaks = [];
                const xLefts = [];
                const xRights = [];

                for (let i = 0; i < n; i++) {
                    const pct = (visualizer.renderValues[i] || 0) / 100;
                    const hBar = pct * maxHeight;
                    const activeBlocks = Math.round(hBar / (blockHeight + blockGap));
                    activeBlocksList.push(activeBlocks);

                    const topOffset = activeBlocks > 0 ? ((activeBlocks - 1) * (blockHeight + blockGap) + blockHeight) : 0;
                    peaks.push(isBottom ? (height - topOffset) : topOffset);

                    const x = i * (barWidth + spacing);
                    xLefts.push(i === 0 ? 0 : (x - spacing / 2));
                    xRights.push(i === n - 1 ? width : (x + barWidth + spacing / 2));
                }

                if (Config.cava.drawFill) {
                    const gradVAlphaFalloff = 0.15;
                    const otherAlphaFalloff = 0.4;
                    let gradVPalette = null;
                    if (colorStyle === "gradient-v") {
                        gradVPalette = new Array(maxBlocks);
                        for (let b = 0; b < maxBlocks; b++) {
                            const c = lerpColor(colBase, colAlt, b / Math.max(1, maxBlocks - 1));
                            gradVPalette[b] = "rgb(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + ")";
                        }
                    }

                    for (let i = 0; i < n; i++) {
                        const activeBlocks = activeBlocksList[i];
                        if (activeBlocks <= 0) continue;
                        const x = i * (barWidth + spacing);
                        const barPct = (visualizer.renderValues[i] || 0) / 100;

                        let barColorStr = null;
                        if (colorStyle === "gradient-h") {
                            const c = lerpColor(colBase, colAlt, x / width);
                            barColorStr = "rgb(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + ")";
                        } else if (colorStyle === "loudness") {
                            const c = lerpColor(colBase, colAlt, barPct);
                            barColorStr = "rgb(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + ")";
                        } else if (colorStyle !== "gradient-v") {
                            barColorStr = "rgb(" + Math.round(colBase.r * 255) + "," + Math.round(colBase.g * 255) + "," + Math.round(colBase.b * 255) + ")";
                        }
                        if (barColorStr !== null) ctx.fillStyle = barColorStr;

                        const alphaFalloff = colorStyle === "gradient-v" ? gradVAlphaFalloff : otherAlphaFalloff;

                        for (let b = 0; b < activeBlocks; b++) {
                            const blockYOffset = b * (blockHeight + blockGap);
                            const y = isBottom ? (height - blockYOffset - blockHeight) : blockYOffset;

                            if (colorStyle === "gradient-v") {
                                ctx.fillStyle = gradVPalette[b];
                            }
                            ctx.globalAlpha = Config.cava.opacity * (1.0 - (b / maxBlocks) * alphaFalloff);
                            ctx.fillRect(x, y, barWidth, blockHeight);
                        }
                    }
                    ctx.globalAlpha = 1.0;
                }

                if (Config.cava.drawStroke) {
                    ctx.beginPath();
                    ctx.moveTo(xLefts[0], peaks[0]);
                    for (let i = 0; i < n; i++) {
                        ctx.lineTo(xRights[i], peaks[i]);
                        if (i < n - 1)
                            ctx.lineTo(xRights[i], peaks[i + 1]);
                    }

                    let strokeStyle;
                    if (colorStyle === "gradient-h") {
                        strokeStyle = ctx.createLinearGradient(0, 0, width, 0);
                        strokeStyle.addColorStop(0.0, Qt.rgba(colBase.r, colBase.g, colBase.b, Math.min(1.0, Config.cava.opacity * 2.5)));
                        strokeStyle.addColorStop(1.0, Qt.rgba(colAlt.r, colAlt.g, colAlt.b, Math.min(1.0, Config.cava.opacity * 2.5)));
                    } else {
                        let sCol = colBase;
                        if (colorStyle === "loudness") {
                            sCol = lerpColor(colBase, colAlt, loudness);
                        }
                        strokeStyle = Qt.rgba(sCol.r, sCol.g, sCol.b, Math.min(1.0, Config.cava.opacity * 2.5));
                    }

                    ctx.strokeStyle = strokeStyle;
                    ctx.lineWidth = 1.5;
                    ctx.stroke();
                }

                return;
            }

            if (renderType === "bars") {
                const spacing = 4;
                const barWidth = (width - (spacing * (n - 1))) / n;

                for (let i = 0; i < n; i++) {
                    const pct = (visualizer.renderValues[i] || 0) / 100;
                    const hBar = pct * maxHeight;
                    const x = i * (barWidth + spacing);
                    const y = isBottom ? (height - hBar) : 0;

                    const barBaseY = isBottom ? height : 0;
                    const barTipY = isBottom ? (height - hBar) : hBar;

                    let fillStyle = ctx.createLinearGradient(x, barBaseY, x, barTipY);

                    let startCol = colBase;
                    let endCol = colBase;
                    let tipAlpha = 0.0;

                    if (colorStyle === "solid") {
                        startCol = colBase;
                        endCol = colBase;
                    } else if (colorStyle === "loudness") {
                        const lCol = lerpColor(colBase, colAlt, pct);
                        startCol = lCol;
                        endCol = lCol;
                        tipAlpha = 0.0;
                    } else if (colorStyle === "gradient-v") {
                        startCol = colBase;
                        endCol = lerpColor(colBase, colAlt, pct);
                        tipAlpha = 0.0;
                    } else if (colorStyle === "gradient-h") {
                        const pctX = x / width;
                        const hCol = lerpColor(colBase, colAlt, pctX);
                        startCol = hCol;
                        endCol = hCol;
                    }

                    if (colorStyle === "gradient-v") {
                        const stopCount = 6;
                        for (let s = 0; s <= stopCount; s++) {
                            const p = s / stopCount;
                            const colorT = Math.min(1.0, p / 0.65);
                            const stopCol = lerpColor(startCol, endCol, colorT);
                            const alphaT = Math.pow(1.0 - p, 1.3);
                            const stopAlpha = tipAlpha + (Config.cava.opacity - tipAlpha) * alphaT;
                            fillStyle.addColorStop(p, Qt.rgba(stopCol.r, stopCol.g, stopCol.b, stopAlpha));
                        }
                    } else {
                        fillStyle.addColorStop(0.0, Qt.rgba(startCol.r, startCol.g, startCol.b, Config.cava.opacity));
                        fillStyle.addColorStop(1.0, Qt.rgba(endCol.r, endCol.g, endCol.b, tipAlpha));
                    }

                    if (Config.cava.drawFill) {
                        ctx.fillStyle = fillStyle;
                        ctx.fillRect(x, y, barWidth, hBar);
                    }

                    if (Config.cava.drawStroke) {
                        ctx.strokeStyle = Qt.rgba(endCol.r, endCol.g, endCol.b, Math.min(1.0, Config.cava.opacity * 2.5));
                        ctx.lineWidth = 1.0;
                        ctx.strokeRect(x, y, barWidth, hBar);
                    }
                }
                return;
            }

            if (renderType === "curve") {
                const pts = [];
                for (let i = 0; i < n; i++) {
                    const pct = (visualizer.renderValues[i] || 0) / 100;
                    pts.push({
                        x: (i / (n - 1)) * width,
                        y: isBottom ? (height - (pct * maxHeight)) : (pct * maxHeight)
                    });
                }

                const startY = isBottom ? height : 0;

                if (Config.cava.drawFill) {
                    ctx.beginPath();
                    ctx.moveTo(pts[0].x, pts[0].y);

                    if (Config.cava.curveType === "smooth") {
                        for (let i = 0; i < pts.length - 1; i++) {
                            const mx = (pts[i].x + pts[i + 1].x) / 2;
                            const my = (pts[i].y + pts[i + 1].y) / 2;
                            ctx.quadraticCurveTo(pts[i].x, pts[i].y, mx, my);
                        }
                        ctx.lineTo(pts[pts.length - 1].x, pts[pts.length - 1].y);
                    } else {
                        for (let i = 1; i < pts.length; i++) {
                            ctx.lineTo(pts[i].x, pts[i].y);
                        }
                    }

                    ctx.lineTo(width, startY);
                    ctx.lineTo(0, startY);
                    ctx.closePath();

                    let fillStyle;
                    if (colorStyle === "gradient-h") {
                        fillStyle = ctx.createLinearGradient(0, 0, width, 0);
                        fillStyle.addColorStop(0.0, Qt.rgba(colBase.r, colBase.g, colBase.b, Config.cava.opacity));
                        fillStyle.addColorStop(1.0, Qt.rgba(colAlt.r, colAlt.g, colAlt.b, Config.cava.opacity));
                    } else {
                        fillStyle = ctx.createLinearGradient(0, startY, 0, isBottom ? (height - maxHeight) : maxHeight);
                        let startCol = colBase;
                        let endCol = colAlt;
                        let tipAlpha = 0.0;

                        if (colorStyle === "solid") {
                            startCol = colBase;
                            endCol = colBase;
                        } else if (colorStyle === "gradient-v") {
                            startCol = colBase;
                            endCol = colAlt;
                            tipAlpha = Config.cava.opacity;
                        } else if (colorStyle === "loudness") {
                            startCol = colBase;
                            endCol = lerpColor(colBase, colAlt, loudness);
                            tipAlpha = Config.cava.opacity;
                        }

                        fillStyle.addColorStop(0.0, Qt.rgba(startCol.r, startCol.g, startCol.b, Config.cava.opacity));
                        fillStyle.addColorStop(1.0, Qt.rgba(endCol.r, endCol.g, endCol.b, tipAlpha));
                    }

                    ctx.fillStyle = fillStyle;
                    ctx.fill();
                }

                if (Config.cava.drawStroke) {
                    ctx.beginPath();
                    ctx.moveTo(pts[0].x, pts[0].y);

                    if (Config.cava.curveType === "smooth") {
                        for (let i = 0; i < pts.length - 1; i++) {
                            const mx = (pts[i].x + pts[i + 1].x) / 2;
                            const my = (pts[i].y + pts[i + 1].y) / 2;
                            ctx.quadraticCurveTo(pts[i].x, pts[i].y, mx, my);
                        }
                        ctx.lineTo(pts[pts.length - 1].x, pts[pts.length - 1].y);
                    } else {
                        for (let i = 1; i < pts.length; i++) {
                            ctx.lineTo(pts[i].x, pts[i].y);
                        }
                    }

                    let strokeStyle;
                    if (colorStyle === "gradient-h") {
                        strokeStyle = ctx.createLinearGradient(0, 0, width, 0);
                        strokeStyle.addColorStop(0.0, Qt.rgba(colBase.r, colBase.g, colBase.b, Math.min(1.0, Config.cava.opacity * 2.5)));
                        strokeStyle.addColorStop(1.0, Qt.rgba(colAlt.r, colAlt.g, colAlt.b, Math.min(1.0, Config.cava.opacity * 2.5)));
                    } else {
                        let sCol = colBase;
                        if (colorStyle === "gradient-v") {
                            sCol = colAlt;
                        } else if (colorStyle === "loudness") {
                            sCol = lerpColor(colBase, colAlt, loudness);
                        }
                        strokeStyle = Qt.rgba(sCol.r, sCol.g, sCol.b, Math.min(1.0, Config.cava.opacity * 2.5));
                    }

                    ctx.strokeStyle = strokeStyle;
                    ctx.lineWidth = 1.5;
                    ctx.stroke();
                }
            }
        }

        Connections {
            target: visualizer
            function onRenderValuesChanged() {
                canvas.requestPaint();
            }
        }

        Connections {
            target: Config
            function onCavaChanged() {
                canvas.requestPaint();
            }
        }
    }
}