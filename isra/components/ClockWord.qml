import QtQuick
import QtQuick.Layouts
import qs.style

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

    property int    fontWeight:    Config.clock.hourWeight    ?? 500
    property real   fontWidth:     Config.clock.fontWidth     ?? 100
    property real   fontRoundness: Config.clock.fontRoundness ?? 0
    property real   subWeight:     Config.clock.minuteWeight  ?? 300
    property real   subWidth:      Config.clock.subWidth      ?? root.fontWidth
    property real   subRoundness:  Config.clock.subRoundness  ?? root.fontRoundness

    readonly property bool isGoogleSansFlex: root.clockFont === "Google Sans Flex"

    readonly property var mainAxes: ({ "wght": root.fontWeight, "wdth": root.fontWidth, "ROND": root.fontRoundness })
    readonly property var subAxes:  ({ "wght": root.subWeight,  "wdth": root.subWidth,  "ROND": root.subRoundness  })

    implicitWidth:  wordClock.implicitWidth
    implicitHeight: wordClock.implicitHeight
                    + (Config.clock.showDate ? Config.clock.dateSpacing + dateLbl.implicitHeight : 0)

    function _wordClockLines() {
        const now = new Date();
        let h = now.getHours(), mi = now.getMinutes();
        const r = mi % 5, m = r >= 3 ? (mi + (5 - r)) % 60 || 0 : mi - r;
        const dh = (r >= 3 && mi + (5 - r) >= 60) ? (h + 1) % 24 : h;
        const displayHour = dh % 12 || 12, nextHour = (displayHour % 12) + 1;
        const names = ["", "ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN", "TWELVE"];
        const w = (text, active) => ({ text, active, isNumber: names.includes(text) });
        const itis = [w("IT", true), w("IS", true)];

        if (m === 0)  return [{ words: itis }, { words: [w(names[displayHour], true)] }, { words: [w("OCLOCK", true)] }];
        if (m === 5)  return [{ words: itis }, { words: [w("FIVE", true)] },              { words: [w("PAST", true), w(names[displayHour], true)] }];
        if (m === 10) return [{ words: itis }, { words: [w("TEN", true)] },               { words: [w("PAST", true), w(names[displayHour], true)] }];
        if (m === 15) return [{ words: itis }, { words: [w("QUARTER", true)] },           { words: [w("PAST", true), w(names[displayHour], true)] }];
        if (m === 20) return [{ words: itis }, { words: [w("TWENTY", true)] },            { words: [w("PAST", true), w(names[displayHour], true)] }];
        if (m === 25) return [{ words: itis }, { words: [w("TWENTY", true), w("FIVE", true)] }, { words: [w("PAST", true), w(names[displayHour], true)] }];
        if (m === 30) return [{ words: itis }, { words: [w("HALF", true)] },              { words: [w("PAST", true), w(names[displayHour], true)] }];
        if (m === 35) return [{ words: itis }, { words: [w("TWENTY", true), w("FIVE", true)] }, { words: [w("TO", true), w(names[nextHour], true)] }];
        if (m === 40) return [{ words: itis }, { words: [w("TWENTY", true)] },            { words: [w("TO", true), w(names[nextHour], true)] }];
        if (m === 45) return [{ words: itis }, { words: [w("QUARTER", true)] },           { words: [w("TO", true), w(names[nextHour], true)] }];
        if (m === 50) return [{ words: itis }, { words: [w("TEN", true)] },               { words: [w("TO", true), w(names[nextHour], true)] }];
        if (m === 55) return [{ words: itis }, { words: [w("FIVE", true)] },              { words: [w("TO", true), w(names[nextHour], true)] }];
        return [{ words: itis }];
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: wordRepeater.model = root._wordClockLines()
    }

    ColumnLayout {
        id: wordClock
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Config.clock.wordSpacing ?? -6

        Repeater {
            id: wordRepeater
            model: root._wordClockLines()

            Row {
                Layout.alignment: root.halign === Text.AlignLeft ? Qt.AlignLeft
                                : root.halign === Text.AlignRight ? Qt.AlignRight
                                : Qt.AlignHCenter
                spacing: 8

                Repeater {
                    model: modelData.words

                    Text {
                        id: wordText

                        text: modelData.text
                        font {
                            family:       root.clockFont
                            pixelSize:    (Config.clock.hourSize ?? 48) * 0.55
                            weight:       root.isGoogleSansFlex
                                            ? Font.Normal
                                            : (modelData.isNumber ? root.fontWeight : root.subWeight)
                            variableAxes: root.isGoogleSansFlex
                                            ? (modelData.isNumber ? root.mainAxes : root.subAxes)
                                            : ({})
                        }
                        color: !modelData.active  ? Qt.alpha(root.subColor, 0.25)
                            : modelData.isNumber ? root.textColor
                            :                      root.subColor
                        opacity: modelData.active ? 1.0 : 0.35
                        Behavior on opacity {
                            NumberAnimation { duration: 400; easing.type: Easing.InOutCubic }
                        }
                    }
                }
            }
        }
    }

    Text {
        id: dateLbl
        visible: Config.clock.showDate
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: wordClock.bottom
            topMargin: Config.clock.dateSpacing
        }
        font {
            family:       root.clockFont
            pixelSize:    Config.clock.dateSize
            weight:       root.isGoogleSansFlex ? Font.Normal : Font.Light
            variableAxes: root.isGoogleSansFlex ? root.subAxes : ({})
        }
        color: root.subColor
        opacity: 0.8
        text: Qt.formatDate(root.currentTime, ["ddd, dd/MM", "ddd, MM/dd"][Config.dateFormat] ?? "ddd, dd/MM")
    }
}
