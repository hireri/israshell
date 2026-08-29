import QtQuick
import QtQuick.Shapes
import QtQuick.Shapes.DesignHelpers
import qs.style

Item {
    id: root

    property real progress: 0
    property real strokeWidth: 3
    property color activeColor: Colors.md3.primary
    property color trackColor: Qt.alpha(Colors.md3.primary, 0.25)

    property real gapDegrees: 15

    readonly property real _pMin: 0.03
    readonly property real _minArcAngleDeg: 0.04 * 180 / Math.PI

    readonly property real _p: Math.max(0, Math.min(1, root.progress))
    readonly property real _progressDeg: _p * 360
    readonly property real _halfFullGapDeg: root.gapDegrees / 2

    readonly property real _dynamicGapDeg: {
        if (_p < _pMin) return root.gapDegrees * (_p / _pMin);
        if (_p > 1 - _pMin) return root.gapDegrees * ((1 - _p) / _pMin);
        return root.gapDegrees;
    }
    readonly property real _halfDynamicGapDeg: _dynamicGapDeg / 2

    readonly property real _activeAlpha: Math.min(1, Math.max(0, _p / _pMin))
    readonly property real _remainingAlpha: Math.min(1, Math.max(0, (1 - _p) / _pMin))

    readonly property real _activeStartDeg: _halfFullGapDeg
    readonly property real _activeEndDeg: {
        if (_p >= 0.995) return 360 - _halfFullGapDeg;
        const e = _progressDeg - _halfDynamicGapDeg;
        if (e - _activeStartDeg < _minArcAngleDeg) return _activeStartDeg + _minArcAngleDeg;
        return e;
    }
    readonly property real _activeSweepDeg: Math.max(0, _activeEndDeg - _activeStartDeg)

    readonly property real _remainingEndDeg: 360 - _halfFullGapDeg
    readonly property real _remainingStartDeg: {
        if (_p <= 0.005) return _halfFullGapDeg;
        const s = _progressDeg + _halfDynamicGapDeg;
        if (_remainingEndDeg - s < _minArcAngleDeg) return _remainingEndDeg - _minArcAngleDeg;
        return s;
    }
    readonly property real _remainingSweepDeg: Math.max(0, _remainingEndDeg - _remainingStartDeg)

    EllipseShape {
        anchors.fill: parent
        visible: root.strokeWidth > 0.01 && root._activeSweepDeg > 0 && root._activeAlpha > 0
        opacity: root._activeAlpha
        fillColor: "transparent"
        strokeColor: root.activeColor
        strokeWidth: root.strokeWidth
        capStyle: ShapePath.RoundCap
        borderMode: EllipseShape.Inside
        startAngle: root._activeStartDeg
        sweepAngle: root._activeSweepDeg
    }

    EllipseShape {
        anchors.fill: parent
        visible: root.strokeWidth > 0.01 && root._remainingSweepDeg > 0 && root._remainingAlpha > 0
        opacity: root._remainingAlpha
        fillColor: "transparent"
        strokeColor: root.trackColor
        strokeWidth: root.strokeWidth
        capStyle: ShapePath.RoundCap
        borderMode: EllipseShape.Inside
        startAngle: root._remainingStartDeg
        sweepAngle: root._remainingSweepDeg
    }
}
