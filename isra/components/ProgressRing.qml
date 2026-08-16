import QtQuick
import qs.style

Canvas {
    id: root

    property real progress: 0
    property real strokeWidth: 3
    property color activeColor: Colors.md3.primary
    property color trackColor: Qt.alpha(Colors.md3.primary, 0.25)

    property real gapDegrees: 15

    readonly property real _pMin: 0.03
    readonly property real _minArcAngle: 0.04

    antialiasing: true

    onProgressChanged: root.requestPaint()
    onStrokeWidthChanged: root.requestPaint()
    onActiveColorChanged: root.requestPaint()
    onTrackColorChanged: root.requestPaint()
    onGapDegreesChanged: root.requestPaint()
    onWidthChanged: root.requestPaint()
    onHeightChanged: root.requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();

        const sw = root.strokeWidth;
        if (sw <= 0.01)
            return;

        const centerX = width / 2;
        const centerY = height / 2;
        const radius = (Math.min(width, height) - sw) / 2;
        if (radius <= 0)
            return;

        const topAngle = -Math.PI / 2;
        const fullGap = root.gapDegrees * (Math.PI / 180);
        const halfFullGap = fullGap / 2;

        const p = Math.max(0, Math.min(1, root.progress));
        const pMin = root._pMin;
        const minArcAngle = root._minArcAngle;

        const activeAlpha = Math.min(1, Math.max(0, p / pMin));
        const remainingAlpha = Math.min(1, Math.max(0, (1 - p) / pMin));

        let dynamicGap = fullGap;
        if (p < pMin)
            dynamicGap = fullGap * (p / pMin);
        else if (p > 1 - pMin)
            dynamicGap = fullGap * ((1 - p) / pMin);
        const halfDynamicGap = dynamicGap / 2;

        const progressAngle = p * 2 * Math.PI;

        if (activeAlpha > 0) {
            ctx.save();
            ctx.globalAlpha = activeAlpha;

            const activeStart = topAngle + halfFullGap;
            let activeEnd = topAngle + progressAngle - halfDynamicGap;

            if (p >= 0.995)
                activeEnd = topAngle + 2 * Math.PI - halfFullGap;
            else if (activeEnd - activeStart < minArcAngle)
                activeEnd = activeStart + minArcAngle;

            if (activeEnd > activeStart) {
                ctx.beginPath();
                ctx.arc(centerX, centerY, radius, activeStart, activeEnd);
                ctx.strokeStyle = root.activeColor;
                ctx.lineWidth = sw;
                ctx.lineCap = "round";
                ctx.stroke();
            }
            ctx.restore();
        }

        if (remainingAlpha > 0) {
            ctx.save();
            ctx.globalAlpha = remainingAlpha;

            let remainingStart = topAngle + progressAngle + halfDynamicGap;
            const remainingEnd = topAngle + 2 * Math.PI - halfFullGap;

            if (p <= 0.005)
                remainingStart = topAngle + halfFullGap;
            else if (remainingEnd - remainingStart < minArcAngle)
                remainingStart = remainingEnd - minArcAngle;

            if (remainingEnd > remainingStart) {
                ctx.beginPath();
                ctx.arc(centerX, centerY, radius, remainingStart, remainingEnd);
                ctx.strokeStyle = root.trackColor;
                ctx.lineWidth = sw;
                ctx.lineCap = "round";
                ctx.stroke();
            }
            ctx.restore();
        }
    }
}
