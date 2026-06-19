import QtQuick
import qs.style
import qs.services

Item {
    id: root

    property var    currentTime
    property color  textColor
    property color  subColor
    property int    halign
    property bool   showSeconds
    property bool   is12h
    property int    analogSize

    property string clockFont:      "Google Sans Flex"
    property int    fontWeight:     Config.clock.hourWeight ?? 500
    property real   fontWidth:      Config.clock.fontWidth      ?? 100
    property real   fontRoundness:  Config.clock.fontRoundness  ?? 0
    property real   subWeight:      Config.clock.minuteWeight ?? 300
    property real   subWidth:       Config.clock.subWidth       ?? root.fontWidth
    property real   subRoundness:   Config.clock.subRoundness   ?? root.fontRoundness

    readonly property var mainAxes: ({ "wght": root.fontWeight, "wdth": root.fontWidth,  "ROND": root.fontRoundness })
    readonly property var subAxes:  ({ "wght": root.subWeight,  "wdth": root.subWidth,   "ROND": root.subRoundness  })

    implicitWidth:  Math.max(hoursLbl.implicitWidth, minsLbl.implicitWidth,
                             Config.clock.showDate ? dateLbl.implicitWidth : 0)
    implicitHeight: hoursLbl.implicitHeight + Config.clock.timeSpacing + minsLbl.implicitHeight
                  + (Config.clock.showDate ? Config.clock.dateSpacing + dateLbl.implicitHeight : 0)

    Text {
        id: hoursLbl

        anchors.horizontalCenter: parent.horizontalCenter
        color: root.textColor
        text:  LocaleService.liveTime.split(":")[0]

        font.family:       root.clockFont
        font.pixelSize:    Config.clock.hourSize
        font.weight:       root.fontWeight
        font.features:     { "tnum": 1 }
        font.variableAxes: root.mainAxes
    }

    Text {
        id: minsLbl

        anchors {
            horizontalCenter: parent.horizontalCenter
            top:              hoursLbl.bottom
            topMargin:        Config.clock.timeSpacing
        }
        color: root.subColor
        text:  LocaleService.liveTime.split(":")[1]

        font.family:       root.clockFont
        font.pixelSize:    Config.clock.minuteSize
        font.weight:       root.subWeight
        font.features:     { "tnum": 1 }
        font.variableAxes: root.subAxes
    }

    Text {
        id: dateLbl

        visible: Config.clock.showDate
        anchors {
            horizontalCenter: parent.horizontalCenter
            top:              minsLbl.bottom
            topMargin:        Config.clock.dateSpacing
        }
        color: root.subColor
        text:  Qt.formatDate(
                   root.currentTime,
                   ["ddd, dd/MM", "ddd, MM/dd"][Config.dateFormat] ?? "ddd, dd/MM"
               )

        font.family:       root.clockFont
        font.pixelSize:    Config.clock.dateSize
        font.weight:       Font.Light
        font.variableAxes: root.subAxes
    }
}
