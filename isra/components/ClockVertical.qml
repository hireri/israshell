import QtQuick
import qs.style
import qs.services

ClockFace {
    id: root

    readonly property string hourShape:   root.cfg.hourShape   ?? "cookie12"
    readonly property string minuteShape: root.cfg.minuteShape ?? "square"

    readonly property real minuteFontSize: root.size * (root.cfg.minuteSize ?? 100) / 100
    readonly property real lineGap: root.tiled ? (root.cfg.tileSpacing ?? 6) : (root.cfg.timeSpacing ?? -30)

    readonly property real _timeWidth: root.grid ? gridBox.width : Math.max(hoursLbl.implicitWidth, minsLbl.implicitWidth)
    readonly property real _timeHeight: root.grid
        ? gridBox.height
        : hoursLbl.implicitHeight + root.lineGap + minsLbl.implicitHeight

    readonly property real dateGap: root.tiled ? 8 : root.textDateGap

    implicitWidth:  Math.max(mainRow.implicitWidth, root.cfg.showDate ? dateLbl.implicitWidth : 0)
    implicitHeight: mainRow.implicitHeight
                  + (root.cfg.showDate ? root.dateGap + dateLbl.implicitHeight : 0)

    Row {
        id: mainRow
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: root.tiled ? 6 : root.size * 0.1

        Item {
            id: timeBox
            width:  root._timeWidth
            height: root._timeHeight

            ClockTile {
                id: hoursLbl

                visible: !root.grid
                anchors.horizontalCenter: parent.horizontalCenter
                text:       LocaleService.liveTime.split(":")[0]
                shape:      root.tiled ? root.hourShape : "none"
                fill:       root.tileFill(root.cfg.colorRole ?? "primary")
                onFill:     root.tileOnFill(root.cfg.colorRole ?? "primary")
                plainColor: root.textColor
                immediate:  root.immediateShapes
                spinKey:    hoursLbl.text

                clockFont:        root.clockFont
                fontSize:         root.size
                fontWeight:       root.fontWeight
                isGoogleSansFlex: root.isGoogleSansFlex
                axes:             root.mainAxes
                measureWeight:    Math.max(root.fontWeight, root.subWeight)
            }

            ClockTile {
                id: minsLbl

                visible: !root.grid
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top:              hoursLbl.bottom
                    topMargin:        root.lineGap
                }
                text:       LocaleService.liveTime.split(":")[1]
                shape:      root.tiled ? root.minuteShape : "none"
                fill:       root.tileFill(root.cfg.subColorRole ?? "secondary")
                onFill:     root.tileOnFill(root.cfg.subColorRole ?? "secondary")
                plainColor: root.subColor
                immediate:  root.immediateShapes
                spinKey:    minsLbl.text

                clockFont:        root.clockFont
                fontSize:         root.minuteFontSize
                fontWeight:       root.subWeight
                isGoogleSansFlex: root.isGoogleSansFlex
                axes:             root.subAxes
                measureWeight:    Math.max(root.fontWeight, root.subWeight)
            }

            ClockDigitGrid {
                id: gridBox

                visible: root.grid
                anchors.horizontalCenter: parent.horizontalCenter
                columns:       2
                columnSpacing: root.cfg.gridColumnSpacing ?? 0
                rowSpacing:    root.cfg.gridRowSpacing ?? 0
                outline:       root.cfg.digitOutline ?? 0

                hourColor:        root.textColor
                minuteColor:      root.subColor
                clockFont:        root.clockFont
                fontSize:         root.size
                hourWeight:       root.fontWeight
                minuteWeight:     root.subWeight
                isGoogleSansFlex: root.isGoogleSansFlex
                hourAxes:         root.mainAxes
                minuteAxes:       root.subAxes
            }
        }

        ClockExtras {
            anchors.verticalCenter: parent.verticalCenter
            face: root
            unit: root.tiled ? hoursLbl.size : root.size
        }
    }

    ClockDate {
        id: dateLbl
        face: root
        pill: root.tiled

        width: root.width
        anchors {
            left:      parent.left
            top:       mainRow.bottom
            topMargin: root.dateGap
        }
    }
}
