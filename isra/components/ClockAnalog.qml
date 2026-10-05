import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.style
import qs.icons
import qs.services

ClockFace {
    id: root

    property real dateSize: root.analogSize * 0.125 * (root.cfg.dateSize ?? 100) / 100
    property real outlineWidth: root.cfg.outlineWidth ?? 2

    readonly property var  qtLocale:      Qt.locale(Config.language.split("_").slice(0, 2).join("_"))

    readonly property bool badgesShown: (root.cfg.showDate ?? false) && root.dateStyle === "badges"
    readonly property bool rimShown:    (root.cfg.showDate ?? false) && root.dateStyle === "rim"

    readonly property real rimRadius:    root.analogSize / 2 - root.ringAmplitude - root.dateSize * 0.75
    readonly property real secondsDeg: root.currentTime.getSeconds() * 6 + root.currentTime.getMilliseconds() * 0.006
    readonly property real rimCenterDeg: (root.cfg.showSeconds ?? false) ? (root.secondsDeg + 180) % 360 : 300
    readonly property string rimText: root.currentTime.toLocaleDateString(root.qtLocale, "ddd d")
    readonly property var  rimLayout: {
        rimFm.ascent;
        const chars = root.rimText.split("");
        const adv = chars.map(c => rimFm.advanceWidth(c));
        const total = adv.reduce((a, b) => a + b, 0);
        const degPerPx = 180 / Math.PI / root.rimRadius;
        let x = -total / 2;
        const out = [];
        for (let i = 0; i < chars.length; i++) {
            out.push({ ch: chars[i], deg: (x + adv[i] / 2) * degPerPx });
            x += adv[i];
        }
        return { chars: out, span: total * degPerPx };
    }
    readonly property bool rimFlip: root.rimCenterDeg > 90 && root.rimCenterDeg < 270

    function rimCovers(deg) {
        if (!root.rimShown) return false;
        const d = ((deg - root.rimCenterDeg + 540) % 360) - 180;
        return Math.abs(d) <= root.rimLayout.span / 2 + 15;
    }

    FontMetrics {
        id: rimFm
        font.family:       root.clockFont
        font.pixelSize:    root.dateSize
        font.weight:       root.isGoogleSansFlex ? Font.Normal : root.subWeight
        font.variableAxes: root.isGoogleSansFlex ? root.subAxes : ({})
    }

    function handStyle(key, fallback) { return root.cfg[key] ?? fallback; }
    function handWidth(key) { return (root.cfg[key] ?? 100) / 100; }
    function handColor(key, fallback) { return Colors.md3[root.cfg[key] ?? ""] ?? fallback; }

    readonly property string dialStyle: root.cfg.dialStyle ?? "digital"
    readonly property bool   showFace:  root.cfg.showFace ?? true
    readonly property string dateStyle: root.cfg.dateStyle ?? "badges"

    readonly property real ringSides:     root.cfg.ringSides ?? 12
    readonly property real ringAmplitude: (root.cfg.ringAmplitude ?? 6) * (root.analogSize / 200)
    readonly property int  ringPoints:    256

    implicitWidth:  analogSize + root.outlineWidth
    implicitHeight: analogSize + root.outlineWidth

    Shape {
        id: wobblyFace
        anchors.centerIn: face
        width:  root.analogSize + root.outlineWidth
        height: root.analogSize + root.outlineWidth
        visible: root.showFace
        layer.enabled: visible
        layer.samples: 4

        ShapePath {
            strokeWidth: root.outlineWidth
            strokeColor: textColor
            fillColor: Colors.md3.surface_container_high
                       ?? Colors.md3.surface_container
                       ?? Qt.rgba(0.95, 0.95, 0.95, 1)

            PathPolyline {
                path: {
                    var points = []
                    var cx     = wobblyFace.width  / 2
                    var cy     = wobblyFace.height / 2
                    var steps  = root.ringPoints
                    var radius = root.analogSize / 2 - root.ringAmplitude
                    for (var i = 0; i <= steps; i++) {
                        var angle        = (i / steps) * 2 * Math.PI
                        var rotatedAngle = angle * root.ringSides + Math.PI / 2
                        var wave         = Math.sin(rotatedAngle) * root.ringAmplitude
                        var x            = Math.cos(angle) * (radius + wave) + cx
                        var y            = Math.sin(angle) * (radius + wave) + cy
                        points.push(Qt.point(x, y))
                    }
                    return points
                }
            }
        }
    }

    Item {
        id: face
        anchors.horizontalCenter: parent.horizontalCenter
        width:  root.analogSize
        height: root.analogSize

        Repeater {
            model: root.dialStyle !== "numerals" ? 12 : 0
            Item {
                anchors.fill: parent
                rotation: index * 30
                opacity: root.rimCovers(index * 30) ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutCubic } }
                Rectangle {
                    width: 6 * (root.analogSize / 200)
                    height: (index % 3 === 0 ? 10 : 6) * (root.analogSize / 200)
                    radius: width / 2
                    color: index % 3 === 0
                           ? Qt.alpha(root.subColor, 0.6)
                           : Qt.alpha(root.subColor, 0.3)
                    anchors.top: parent.top
                    anchors.topMargin: 16 * (root.analogSize / 200)
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        Repeater {
            model: root.dialStyle === "numerals" ? ["12", "3", "6", "9"] : []

            Text {
                readonly property real angle: index * Math.PI / 2
                readonly property real reach: root.analogSize * 0.335 - root.ringAmplitude * 2

                x: face.width  / 2 + Math.sin(angle) * reach - width  / 2
                y: face.height / 2 - Math.cos(angle) * reach - height / 2
                z: 1
                color: Qt.alpha(root.textColor, 0.9)
                text:  modelData

                font.family:        root.clockFont
                font.pixelSize:     root.analogSize * 0.29
                font.weight:        root.isGoogleSansFlex ? Font.Normal : root.fontWeight
                font.letterSpacing: -root.analogSize * 0.004
                font.variableAxes:  root.isGoogleSansFlex ? root.mainAxes : ({})
            }
        }

        Item {
            anchors.fill: parent
            z: 2
            rotation: root.rimCenterDeg
            opacity: root.rimShown ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutCubic } }

            Repeater {
                model: root.rimLayout.chars

                Item {
                    x: face.width  / 2
                    y: face.height / 2
                    rotation: root.rimFlip ? -modelData.deg : modelData.deg

                    Text {
                        x: -width / 2
                        y: -root.rimRadius - height / 2
                        rotation: root.rimFlip ? 180 : 0
                        color: root.subColor
                        text:  modelData.ch

                        font.family:       root.clockFont
                        font.pixelSize:    root.dateSize
                        font.weight:       root.isGoogleSansFlex ? Font.Normal : root.subWeight
                        font.variableAxes: root.isGoogleSansFlex ? root.subAxes : ({})
                    }
                }
            }
        }

        Column {
            id: innerDigitalClock
            anchors.centerIn: parent
            spacing: -root.analogSize * 0.1
            z: 1

            readonly property bool shown: root.dialStyle === "digital"
            opacity: shown ? 0.5 : 0.0
            scale:   shown ? 1.0  : 0.75

            layer.enabled: true

            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutCubic } }
            Behavior on scale   { NumberAnimation { duration: 400; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1] } }

            Text {
                id: innerHours
                anchors.horizontalCenter: parent.horizontalCenter
                color: root.subColor
                text: {
                    const h = root.currentTime.getHours()
                    const disp = root.is12h ? (h % 12 || 12) : h
                    return String(disp).padStart(2, '0')
                }

                font.family:        root.clockFont
                font.pixelSize:     root.analogSize * 0.28
                font.weight:        root.isGoogleSansFlex ? Font.Normal : root.fontWeight
                font.letterSpacing: -0.5
                font.features:      { "tnum": 1 }
                font.variableAxes:  root.isGoogleSansFlex ? root.mainAxes : ({})
            }

            Text {
                id: innerMinutes
                anchors.horizontalCenter: parent.horizontalCenter
                color: root.subColor
                text: Qt.formatTime(root.currentTime, "mm")

                font.family:        root.clockFont
                font.pixelSize:     root.analogSize * 0.28
                font.weight:        root.isGoogleSansFlex ? Font.Normal : root.fontWeight
                font.letterSpacing: -0.5
                font.features:      { "tnum": 1 }
                font.variableAxes:  root.isGoogleSansFlex ? root.mainAxes : ({})
            }
        }

        Item {
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            rotation: root.currentTime.getMinutes() * 6
                      + root.currentTime.getSeconds() * 0.1
                      + root.currentTime.getMilliseconds() * (0.1 / 1000)
            z: 3

            ClockHand {
                style:     root.handStyle("minuteHandStyle", "capsule")
                length:    root.analogSize * 0.32
                thickness: root.analogSize * 0.05 * root.handWidth("minuteHandWidth")
                color:     root.handColor("minuteHandColor", root.subColor)
            }
        }

        Item {
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            rotation: (root.currentTime.getHours() % 12) * 30
                      + root.currentTime.getMinutes() * 0.5
                      + root.currentTime.getSeconds() * (0.5 / 60)
            z: 4

            ClockHand {
                style:     root.handStyle("hourHandStyle", "capsule")
                length:    root.analogSize * 0.20
                thickness: root.analogSize * 0.08 * root.handWidth("hourHandWidth")
                color:     root.handColor("hourHandColor", root.textColor)
            }
        }

        Item {
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            rotation: root.currentTime.getSeconds() * 6
                      + root.currentTime.getMilliseconds() * 0.006
            z: 5

            ClockHand {
                readonly property string handKind: root.handStyle("secondHandStyle", "dot")

                style:     handKind
                length:    root.analogSize * (handKind === "dot" ? 0.31 : 0.38)
                thickness: root.analogSize * 0.08 * root.handWidth("secondHandWidth")
                color:     root.handColor("secondHandColor", Colors.md3.tertiary ?? Colors.md3.error ?? "#ff6b6b")
                opacity:   root.cfg.showSeconds ? 1.0 : 0.0
                scale:     root.cfg.showSeconds ? 1.0 : 0.75
                transformOrigin: Item.Bottom

                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutCubic } }
                Behavior on scale   { NumberAnimation { duration: 400; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1] } }
            }
        }

        Rectangle {
            width: root.analogSize * 0.035
            height: width
            radius: width / 2
            color: root.showFace ? (Colors.md3.surface_container_high ?? Colors.md3.surface) : Colors.md3.surface
            anchors.centerIn: parent
            z: 10
            antialiasing: true
        }
    }

    readonly property real datePillPad: 8 * ((root.dateSize) / 25)
    readonly property real datePillMinSize: root.dateSize * 1.8
    readonly property real datePillSize: Math.max(root.datePillMinSize,
                                                    dayLbl.implicitWidth, dayLbl.implicitHeight,
                                                    monthLbl.implicitWidth, monthLbl.implicitHeight)
                                          + root.datePillPad * 2

    readonly property real dateRimPush:   7 * (root.analogSize / 200)
    readonly property real dateRimOffset: (root.analogSize / 2) * Math.SQRT1_2 + root.dateRimPush
    readonly property int  daySide: Config.dateOrder === 1 ? 1 : -1

    Item {
        id: dayBadge
        x: face.x + face.width  / 2 + root.daySide * root.dateRimOffset - width  / 2
        y: face.y + face.height / 2 + root.daySide * root.dateRimOffset - height / 2

        z: 2
        opacity: root.badgesShown ? 1 : 0
        scale: root.badgesShown ? 1.0 : 0.75

        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutCubic } }
        Behavior on scale   { NumberAnimation { duration: 400; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1] } }

        width:  root.datePillSize
        height: root.datePillSize

        MaterialShape {
            anchors.fill: parent
            name: "pill"
            immediate: root.immediateShapes
            shapeSize: parent.width
            color: Colors.md3.secondary_container
                   ?? Qt.rgba(0.85, 0.85, 0.95, 1)
        }

        Text {
            id: dayLbl
            anchors.centerIn: parent
            font.family:       root.clockFont
            font.pixelSize:    (root.dateSize) * 1.45
            font.weight:       root.isGoogleSansFlex ? Font.Normal : root.subWeight
            font.variableAxes: root.isGoogleSansFlex ? root.subAxes : ({})
            color: Colors.md3.on_secondary_container
                   ?? root.subColor
            text: Qt.formatDate(root.currentTime, "d")
        }
    }

    Item {
        id: monthBadge
        x: face.x + face.width  / 2 - root.daySide * root.dateRimOffset - width  / 2
        y: face.y + face.height / 2 - root.daySide * root.dateRimOffset - height / 2

        z: 2
        opacity: root.badgesShown ? 1 : 0
        scale: root.badgesShown ? 1.0 : 0.75

        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutCubic } }
        Behavior on scale   { NumberAnimation { duration: 400; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1] } }

        width:  root.datePillSize
        height: root.datePillSize

        MaterialShape {
            anchors.fill: parent
            name: "gem"
            immediate: root.immediateShapes
            shapeSize: parent.width
            color: Colors.md3.primary_container
                   ?? Qt.rgba(0.85, 0.85, 0.95, 1)
        }

        Text {
            id: monthLbl
            anchors.centerIn: parent
            font.family:       root.clockFont
            font.pixelSize:    root.dateSize
            font.weight:       root.isGoogleSansFlex ? Font.Normal : root.subWeight
            font.variableAxes: root.isGoogleSansFlex ? root.subAxes : ({})
            color: Colors.md3.on_primary_container
                   ?? root.subColor
            text: {
                const month = root.currentTime.toLocaleDateString(root.qtLocale, "MMM");
                return month.charAt(0).toUpperCase() + month.slice(1);
            }
        }
    }
}