import QtQuick
import QtQuick.Layouts
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
    property int    fontWeight:     Config.clock.hourWeight    ?? 600
    property real   fontWidth:      Config.clock.fontWidth     ?? 100
    property real   fontRoundness:  Config.clock.fontRoundness ?? 0
    property real   subWeight:      Config.clock.minuteWeight  ?? 300
    property real   subWidth:       Config.clock.subWidth      ?? root.fontWidth
    property real   subRoundness:   Config.clock.subRoundness  ?? root.fontRoundness

    readonly property int  baseSize:         Config.clock.hourSize ?? 64
    readonly property bool isGoogleSansFlex: root.clockFont === "Google Sans Flex"
    readonly property var  mainAxes:         ({ "wght": root.fontWeight, "wdth": root.fontWidth, "ROND": root.fontRoundness })
    readonly property var  subAxes:          ({ "wght": root.subWeight,  "wdth": root.subWidth,  "ROND": root.subRoundness  })

    implicitWidth:  timeRow.implicitWidth
    implicitHeight: timeRow.implicitHeight
                  + (Config.clock.showDate
                        ? Config.clock.dateSpacing + dateLbl.implicitHeight
                        : 0)

    RowLayout {
        id: timeRow

        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 6

        Text {
            Layout.alignment: Qt.AlignBaseline
            color: root.textColor
            text:  LocaleService.liveTime.split(":").slice(0, 2).join(":")

            font.family:        root.clockFont
            font.pixelSize:     root.baseSize
            font.weight:        root.isGoogleSansFlex ? Font.Normal : root.fontWeight
            font.letterSpacing: -0.5
            font.features:      { "tnum": 1 }
            font.variableAxes:  root.isGoogleSansFlex ? root.mainAxes : ({})
        }

        Text {
            visible:          root.showSeconds
            Layout.alignment: Qt.AlignBaseline
            color: root.subColor
            text:  ":" + LocaleService.liveSecs

            font.family:       root.clockFont
            font.pixelSize:    root.baseSize * 0.55
            font.weight:       root.isGoogleSansFlex ? Font.Normal : root.subWeight
            font.features:     { "tnum": 1 }
            font.variableAxes: root.isGoogleSansFlex ? root.subAxes : ({})
        }

        Item {
            visible:               root.is12h
            Layout.preferredWidth: 4
        }

        Text {
            visible:          root.is12h
            Layout.alignment: Qt.AlignBaseline
            color: root.subColor
            text:  LocaleService.liveAmPm.trim()

            font.family:        root.clockFont
            font.pixelSize:     root.baseSize * 0.35
            font.weight:        root.isGoogleSansFlex ? Font.Normal : root.subWeight
            font.letterSpacing: 0.5
            font.variableAxes:  root.isGoogleSansFlex ? root.subAxes : ({})
        }
    }

    Text {
        id: dateLbl

        visible: Config.clock.showDate
        color:   root.subColor
        text:    Qt.formatDate(
                     root.currentTime,
                     ["ddd, dd/MM", "ddd, MM/dd"][Config.dateFormat] ?? "ddd, dd/MM"
                 )

        width:               timeRow.width
        horizontalAlignment: root.halign

        anchors {
            left:      timeRow.left
            top:       timeRow.bottom
            topMargin: Config.clock.dateSpacing
        }

        font.family:       root.clockFont
        font.pixelSize:    Config.clock.dateSize
        font.weight:       root.isGoogleSansFlex ? Font.Normal : root.subWeight
        font.variableAxes: root.isGoogleSansFlex ? root.subAxes : ({})
    }
}
