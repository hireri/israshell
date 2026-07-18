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
    property int    fontWeight:     Config.clock.hourWeight    ?? 500
    property real   fontWidth:      Config.clock.fontWidth     ?? 100
    property real   fontRoundness:  Config.clock.fontRoundness ?? 0
    property real   subWeight:      Config.clock.minuteWeight  ?? 300

    readonly property bool isGoogleSansFlex: root.clockFont === "Google Sans Flex"

    readonly property var mainAxes: ({ "wght": root.fontWeight, "wdth": root.fontWidth, "ROND": root.fontRoundness })
    readonly property var subAxes:  ({ "wght": root.subWeight,  "wdth": root.fontWidth,  "ROND": root.fontRoundness  })

    readonly property real _timeWidth: Math.max(hoursLbl.implicitWidth, minsLbl.implicitWidth)

    implicitWidth:  Math.max(_timeWidth, Config.clock.showDate ? dateLbl.implicitWidth : 0)
    implicitHeight: hoursLbl.implicitHeight + Config.clock.timeSpacing + minsLbl.implicitHeight
                  + (Config.clock.showDate ? Config.clock.dateSpacing + dateLbl.implicitHeight : 0)

    Text {
        id: hoursLbl

        anchors.horizontalCenter: parent.horizontalCenter
        color: root.textColor
        text:  LocaleService.liveTime.split(":")[0]

        font.family:       root.clockFont
        font.pixelSize:    Config.clock.hourSize
        font.weight:       root.isGoogleSansFlex ? Font.Normal : root.fontWeight
        font.features:     { "tnum": 1 }
        font.variableAxes: root.isGoogleSansFlex ? root.mainAxes : ({})
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
        font.weight:       root.isGoogleSansFlex ? Font.Normal : root.subWeight
        font.features:     { "tnum": 1 }
        font.variableAxes: root.isGoogleSansFlex ? root.subAxes : ({})
    }

    Text {
        id: dateLbl

        visible: Config.clock.showDate
        color:   root.subColor
        text:    LocaleService.shortDateText

        width:               root.width
        horizontalAlignment: root.halign

        anchors {
            left:      parent.left
            top:       minsLbl.bottom
            topMargin: Config.clock.dateSpacing
        }

        font.family:       root.clockFont
        font.pixelSize:    Config.clock.dateSize
        font.weight:       root.isGoogleSansFlex ? Font.Normal : Font.Light
        font.variableAxes: root.isGoogleSansFlex ? root.subAxes : ({})
    }
}
