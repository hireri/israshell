import QtQuick
import QtQuick.Layouts
import qs.style
import qs.services

ClockFace {
    id: root

    readonly property real baseSize: root.size

    readonly property string hourShape:   root.cfg.hourShape   ?? "cookie12"
    readonly property string minuteShape: root.cfg.minuteShape ?? "square"

    readonly property real dateGap: root.tiled ? 8 : root.textDateGap

    implicitWidth:  timeRow.implicitWidth
    implicitHeight: timeRow.implicitHeight
                  + (root.cfg.showDate ? root.dateGap + dateLbl.implicitHeight : 0)

    RowLayout {
        id: timeRow

        anchors.horizontalCenter: parent.horizontalCenter
        spacing: root.tiled ? (root.cfg.tileSpacing ?? 6) : 6

        ClockDigitGrid {
            visible: root.grid
            Layout.alignment: Qt.AlignVCenter
            columns:       4
            columnSpacing: root.cfg.gridColumnSpacing ?? 0
            outline:       root.cfg.digitOutline ?? 0

            hourColor:        root.textColor
            minuteColor:      root.subColor
            clockFont:        root.clockFont
            fontSize:         root.baseSize
            hourWeight:       root.fontWeight
            minuteWeight:     root.subWeight
            isGoogleSansFlex: root.isGoogleSansFlex
            hourAxes:         root.mainAxes
            minuteAxes:       root.subAxes
        }

        ClockTile {
            id: hourTile
            visible: root.tiled
            Layout.alignment: Qt.AlignVCenter
            text:       LocaleService.liveTime.split(":")[0]
            shape:      root.hourShape
            fill:       root.tileFill(root.cfg.colorRole ?? "primary")
            onFill:     root.tileOnFill(root.cfg.colorRole ?? "primary")
            plainColor: root.textColor
            immediate:  root.immediateShapes
            spinKey:    hourTile.text

            clockFont:        root.clockFont
            fontSize:         root.baseSize
            fontWeight:       root.fontWeight
            isGoogleSansFlex: root.isGoogleSansFlex
            axes:             root.mainAxes
            measureWeight:     Math.max(root.fontWeight, root.subWeight)
        }

        ClockTile {
            id: minuteTile
            visible: root.tiled
            Layout.alignment: Qt.AlignVCenter
            text:       LocaleService.liveTime.split(":")[1]
            shape:      root.minuteShape
            fill:       root.tileFill(root.cfg.subColorRole ?? "secondary")
            onFill:     root.tileOnFill(root.cfg.subColorRole ?? "secondary")
            plainColor: root.textColor
            immediate:  root.immediateShapes
            spinKey:    minuteTile.text

            clockFont:        root.clockFont
            fontSize:         root.baseSize
            fontWeight:       root.subWeight
            isGoogleSansFlex: root.isGoogleSansFlex
            axes:             root.subAxes
            measureWeight:     Math.max(root.fontWeight, root.subWeight)
        }

        Text {
            visible: !root.tiled && !root.grid
            Layout.alignment: Qt.AlignVCenter
            color: root.textColor
            text:  LocaleService.liveTime.split(":").slice(0, 2).join(":")

            font.family:        root.clockFont
            font.pixelSize:     root.baseSize
            font.weight:        root.isGoogleSansFlex ? Font.Normal : root.fontWeight
            font.letterSpacing: -0.5
            font.features:      { "tnum": 1 }
            font.variableAxes:  root.isGoogleSansFlex ? root.mainAxes : ({})
        }

        ClockExtras {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: root.tiled ? 0 : root.baseSize * 0.1
            face: root
            unit: root.tiled ? hourTile.size : root.baseSize
        }
    }

    ClockDate {
        id: dateLbl
        face: root
        pill: root.tiled

        width: timeRow.width
        anchors {
            left:      timeRow.left
            top:       timeRow.bottom
            topMargin: root.dateGap
        }
    }
}
