pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.style
import "calendar.js" as Cal
import "holidays.js" as Holidays

Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.local/share/israshell/calendar"
    readonly property string _personalId: root.dir + "/personal"
    readonly property string _holidaysId: "holidays"
    readonly property var roots: root._roots()
    readonly property string rootsKey: JSON.stringify(root.roots)
    readonly property string holidayRegion: Config.calendar.holidayRegion !== "" ? Config.calendar.holidayRegion : Holidays.regionFor(Config.language)
    readonly property var writableCalendars: root._cals.map(c => Object.assign({}, c, { own: c.root === root.dir, hidden: Config.calendar.hidden.includes(c.id) }))
    readonly property var calendars: root.writableCalendars.concat(root.holidayRegion === "" ? [] : [{ id: root._holidaysId, name: Localization.t("calendarPage.holidays"), color: Colors.md3.tertiary.toString(), root: "", own: false, hidden: !Config.calendar.holidays, readOnly: true }])
    readonly property var events: root._events
    readonly property bool loading: loadProc.running || root._job !== null
    readonly property bool syncAvailable: root._hasSync
    readonly property bool syncing: syncProc.running
    readonly property string syncError: root._syncError
    readonly property real lastSync: root._lastSync

    property var _cals: [{ id: root._personalId, name: "Personal", color: "", root: root.dir }]
    property var _events: []
    property var _queue: []
    property var _job: null
    property bool _reloadPending: false
    property bool _hasSync: false
    property string _syncError: ""
    property real _lastSync: 0

    signal changed()

    onRootsKeyChanged: root.reload()

    readonly property string _scan: 'for d; do d=$(cd -- "$d" 2>/dev/null && pwd) || continue; printf "%s\\n" "@@ROOT@@$d"; ' +
        'for c in "$d"/*/; do [ -d "$c" ] || continue; c=${c%/}; printf "%s\\n" "@@CAL@@$c"; ' +
        'if [ -f "$c/displayname" ]; then echo "@@META@@name"; printf "%s\\n" "$(head -n 1 "$c/displayname")"; fi; ' +
        'if [ -f "$c/color" ]; then echo "@@META@@color"; printf "%s\\n" "$(head -n 1 "$c/color")"; fi; ' +
        'for f in "$c"/*.ics; do [ -f "$f" ] || continue; printf "%s\\n" "@@FILE@@${f##*/}"; cat "$f" 2>/dev/null; echo; done; done; done'
    readonly property string _writeScript: 'set -e; d="$1"; mkdir -p -- "$d"; printf "%s" "$3" > "$d/$2.tmp"; mv -f -- "$d/$2.tmp" "$d/$2"; shift 3; for o; do rm -f -- "$o"; done'
    readonly property string _rmScript: 'for o; do rm -f -- "$o"; done'

    function _safe(s) {
        return String(s).replace(/[^A-Za-z0-9._@-]/g, "_").replace(/^\./, "_");
    }

    function _roots() {
        const home = Quickshell.env("HOME");
        const extra = Config.calendar.roots.map(r => String(r).replace(/^~(?=\/|$)/, home).replace(/(.)\/+$/, "$1"));
        return [root.dir].concat(extra).filter((r, i, all) => r !== "" && all.indexOf(r) === i);
    }

    function _patch(changes) {
        Config.update({ calendar: Object.assign({}, Config.calendar, changes) });
    }

    function setHidden(id, hidden) {
        if (id === root._holidaysId) {
            root._patch({ holidays: !hidden });
            return;
        }
        const rest = Config.calendar.hidden.filter(x => x !== id);
        root._patch({ hidden: hidden ? rest.concat([id]) : rest });
    }

    function _parse(text) {
        const cals = [];
        const evs = [];
        let cal = null, field = "", lines = null, file = "", rootPath = "";
        const close = () => {
            if (lines && cal) {
                try {
                    for (const e of Cal.parseIcs(lines.join("\n")))
                        evs.push(Object.assign(e, { calendar: cal.id, file: file }));
                } catch (err) {
                }
            }
            lines = null;
        };
        for (const line of text.split("\n")) {
            if (line.startsWith("@@FILE@@")) {
                close();
                file = line.slice(8);
                lines = [];
            } else if (line.startsWith("@@ROOT@@")) {
                close();
                rootPath = line.slice(8);
            } else if (line.startsWith("@@CAL@@")) {
                close();
                cal = { id: line.slice(7), name: "", color: "", root: rootPath };
                cals.push(cal);
                field = "";
            } else if (line.startsWith("@@META@@")) {
                field = line.slice(8);
            } else if (field) {
                cal[field] = line.trim();
                field = "";
            } else if (lines) {
                lines.push(line);
            }
        }
        close();
        return { cals: cals, evs: evs };
    }

    function _apply(text) {
        const p = root._parse(text);
        const cals = p.cals.map(c => ({
            id: c.id,
            name: c.name || (c.id === root._personalId ? "Personal" : c.id.slice(c.id.lastIndexOf("/") + 1)),
            color: c.color,
            root: c.root
        }));
        const personal = cals.find(c => c.id === root._personalId) || { id: root._personalId, name: "Personal", color: "", root: root.dir };
        root._cals = [personal].concat(cals.filter(c => c.id !== root._personalId));
        root._events = p.evs;
        root.changed();
    }

    function reload(): void {
        probeProc.running = true;
        if (loadProc.running || root._job !== null || root._queue.length > 0) {
            root._reloadPending = true;
            return;
        }
        root._reloadPending = false;
        loadProc.running = true;
    }

    function _enqueue(command, label, cb) {
        root._queue.push({ command: command, label: label, cb: cb });
        Qt.callLater(root._pump);
    }

    function _pump() {
        if (root._job !== null)
            return;
        const job = root._queue.shift();
        if (!job) {
            root.reload();
            return;
        }
        root._job = job;
        writeProc.command = job.command;
        writeProc.running = true;
    }

    function occurrences(fromMs, toMs) {
        const colors = {};
        for (const c of root.calendars)
            colors[c.id] = c.color;
        const own = Cal.expand(root.events.filter(x => !Config.calendar.hidden.includes(x.calendar)), fromMs, toMs);
        const hol = Config.calendar.holidays ? Holidays.between(root.holidayRegion, fromMs, toMs) : [];
        return own.concat(hol).map(o => Object.assign(o, { color: colors[o.calendar] || "" }));
    }

    function byDay(fromMs, toMs) {
        return Cal.groupByDay(root.occurrences(fromMs, toMs));
    }

    function save(ev, done) {
        const e = Object.assign({}, ev);
        if (!e.uid)
            e.uid = Cal.newUid();
        e.calendar = root._cals.some(c => c.id === e.calendar) ? e.calendar : root._personalId;
        const same = root.events.find(x => x.uid === e.uid && x.calendar === e.calendar);
        const file = same ? same.file : root._safe(e.uid) + ".ics";
        const stale = root.events.filter(x => x.uid === e.uid && x.calendar !== e.calendar).map(x => x.calendar + "/" + x.file);
        root._enqueue(["sh", "-c", root._writeScript, "sh", e.calendar, file, Cal.serializeEvent(e)].concat(stale), file, ok => {
            if (done)
                done(ok, e);
        });
    }

    function remove(uid, done) {
        const paths = root.events.filter(x => x.uid === uid).map(x => x.calendar + "/" + x.file);
        if (paths.length === 0) {
            if (done)
                done(false);
            return;
        }
        root._enqueue(["sh", "-c", root._rmScript, "sh"].concat(paths), uid, ok => {
            if (done)
                done(ok);
        });
    }

    function removeOccurrence(uid, startMs, done) {
        const ev = root.events.find(x => x.uid === uid);
        if (!ev) {
            if (done)
                done(false);
            return;
        }
        root.save(Cal.withExdate(ev, startMs), done);
    }

    function sync() {
        if (!root.syncAvailable || syncProc.running)
            return;
        syncProc.running = true;
    }

    Process {
        id: loadProc
        command: ["sh", "-c", root._scan, "sh"].concat(root.roots)
        stdout: StdioCollector {
            onStreamFinished: root._apply(text)
        }
        onExited: {
            if (root._reloadPending)
                root.reload();
        }
    }

    Process {
        id: probeProc
        command: ["sh", "-c", "command -v vdirsyncer >/dev/null 2>&1"]
        onExited: (code) => {
            root._hasSync = code === 0;
        }
    }

    Process {
        id: syncProc
        command: ["vdirsyncer", "sync"]
        stderr: StdioCollector {
            id: syncErr
        }
        onExited: (code) => {
            if (code === 0) {
                root._lastSync = Date.now();
                root._syncError = "";
                root.reload();
                return;
            }
            root._syncError = syncErr.text.trim().split("\n").pop().trim() || ("exit " + code);
        }
    }

    Timer {
        interval: Math.max(1, Config.calendar.syncMinutes) * 60000
        running: Config.calendar.autoSync && root.syncAvailable
        repeat: true
        onTriggered: root.sync()
    }

    Process {
        id: writeProc
        onExited: (code, status) => {
            const job = root._job;
            root._job = null;
            if (code !== 0)
                console.warn("calendar: write failed:", job.label);
            job.cb(code === 0);
            Qt.callLater(root._pump);
        }
    }

    Component.onCompleted: root.reload()
}
