pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.style

Singleton {
    id: root

    readonly property bool enabled: Config.calendar.reminders !== false
    readonly property real lastCheck: root._last
    property int firedCount: 0
    property int tickMs: 30000
    property real _last: 0
    property real _saved: 0
    property int _waiting: 0
    property bool _loaded: false
    property real _started: Date.now()

    function _cmd(extra, summary, body, urgent) {
        return ["notify-send", "-u", urgent ? "critical" : "normal", "-a", "Calendar", "-h", "string:x-material-icon:calendar-month"].concat(extra, [summary, body]);
    }

    function _lead(m) {
        const num = x => String(+x.toFixed(1));
        if (m === 0)
            return Localization.t("calendarReminder.starting_now");
        if (m < 60)
            return Localization.t("calendarReminder.in_minutes").arg(m);
        if (m < 1440)
            return Localization.t("calendarReminder.in_hours").arg(num(m / 60));
        return Localization.t("calendarReminder.in_days").arg(num(m / 1440));
    }

    function _fire(occ) {
        root.firedCount++;
        const time = occ.allDay ? Localization.t("calendar.allDay") : LocaleService.formatClockTime(new Date(occ.start)) + " – " + LocaleService.formatClockTime(new Date(occ.end));
        const body = root._lead(occ.reminder) + " · " + time + (occ.location ? " · " + occ.location : "");
        if (!occ.link || root._waiting >= 8) {
            Quickshell.execDetached(root._cmd([], occ.title, body, occ.urgent));
            return;
        }
        const p = joinComponent.createObject(root, {
            command: root._cmd(["--wait", "--action=join=" + Localization.t("calendarReminder.join")], occ.title, body, occ.urgent),
            link: occ.link,
            running: true
        });
        root._waiting++;
        p.exited.connect(() => {
            if (p.stdout.text.trim() === "join")
                Qt.openUrlExternally(p.link);
            root._waiting--;
            p.destroy();
        });
    }

    function _tick() {
        if (!root._loaded || CalendarService.loading)
            return;
        const now = Date.now();
        if (root._last === 0)
            root._last = root._saved > 0 ? Math.max(root._saved, now - 600000) : root._started;
        const from = root._last;
        const before = root.firedCount;
        for (const occ of CalendarService.occurrences(from, now + 90000000)) {
            const fireAt = occ.start - occ.reminder * 60000;
            if (occ.reminder >= 0 && fireAt > from && fireAt <= now)
                root._fire(occ);
        }
        root._last = now;
        if (root.firedCount !== before)
            stateFile.setText(JSON.stringify({lastCheck: now}));
    }

    function _loadState() {
        try {
            root._saved = Number(JSON.parse(stateFile.text()).lastCheck) || 0;
        } catch (e) {
            root._saved = 0;
        }
    }

    function test() {
        Quickshell.execDetached(root._cmd([], Localization.t("calendarReminder.test_title"), Localization.t("calendarReminder.test_body")));
    }

    Component {
        id: joinComponent
        Process {
            property string link
            stdout: StdioCollector {}
        }
    }

    FileView {
        id: stateFile
        path: Config.configDir + "/calendar_reminders.json"
        watchChanges: false
        blockLoading: true
        printErrors: false
        Component.onCompleted: root._loadState()
    }

    onEnabledChanged: {
        if (!root.enabled) {
            root._last = 0;
            root._saved = 0;
            root._started = Date.now();
        }
    }

    Connections {
        target: CalendarService
        function onChanged() {
            root._loaded = true;
        }
    }

    Timer {
        interval: root.tickMs
        running: root.enabled
        repeat: true
        triggeredOnStart: true
        onTriggered: root._tick()
    }

    Timer {
        interval: 300000
        running: root.enabled
        repeat: true
        onTriggered: CalendarService.reload()
    }

    Component.onCompleted: {
        if (root.enabled)
            CalendarService.reload();
    }
}
