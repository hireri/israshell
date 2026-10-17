pragma ComponentBehavior: Bound
import QtQuick
import qs.style
import qs.services
import "format.js" as Fmt

Item {
    id: root

    readonly property string mode: root.range === "day" ? "hours" : "days"
    property var srcDays: []
    property var srcHourly: ({})
    property string srcRange: ""

    property var days: []
    property var hourly: ({})
    property string range: ""
    property bool swapping: false
    property bool settled: true
    property real fade: 1
    property real chartHeight: 150
    property int hover: -1

    readonly property var order: ["other", "fun", "web", "work"]
    readonly property var steps: [600, 900, 1800, 3600, 7200, 10800, 14400, 21600, 28800, 43200]
    readonly property int count: root.mode === "hours" ? 24 : root.days.length
    readonly property real labelW: 38
    readonly property real plotW: root.width - root.labelW
    readonly property real slotW: root.plotW / Math.max(1, root.count)
    readonly property real barW: Math.max(4, Math.min(root.slotW - (root.mode === "hours" ? 5 : 14), root.mode === "hours" ? 14 : 42))
    readonly property real topRoom: 30
    readonly property var hourTotals: Array.from({ length: 24 }, (_, h) => root.order.reduce((a, c) => a + ((root.hourly[c] ?? [])[h] ?? 0), 0))
    readonly property real maxValue: root.mode === "hours" ? Math.max(0, ...root.hourTotals) : Math.max(0, ...root.days.map(d => d.total))
    readonly property real step: root.steps.find(s => root.maxValue / s <= 4) ?? 43200
    readonly property int lines: 4
    readonly property real scaleMax: root.lines * root.step
    readonly property string todayKey: ScreenTimeService.todayKey()

    function valueAt(i: int): real {
        return root.mode === "hours" ? root.hourTotals[i] : (root.days[i]?.total ?? 0);
    }

    function dateOf(i: int): var {
        return new Date(root.days[i].key + "T00:00:00");
    }

    function nameAt(i: int): string {
        if (root.mode === "hours")
            return (i < 10 ? "0" : "") + i + ":00";
        const d = root.dateOf(i);
        return Qt.locale().dayName(d.getDay(), Locale.ShortFormat) + " " + d.getDate();
    }

    function tickAt(i: int): string {
        if (root.mode === "hours")
            return i % 6 === 0 ? (i < 10 ? "0" : "") + i : "";
        const d = root.dateOf(i);
        if (root.range === "week")
            return Qt.locale().dayName(d.getDay(), Locale.ShortFormat);
        return d.getDate() % 5 === 0 ? String(d.getDate()) : "";
    }

    function axisLabel(secs: real): string {
        return secs === 0 ? "0" : secs < 3600 ? Math.round(secs / 60) + "m" : (Math.round(secs / 360) / 10) + "h";
    }

    implicitHeight: root.topRoom + root.chartHeight + 32

    Binding { target: root; property: "days"; value: root.srcDays ?? []; when: !root.swapping && root.srcRange === root.range; restoreMode: Binding.RestoreNone }
    Binding { target: root; property: "hourly"; value: root.srcHourly ?? ({}); when: !root.swapping && root.srcRange === root.range; restoreMode: Binding.RestoreNone }

    Component.onCompleted: root.range = root.srcRange

    onSrcRangeChanged: if (root.range !== "" && root.range !== root.srcRange)
        swap.restart()

    SequentialAnimation {
        id: swap

        PropertyAction { target: root; property: "settled"; value: false }
        PropertyAction { target: root; property: "swapping"; value: true }
        NumberAnimation { target: root; property: "fade"; to: 0; duration: 150; easing.type: Easing.OutCubic }
        ScriptAction { script: root.range = root.srcRange }
        PropertyAction { target: root; property: "swapping"; value: false }
        PauseAnimation { duration: 50 }
        NumberAnimation { target: root; property: "fade"; to: 1; duration: 250; easing.type: Easing.OutCubic }
        PropertyAction { target: root; property: "settled"; value: true }
    }

    Item {
        id: plot
        y: root.topRoom
        width: root.plotW
        height: root.chartHeight

        Repeater {
            model: root.lines + 1

            Item {
                id: grid
                required property int index

                y: plot.height - grid.index * root.step / root.scaleMax * plot.height
                width: root.width

                Rectangle {
                    x: 0
                    width: root.plotW
                    height: grid.index === 0 ? 2 : 1
                    y: grid.index === 0 ? -1 : 0
                    color: grid.index === 0 ? Colors.md3.on_surface_variant : Colors.md3.outline_variant
                }

                Text {
                    x: root.plotW + 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.axisLabel(grid.index * root.step)
                    font.family: Config.fontFamily
                    font.pixelSize: 12
                    color: Colors.md3.on_surface_variant
                    opacity: root.fade
                }
            }
        }

        Repeater {
            model: root.count

            Item {
                id: col
                required property int index

                readonly property bool isToday: root.mode === "days" && root.days[col.index]?.key === root.todayKey
                readonly property var segs: root.mode === "hours" ? root.order.map(c => ({ cat: c, secs: (root.hourly[c] ?? [])[col.index] ?? 0 })).filter(s => s.secs > 0) : (root.valueAt(col.index) > 0 ? [{ cat: "", secs: root.valueAt(col.index) }] : [])

                x: col.index * root.slotW
                width: root.slotW
                height: plot.height

                property real dim: root.hover >= 0 && root.hover !== col.index ? 0.55 : 1
                opacity: root.fade * col.dim

                Behavior on dim {
                    NumberAnimation { duration: 120 }
                }

                Column {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: root.barW

                    Repeater {
                        model: col.segs.length

                        Rectangle {
                            id: seg
                            required property int index

                            readonly property var info: col.segs[seg.index]
                            readonly property bool isTop: seg.index === 0
                
                            property real frac: (seg.info?.secs ?? 0) / root.scaleMax

                            width: root.barW
                            height: Math.max(3, seg.frac * plot.height)
                            topLeftRadius: seg.isTop ? 4 : 0
                            topRightRadius: seg.isTop ? 4 : 0
                            color: root.mode === "hours" ? ScreenTimeService.categoryColor(seg.info?.cat ?? "other") : Colors.md3.primary

                            Behavior on frac {
                                enabled: root.settled
                                NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }

                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.hover = col.index
                    onExited: if (root.hover === col.index)
                        root.hover = -1
                }
            }
        }
    }

    Item {
        anchors.top: plot.bottom
        width: root.plotW
        height: 32
        opacity: root.fade

        Repeater {
            model: root.count

            Item {
                id: tick
                required property int index
                readonly property string label: root.tickAt(tick.index)
                readonly property bool isToday: root.mode === "days" && root.days[tick.index]?.key === root.todayKey

                x: tick.index * root.slotW
                width: root.slotW
                height: parent.height
                visible: tick.label !== ""

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 2
                    height: 5
                    color: Colors.md3.on_surface_variant
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 9
                    text: tick.label
                    font.family: Config.fontFamily
                    font.pixelSize: 12
                    font.weight: tick.isToday ? Font.Medium : Font.Normal
                    color: tick.isToday ? Colors.md3.primary : Colors.md3.on_surface_variant
                }
            }
        }
    }

    Rectangle {
        id: bubble
        readonly property real v: root.hover >= 0 ? root.valueAt(root.hover) : 0

        visible: root.hover >= 0 && bubble.v > 0
        opacity: root.fade
        x: Math.max(0, Math.min(root.plotW - bubble.width, root.hover * root.slotW + root.slotW / 2 - bubble.width / 2))
        y: Math.max(0, root.topRoom + plot.height * (1 - bubble.v / root.scaleMax) - bubble.height - 6)
        width: tip.implicitWidth + 20
        height: 26
        radius: 13
        color: Colors.md3.inverse_surface

        Text {
            id: tip
            anchors.centerIn: parent
            text: root.hover >= 0 ? root.nameAt(root.hover) + " · " + Fmt.duration(bubble.v) : ""
            font.family: Config.fontFamily
            font.pixelSize: 12
            color: Colors.md3.inverse_on_surface
        }
    }
}
