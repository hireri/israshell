import QtQuick
import qs.icons

Item {
    id: b

    property string shapeName: "circle"
    property string flash: ""
    property color fill: "gray"
    property real rad: 100
    property real tilt: 0
    property real sc: 1
    property real appearScale: 1
    property real appearOpacity: 1
    property string label: ""
    property string subLabel: ""
    property color textColor: "white"
    property real kx: 0
    property real ky: 0
    property real kr: 0

    width: rad * 2
    height: rad * 2
    scale: appearScale
    opacity: appearOpacity

    function flashTo(n, ms) {
        flash = n;
        restore.interval = ms;
        restore.restart();
    }

    Timer {
        id: restore
        onTriggered: b.flash = ""
    }

    MaterialShape {
        name: b.flash || b.shapeName
        immediate: true
        shapeSize: b.rad * 2 * b.sc
        color: b.fill
        x: b.rad * (1 - b.sc) + b.kx
        y: b.rad * (1 - b.sc) + b.ky
        rotationAnimates: false
        rotationDegrees: b.tilt + b.kr
    }

    FontMetrics {
        id: fm
        font: digits.font
    }

    Text {
        id: digits
        visible: b.label !== ""
        x: b.rad - implicitWidth / 2 + b.kx
        y: b.rad - fm.ascent + (fm.capitalHeight > 0 ? fm.capitalHeight : b.rad * 0.85 * 0.72) / 2 + b.ky
        text: b.label
        color: b.textColor
        font.pixelSize: b.rad * 0.85
        font.weight: Font.DemiBold
    }

    Text {
        visible: b.label !== "" && b.subLabel !== ""
        x: b.rad - implicitWidth / 2 + b.kx
        y: b.rad + b.rad * 0.38 + b.ky
        text: b.subLabel
        color: b.textColor
        opacity: 0.8
        font.pixelSize: b.rad * 0.14
    }
}
