import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import qs.style
import qs.icons
import qs.services

Item {
    id: root

    property var currentTime
    property string clockFont
    property color textColor
    property color subColor
    property int halign
    property bool showSeconds
    property bool is12h
    property int analogSize
    property real dateSize: Config.clock.dateSize ?? 25
    property real outlineWidth: Config.clock.outlineWidth ?? 2

    property int    fontWeight:    Config.clock.hourWeight    ?? 600
    property real   fontWidth:     Config.clock.fontWidth     ?? 100
    property real   fontRoundness: Config.clock.fontRoundness ?? 0
    property real   subWeight:     Config.clock.minuteWeight  ?? 300

    readonly property bool isGoogleSansFlex: root.clockFont === "Google Sans Flex"
    readonly property var  mainAxes:         ({ "wght": root.fontWeight, "wdth": root.fontWidth, "ROND": root.fontRoundness })
    readonly property var  subAxes:          ({ "wght": root.subWeight,  "wdth": root.fontWidth,  "ROND": root.fontRoundness  })

    readonly property var  qtLocale:      Qt.locale(Config.language.split("_").slice(0, 2).join("_"))

    readonly property real ringSides:     Config.clock.ringSides     ?? 8
    readonly property real ringAmplitude: (Config.clock.ringAmplitude ?? 6) * (root.analogSize / 200)
    readonly property int  ringPoints:    256

    implicitWidth:  analogSize + root.outlineWidth
    implicitHeight: analogSize + root.outlineWidth

    Shape {
        id: wobblyFace
        anchors.centerIn: face
        width:  root.analogSize + root.outlineWidth
        height: root.analogSize + root.outlineWidth
        visible: true
        layer.enabled: true
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
            model: 12
            Item {
                anchors.fill: parent
                rotation: index * 30
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

        Column {
            id: innerDigitalClock
            anchors.centerIn: parent
            spacing: -root.analogSize * 0.1
            z: 1

            readonly property bool shown: Config.clock.showDigitalInside ?? false
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

            Rectangle {
                width: root.analogSize * 0.05
                height: root.analogSize * 0.32 + width
                radius: width / 2
                color: root.subColor
                anchors.bottom: parent.verticalCenter
                anchors.bottomMargin: -radius
                anchors.horizontalCenter: parent.horizontalCenter
                antialiasing: true
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

            Rectangle {
                width: root.analogSize * 0.08
                height: root.analogSize * 0.20 + width
                radius: width / 2
                color: root.textColor
                anchors.bottom: parent.verticalCenter
                anchors.bottomMargin: -radius
                anchors.horizontalCenter: parent.horizontalCenter
                antialiasing: true
            }
        }

        Item {
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            rotation: root.currentTime.getSeconds() * 6
                      + root.currentTime.getMilliseconds() * 0.006
            z: 5

            Rectangle {
                width: root.analogSize * 0.08
                height: width
                radius: width / 2
                color: Colors.md3.tertiary ?? Colors.md3.error ?? "#ff6b6b"
                y: root.analogSize * 0.15
                anchors.horizontalCenter: parent.horizontalCenter
                antialiasing: true
                opacity: Config.clock.showSeconds ? 1.0 : 0.0
                scale: Config.clock.showSeconds ? 1.0 : 0.75

                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutCubic } }
                Behavior on scale   { NumberAnimation { duration: 400; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1] } }

            }
        }

        Rectangle {
            width: root.analogSize * 0.05
            height: width
            radius: width / 2
            color: root.textColor
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

    Item {
        id: dayBadge
        x: face.x + face.width  / 2 - root.dateRimOffset - width  / 2
        y: face.y + face.height / 2 - root.dateRimOffset - height / 2

        z: 2
        opacity: Config.clock.showDate ? 1 : 0
        scale: Config.clock.showDate ? 1.0 : 0.75

        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutCubic } }
        Behavior on scale   { NumberAnimation { duration: 400; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1] } }

        width:  root.datePillSize
        height: root.datePillSize

        MaterialShape {
            anchors.fill: parent
            name: "pill"
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
        x: face.x + face.width  / 2 + root.dateRimOffset - width  / 2
        y: face.y + face.height / 2 + root.dateRimOffset - height / 2

        z: 2
        opacity: Config.clock.showDate ? 1 : 0
        scale: Config.clock.showDate ? 1.0 : 0.75

        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutCubic } }
        Behavior on scale   { NumberAnimation { duration: 400; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1] } }

        width:  root.datePillSize
        height: root.datePillSize

        MaterialShape {
            anchors.fill: parent
            name: "gem"
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