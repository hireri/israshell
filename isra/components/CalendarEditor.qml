pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import qs.style
import qs.icons
import qs.services
import qs.windows.components

FocusScope {
    id: root

    property var event: null
    property date day: new Date()
    property var calendars: []

    signal saved(var ev)
    signal deleted(var ev, bool onlyThis)
    signal cancelled()

    readonly property int titleH: 44
    readonly property int footH: 40
    readonly property int rowH: Math.max(28, Math.min(40, Math.floor((root.height - titleH - footH - rowCount * 6) / (rowCount - 1))))
    readonly property int rowCount: 8 + (root.calendars.length > 1 ? 1 : 0)
    readonly property real contentH: titleH + (rowCount - 1) * rowH
    readonly property real gap: Math.max(6, Math.min(16, Math.floor((root.height - contentH - footH) / rowCount)))
    readonly property bool recurring: !!(root.event && root.event.recurring)
    readonly property bool canSave: root._title.trim() !== ""
    readonly property int timeW: Config.hourFormat === 0 ? 60 : 72

    property date _day: new Date()
    property bool _allDay: false
    property int _startMin: 540
    property int _endMin: 600
    property string _freq: ""
    property int _reminder: -1
    property bool _urgent: false
    property string _calendar: ""
    property string _title: ""
    property string _location: ""
    property string _notes: ""
    property bool _deleting: false

    readonly property var groups: [
        {
            id: "repeat",
            label: Localization.t("calendarEditor.repeat"),
            items: [
                {value: "", label: Localization.t("calendarEditor.repeatNone")},
                {value: "DAILY", label: Localization.t("calendarEditor.daily")},
                {value: "WEEKLY", label: Localization.t("calendarEditor.weekly")},
                {value: "MONTHLY", label: Localization.t("calendarEditor.monthly")},
                {value: "YEARLY", label: Localization.t("calendarEditor.yearly")}
            ]
        },
        {
            id: "reminder",
            label: Localization.t("calendarEditor.reminder"),
            items: [
                {value: -1, label: Localization.t("calendarEditor.reminderNone")},
                {value: 0, label: Localization.t("calendarEditor.atStart")},
                {value: 5, label: Localization.t("calendarEditor.min5")},
                {value: 15, label: Localization.t("calendarEditor.min15")},
                {value: 30, label: Localization.t("calendarEditor.min30")},
                {value: 60, label: Localization.t("calendarEditor.hour1")},
                {value: 1440, label: Localization.t("calendarEditor.day1")}
            ]
        }
    ].concat(root.calendars.length > 1 ? [{
        id: "calendar",
        label: Localization.t("calendarEditor.calendar"),
        items: root.calendars.map(c => ({value: c.id, label: c.name}))
    }] : [])

    implicitWidth: 268
    implicitHeight: 400
    width: implicitWidth
    height: implicitHeight

    Component.onCompleted: _open()
    onEventChanged: _open()
    onDayChanged: _open()
    onVisibleChanged: if (visible) _open()

    Keys.onEscapePressed: ev => {
        ev.accepted = true;
        root.cancelled();
    }

    function _open() {
        _load();
        if (visible)
            titleField.focusField();
    }

    function _mins(ms) {
        const d = new Date(ms);
        return d.getHours() * 60 + d.getMinutes();
    }

    function _load() {
        const e = root.event;
        const src = new Date(e ? (e.recurring ? e.seriesStart : e.start) : root.day);
        root._day = new Date(src.getFullYear(), src.getMonth(), src.getDate());
        root._allDay = !!(e && e.allDay);
        root._startMin = e && !e.allDay ? root._mins(e.start) : 540;
        root._endMin = e && !e.allDay ? root._mins(e.end) : 600;
        root._freq = e?.rrule?.freq ?? "";
        root._reminder = e?.reminder ?? -1;
        root._urgent = !!e?.urgent;
        root._calendar = e?.calendar ?? (root.calendars[0]?.id ?? "");
        root._title = e?.title ?? "";
        root._location = e?.location ?? "";
        root._notes = e?.description ?? "";
        root._deleting = false;
    }

    function _clock(m) {
        return LocaleService.formatClockTime(new Date(2000, 0, 1, 0, m));
    }

    function _parse(s) {
        const m = s.trim().toLowerCase().match(/^(\d{1,2})(?::?(\d{2}))?\s*([ap]m?)?$/);
        if (!m)
            return -1;
        let h = Number(m[1]);
        const mi = Number(m[2] ?? 0);
        if (m[3]) {
            if (h < 1 || h > 12)
                return -1;
            h = h % 12 + (m[3][0] === "p" ? 12 : 0);
        }
        return h < 24 && mi < 60 ? h * 60 + mi : -1;
    }

    function _minOf(w) {
        return w === "start" ? root._startMin : root._endMin;
    }

    function _setMin(w, v) {
        if (w === "start")
            root._startMin = v;
        else
            root._endMin = v;
    }

    function _nudge(w, d) {
        root._setMin(w, (root._minOf(w) + d + 1440) % 1440);
    }

    function _stepDay(n) {
        if (!root.recurring)
            root._day = new Date(root._day.getFullYear(), root._day.getMonth(), root._day.getDate() + n);
    }

    function _choice(id) {
        return id === "repeat" ? root._freq : id === "reminder" ? root._reminder : root._calendar;
    }

    function _pick(id, key) {
        if (id === "repeat")
            root._freq = key;
        else if (id === "reminder")
            root._reminder = key;
        else
            root._calendar = key;
    }

    function _save() {
        const title = root._title.trim();
        if (title === "")
            return;
        const e = root.event;
        const y = root._day.getFullYear(), mo = root._day.getMonth(), d = root._day.getDate();
        const start = root._allDay ? new Date(y, mo, d).getTime() : new Date(y, mo, d, 0, root._startMin).getTime();
        let end = root._allDay ? new Date(y, mo, d + 1).getTime() : new Date(y, mo, d, 0, root._endMin).getTime();
        if (!root._allDay && end <= start)
            end = start + 3600000;
        const freq = root._freq;
        const rrule = freq === "" ? null : e?.rrule?.freq === freq ? e.rrule : {
            freq: freq,
            interval: 1,
            count: 0,
            until: 0,
            byday: freq === "WEEKLY" ? [root._day.getDay()] : []
        };
        root.saved({
            uid: e?.uid ?? "",
            calendar: root._calendar,
            title: title,
            location: root._location.trim(),
            description: root._notes.trim(),
            start: start,
            end: end,
            allDay: root._allDay,
            rrule: rrule,
            url: e?.url ?? "",
            exdates: e?.exdates ?? [],
            reminder: root._reminder,
            urgent: root._urgent && root._reminder >= 0
        });
    }

    Flickable {
        id: body
        width: root.width
        height: root.height - root.footH - root.gap
        contentHeight: column.implicitHeight
        clip: true
        interactive: contentHeight > height
        flickDeceleration: 4000
        maximumFlickVelocity: 2200
        boundsBehavior: Flickable.DragAndOvershootBounds

        Column {
            id: column
            width: root.width
            spacing: root.gap

            TextInputField {
                id: titleField
                width: parent.width
                height: root.titleH
                radius: root.titleH / 2
                fontSize: 15
                hPadding: 16
                monospace: false
                text: root._title
                placeholder: Localization.t("calendarEditor.title")
                onEdited: t => root._title = t
                onAccepted: root._save()
            }

            Rectangle {
                id: dateRow
                width: parent.width
                height: root.rowH
                radius: height / 2
                color: Colors.md3.surface_container_high

                Repeater {
                    model: [{icon: "chevron-left", step: -1}, {icon: "chevron-right", step: 1}]

                    delegate: Rectangle {
                        id: navBtn
                        required property var modelData

                        width: root.rowH - 8
                        height: root.rowH - 8
                        radius: height / 2
                        anchors.verticalCenter: parent.verticalCenter
                        x: modelData.step < 0 ? 4 : dateRow.width - width - 4
                        color: navMa.containsMouse ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high
                        opacity: root.recurring ? 0.38 : 1
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }

                        MaterialIcon {
                            anchors.centerIn: parent
                            name: navBtn.modelData.icon
                            iconSize: 18
                            color: Colors.md3.on_surface
                            scale: navMa.pressed ? 0.85 : 1
                            Behavior on scale {
                                NumberAnimation { duration: 100 }
                            }
                        }

                        MouseArea {
                            id: navMa
                            anchors.fill: parent
                            enabled: !root.recurring
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root._stepDay(navBtn.modelData.step)
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: LocaleService.formatDateMedium(root._day)
                    color: Colors.md3.on_surface
                    font.family: Config.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }
            }

            Item {
                width: parent.width
                height: root.rowH

                Row {
                    opacity: root._allDay ? 0.4 : 1
                    enabled: !root._allDay
                    height: root.rowH
                    spacing: 4
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }

                    Repeater {
                        model: ["start", "end"]

                        delegate: Row {
                            id: timeRow
                            required property string modelData
                            required property int index

                            spacing: 4

                            Text {
                                visible: timeRow.index === 1
                                width: 8
                                height: root.rowH
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text: "–"
                                color: Colors.md3.on_surface_variant
                                font.family: Config.fontFamily
                                font.pixelSize: 13
                            }

                            TextField {
                                id: timeField
                                width: root.timeW
                                height: root.rowH
                                leftPadding: 0
                                rightPadding: 0
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: Config.fontMonospace
                                font.pixelSize: 13
                                color: Colors.md3.on_surface
                                selectionColor: Colors.md3.primary
                                selectedTextColor: Colors.md3.on_primary
                                text: root._clock(root._minOf(timeRow.modelData))
                                background: Rectangle {
                                    radius: height / 2
                                    color: timeHover.hovered && timeField.enabled ? Colors.md3.surface_container_highest : Colors.md3.surface_container_high
                                    border.width: timeField.activeFocus ? 2 : 0
                                    border.color: Colors.md3.primary
                                    Behavior on color {
                                        ColorAnimation { duration: 150 }
                                    }
                                    HoverHandler {
                                        id: timeHover
                                    }
                                }

                                WheelHandler {
                                    onWheel: wheel => root._nudge(timeRow.modelData, wheel.angleDelta.y > 0 ? 5 : -5)
                                }
                                Keys.onEscapePressed: ev => {
                                    ev.accepted = true;
                                    focus = false;
                                }
                                Keys.onUpPressed: root._nudge(timeRow.modelData, 5)
                                Keys.onDownPressed: root._nudge(timeRow.modelData, -5)
                                onEditingFinished: {
                                    const v = root._parse(text);
                                    if (v >= 0)
                                        root._setMin(timeRow.modelData, v);
                                    text = Qt.binding(() => root._clock(root._minOf(timeRow.modelData)));
                                }
                            }
                        }
                    }
                }

                Row {
                    anchors.right: parent.right
                    height: root.rowH
                    spacing: 6

                    Text {
                        height: root.rowH
                        verticalAlignment: Text.AlignVCenter
                        text: Localization.t("calendarEditor.allDay")
                        color: Colors.md3.on_surface
                        font.family: Config.fontFamily
                        font.pixelSize: 13
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }

                    Md3Switch {
                        y: (parent.height - height) / 2
                        checked: root._allDay
                        onToggled: c => root._allDay = c
                    }
                }
            }

            Repeater {
                model: root.groups

                delegate: Item {
                    id: selRow
                    required property var modelData

                    width: column.width
                    height: root.rowH

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        text: selRow.modelData.label
                        color: Colors.md3.on_surface_variant
                        font.family: Config.fontFamily
                        font.pixelSize: 13
                    }

                    SelectField {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 164
                        height: root.rowH
                        radius: root.rowH / 2
                        options: selRow.modelData.items
                        currentValue: root._choice(selRow.modelData.id)
                        onSelected: v => root._pick(selRow.modelData.id, v)
                    }
                }
            }

            Item {
                width: column.width
                height: root.rowH
                opacity: root._reminder >= 0 ? 1 : 0.4
                enabled: root._reminder >= 0

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    text: Localization.t("calendarEditor.urgent")
                    color: Colors.md3.on_surface_variant
                    font.family: Config.fontFamily
                    font.pixelSize: 13
                }

                Md3Switch {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: root._urgent && root._reminder >= 0
                    onToggled: c => root._urgent = c
                }
            }

            TextInputField {
                width: parent.width
                height: root.rowH
                radius: root.rowH / 2
                fontSize: 13
                hPadding: 16
                monospace: false
                text: root._location
                placeholder: Localization.t("calendarEditor.location")
                onEdited: t => root._location = t
            }

            TextInputField {
                width: parent.width
                height: root.rowH
                radius: root.rowH / 2
                fontSize: 13
                hPadding: 16
                monospace: false
                text: root._notes
                placeholder: Localization.t("calendarEditor.notes")
                onEdited: t => root._notes = t
            }
        }
    }

    Item {
        id: footer
        width: root.width
        height: root.footH
        anchors.bottom: parent.bottom

        Item {
            anchors.fill: parent
            opacity: root._deleting ? 0 : 1
            visible: opacity > 0
            enabled: !root._deleting
            Behavior on opacity {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }

            ActionButton {
                visible: !!root.event?.uid
                anchors.left: parent.left
                implicitHeight: root.footH
                radius: root.footH / 2
                danger: true
                label: Localization.t("calendarEditor.delete")
                onClicked: root._deleting = true
            }

            Row {
                anchors.right: parent.right
                spacing: 6

                ActionButton {
                    implicitHeight: root.footH
                    radius: root.footH / 2
                    label: Localization.t("calendarEditor.cancel")
                    onClicked: root.cancelled()
                }

                ActionButton {
                    implicitHeight: root.footH
                    radius: root.footH / 2
                    primary: true
                    enabled: root.canSave
                    label: Localization.t("calendarEditor.save")
                    onClicked: root._save()
                }
            }
        }

        Item {
            anchors.fill: parent
            opacity: root._deleting ? 1 : 0
            visible: opacity > 0
            enabled: root._deleting
            Behavior on opacity {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }

            Row {
                anchors.left: parent.left
                spacing: 6

                ActionButton {
                    visible: root.recurring
                    implicitHeight: root.footH
                    radius: root.footH / 2
                    danger: true
                    label: Localization.t("calendarEditor.deleteThis")
                    onClicked: root.deleted(root.event, true)
                }

                ActionButton {
                    visible: root.recurring
                    implicitHeight: root.footH
                    radius: root.footH / 2
                    danger: true
                    label: Localization.t("calendarEditor.deleteAll")
                    onClicked: root.deleted(root.event, false)
                }

                ActionButton {
                    visible: !root.recurring
                    implicitHeight: root.footH
                    radius: root.footH / 2
                    danger: true
                    label: Localization.t("calendarEditor.confirm")
                    onClicked: root.deleted(root.event, false)
                }
            }

            ActionButton {
                anchors.right: parent.right
                implicitHeight: root.footH
                radius: root.footH / 2
                label: Localization.t("calendarEditor.back")
                onClicked: root._deleting = false
            }
        }
    }
}
