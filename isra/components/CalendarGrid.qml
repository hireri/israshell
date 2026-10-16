pragma ComponentBehavior: Bound
import QtQuick
import qs.style
import qs.icons
import qs.services
import "../services/calendar.js" as Cal

Item {
    id: root

    property int firstDayOfWeek: 1
    property var eventCounts: ({})
    property bool isOpen: false
    property date selectedDate: new Date()

    signal daySelected(date day)
    signal viewChanged(int year, int month)

    readonly property int cellSize: 38
    readonly property int circleSize: 34
    readonly property int cellHeight: 30
    readonly property int pillHeight: 26
    readonly property int inset: (cellSize - circleSize) / 2
    readonly property int insetY: (cellHeight - pillHeight) / 2
    readonly property int gridW: 7 * cellSize
    readonly property real gridX: Math.round((width - gridW) / 2)
    readonly property int navSize: 32
    readonly property int slide: 24

    property date today: new Date()
    readonly property int todayIdx: today.getFullYear() * 12 + today.getMonth()
    property int shownIdx: todayIdx
    property int _targetIdx: todayIdx
    property int _dir: 1
    property int _slot: 0

    readonly property int shownYear: Math.floor(shownIdx / 12)
    readonly property int shownMonth: shownIdx % 12
    readonly property var cells: Cal.monthGrid(shownYear, shownMonth, firstDayOfWeek)
    readonly property string todayKey: Cal.dayKey(today)
    readonly property string selKey: Cal.dayKey(selectedDate)
    readonly property int selIdx: cells.findIndex(c => c.key === selKey)

    readonly property var navSpec: [
        {
            icon: "filter-center-focus",
            label: "calendar.today",
            run: () => root._goToday()
        },
        {
            icon: "chevron-left",
            label: "calendar.prevMonth",
            run: () => root._navigate(root._targetIdx - 1)
        },
        {
            icon: "chevron-right",
            label: "calendar.nextMonth",
            run: () => root._navigate(root._targetIdx + 1)
        }
    ]

    implicitWidth: 268
    implicitHeight: 244
    width: implicitWidth
    height: implicitHeight

    onIsOpenChanged: if (isOpen) _jump()
    onSelIdxChanged: if (selIdx >= 0) _slot = selIdx
    onShownIdxChanged: viewChanged(Math.floor(shownIdx / 12), shownIdx % 12)

    Component.onCompleted: {
        if (selIdx >= 0)
            _slot = selIdx;
        viewChanged(shownYear, shownMonth);
    }

    function _qtDow(i) {
        return (firstDayOfWeek + i) % 7;
    }

    function _navigate(idx) {
        if (idx === _targetIdx)
            return;
        _dir = idx > _targetIdx ? 1 : -1;
        _targetIdx = idx;
        inAnim.stop();
        if (!outAnim.running)
            outAnim.start();
    }

    function _swap() {
        shownIdx = _targetIdx;
        gridHolder.x = slide * _dir;
        gridHolder.opacity = 0;
        inAnim.restart();
    }

    function _jump() {
        outAnim.stop();
        inAnim.stop();
        gridHolder.x = 0;
        gridHolder.opacity = 1;
        today = new Date();
        _targetIdx = todayIdx;
        shownIdx = todayIdx;
        selectedDate = today;
    }

    function _rollover() {
        const wasToday = selKey === todayKey;
        const wasCurrent = shownIdx === todayIdx;
        today = new Date();
        if (wasCurrent) {
            _targetIdx = todayIdx;
            shownIdx = todayIdx;
        }
        if (wasToday)
            selectedDate = today;
    }

    function _goToday() {
        _navigate(todayIdx);
        selectedDate = today;
        daySelected(selectedDate);
    }

    function _pick(c) {
        _navigate(c.y * 12 + c.m);
        selectedDate = new Date(c.y, c.m, c.d);
        daySelected(selectedDate);
    }

    ParallelAnimation {
        id: outAnim
        onFinished: root._swap()

        NumberAnimation {
            target: gridHolder
            property: "x"
            to: -root.slide * root._dir
            duration: 100
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: gridHolder
            property: "opacity"
            to: 0
            duration: 100
            easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: inAnim

        NumberAnimation {
            target: gridHolder
            property: "x"
            to: 0
            duration: 160
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: gridHolder
            property: "opacity"
            to: 1
            duration: 160
            easing.type: Easing.OutCubic
        }
    }

    Connections {
        target: LocaleService
        function onLiveFullDateChanged() {
            root._rollover();
        }
    }

    Timer {
        id: wheelCooldown
        interval: 200
    }

    Item {
        id: header
        x: root.gridX
        width: root.gridW
        height: root.navSize

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 3 * (root.navSize + 4) - 8
            elide: Text.ElideRight
            text: LocaleService.monthYear(root.shownYear, root.shownMonth)
            color: Colors.md3.on_surface
            font.family: Config.fontFamily
            font.pixelSize: 14
            font.weight: Font.Medium
            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
        }

        Repeater {
            model: root.navSpec

            delegate: Rectangle {
                id: navBtn
                required property var modelData
                required property int index

                x: root.gridW - root.navSize - (2 - index) * (root.navSize + 4)
                anchors.verticalCenter: parent.verticalCenter
                width: root.navSize
                height: root.navSize
                topLeftRadius: index === 2 ? 6 : height / 2
                bottomLeftRadius: index === 2 ? 6 : height / 2
                topRightRadius: index === 1 ? 6 : height / 2
                bottomRightRadius: index === 1 ? 6 : height / 2
                color: navMa.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high
                opacity: index === 0 && root.shownIdx === root.todayIdx ? 0 : 1
                visible: opacity > 0

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }

                Accessible.role: Accessible.Button
                Accessible.name: Localization.t(navBtn.modelData.label)

                MaterialIcon {
                    anchors.centerIn: parent
                    name: navBtn.modelData.icon
                    iconSize: 18
                    color: Colors.md3.on_surface
                    scale: navMa.pressed ? 0.85 : 1
                    Behavior on scale {
                        NumberAnimation {
                            duration: 100
                        }
                    }
                }

                MouseArea {
                    id: navMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: navBtn.modelData.run()
                }
            }
        }
    }

    Item {
        x: root.gridX
        y: 40
        width: root.gridW
        height: 24

        Repeater {
            model: 7

            Text {
                required property int index
                x: index * root.cellSize
                width: root.cellSize
                horizontalAlignment: Text.AlignHCenter
                text: LocaleService.weekdayName(root._qtDow(index), Locale.NarrowFormat)
                color: Colors.md3.on_surface_variant
                font.family: Config.fontFamily
                font.pixelSize: 12
                font.weight: Font.Medium
                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }
        }
    }

    Item {
        id: gridHolder
        y: 64
        width: root.width
        height: 6 * root.cellHeight
        clip: true

        WheelHandler {
            onWheel: event => {
                if (wheelCooldown.running)
                    return;
                root._navigate(root._targetIdx + (event.angleDelta.y > 0 ? -1 : 1));
                wheelCooldown.restart();
            }
        }

        Rectangle {
            id: indicator
            x: root.gridX + (root._slot % 7) * root.cellSize + root.inset
            y: Math.floor(root._slot / 7) * root.cellHeight + root.insetY
            width: root.circleSize
            height: root.pillHeight
            radius: height / 2
            color: root.selKey === root.todayKey ? Colors.md3.primary : Colors.md3.secondary_container
            opacity: root.selIdx >= 0 ? 1 : 0

            Behavior on x {
                NumberAnimation {
                    duration: 240
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on y {
                NumberAnimation {
                    duration: 240
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }
            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
        }

        Repeater {
            model: root.cells

            delegate: Item {
                id: cellItem
                required property var modelData
                required property int index
                readonly property bool isToday: modelData.key === root.todayKey
                readonly property bool isSel: modelData.key === root.selKey
                readonly property bool hasEvents: (root.eventCounts[modelData.key] ?? 0) > 0
                readonly property color onCover: isToday ? Colors.md3.on_primary : isSel ? Colors.md3.on_secondary_container : Colors.md3.primary

                x: root.gridX + (index % 7) * root.cellSize
                y: Math.floor(index / 7) * root.cellHeight
                width: root.cellSize
                height: root.cellHeight

                Rectangle {
                    anchors.centerIn: parent
                    width: root.circleSize
                    height: root.pillHeight
                    radius: height / 2
                    color: Colors.md3.primary
                    visible: cellItem.isToday
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: root.circleSize
                    height: root.pillHeight
                    radius: height / 2
                    color: Colors.md3.on_surface
                    opacity: dayMa.containsMouse ? 0.08 : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 100
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: cellItem.modelData.d
                    font.family: Config.fontFamily
                    font.pixelSize: 14
                    color: cellItem.isToday ? Colors.md3.on_primary : cellItem.isSel ? Colors.md3.on_secondary_container : cellItem.modelData.inMonth ? Colors.md3.on_surface : Colors.md3.on_surface_variant
                    opacity: cellItem.modelData.inMonth ? 1 : 0.38
                    scale: dayMa.pressed ? 0.92 : 1
                    Behavior on scale {
                        NumberAnimation {
                            duration: 100
                        }
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: root.cellHeight / 2 + 8
                    width: 4
                    height: 4
                    radius: 2
                    color: cellItem.onCover
                    visible: cellItem.hasEvents
                    opacity: cellItem.modelData.inMonth ? 1 : 0.38
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }

                MouseArea {
                    id: dayMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root._pick(cellItem.modelData)
                }
            }
        }
    }
}
