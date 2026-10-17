pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import qs.style
import "screentime.js" as ST

Singleton {
    id: root

    readonly property var cfg: Config.screentime
    readonly property bool enabled: root.cfg.enabled
    readonly property bool paused: root.cfg.paused
    readonly property bool tracking: root.enabled && !root.paused
    readonly property bool idle: idleMonitor.isIdle
    readonly property bool locked: LockscreenService.locked
    readonly property bool recording: root._credit
    readonly property bool loaded: root._loaded
    readonly property string dir: Quickshell.env("HOME") + "/.local/share/israshell/screentime"

    property string storageError: ""
    property var today: ST.summarize([], {})
    property var view: ST.summarize([], {})
    property var viewDays: []
    property real averageSecs: 0
    property string range: "day"
    property bool viewLoading: false
    property int viewConsumers: 0

    signal exported(string path)
    signal exportFailed()
    signal dataDeleted()

    readonly property var optionSpec: ({
            enabled: { type: "bool" },
            paused: { type: "bool" },
            appFocus: { type: "bool" },
            hourly: { type: "bool" },
            workspaces: { type: "bool" },
            fullscreen: { type: "bool" },
            media: { type: "bool" },
            notifications: { type: "bool" },
            unlocks: { type: "bool" },
            windowTitles: { type: "bool" },
            idleSeconds: { type: "int", min: 30, max: 3600 },
            retentionDays: { type: "int", min: 0, max: 3650 }
        })

    readonly property string _keyCmd: 'K=$(printf "%s" "$(cat /etc/machine-id 2>/dev/null || echo nomachineid):$(id -un):screentime" | openssl dgst -sha256 -binary | od -An -tx1 | tr -d " \\n"); export K; '
    readonly property string _readScript: '[ -f "$1" ] || exit 4; ' + root._keyCmd + 'openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -pass env:K -base64 -in "$1"'
    readonly property string _writeScript: 'umask 077; mkdir -p -- "$(dirname -- "$2")" || exit 5; ' + root._keyCmd + 'head -c "$1" | openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt -pass env:K -base64 -out "$2.tmp" && mv -f -- "$2.tmp" "$2"'
    readonly property string _plainWriteScript: 'umask 077; head -c "$1" > "$2.tmp" && mv -f -- "$2.tmp" "$2"'

    property var _month: ST.emptyMonth()
    property string _monthKey: ST.monthKey(Date.now())
    property bool _loaded: false
    property bool _persist: true
    property bool _dirty: false
    property bool _credit: false
    property real _lastTick: Date.now()
    property real _run: 0
    property var _cur: ({ app: "", raw: "", ws: -1, fs: false, title: "" })
    property var _lastSeen: ({})
    property var _meta: ({})
    property int _metaRev: 0
    property var _prev: null
    property var _queue: []
    property var _job: null
    property bool _gotText: false
    property bool _gotExit: false
    property string _jobText: ""
    property int _jobCode: -1

    function todayKey(): string {
        return ST.dayKey(Date.now());
    }

    function _norm(id: string): string {
        return String(id || "").trim().toLowerCase();
    }

    function _lookup(id: string): var {
        root._metaRev;
        let m = root._meta[id];
        if (m)
            return m;
        if (Object.keys(root._meta).length > 300)
            root._meta = ({});
        const e = id === ST.UNATTRIBUTED ? null : DesktopEntries.heuristicLookup(id);
        m = { name: e && e.name ? e.name : id, icon: e && e.icon ? e.icon : "", categories: e && e.categories ? Array.from(e.categories) : [] };
        if (e || id === ST.UNATTRIBUTED)
            root._meta[id] = m;
        return m;
    }

    function appName(id: string): string {
        return id === ST.UNATTRIBUTED ? Localization.t("screenTime.unattributed") : root._lookup(id).name;
    }

    function appIcon(id: string): string {
        return root._lookup(id).icon;
    }

    function categoryOf(id: string): string {
        return ST.categoryFor(root._lookup(id).categories, root.cfg.categoryOverrides[id] || "", id);
    }

    function categoryColor(cat: string): color {
        switch (cat) {
        case "work":
            return Colors.md3.primary;
        case "web":
            return Colors.md3.secondary;
        case "fun":
            return Colors.md3.tertiary;
        }
        return Colors.md3.outline;
    }

    function _ctx(): var {
        return { excluded: root.cfg.excluded, categoryOf: id => root.categoryOf(id) };
    }

    function _patch(changes: var): void {
        Config.update({ screentime: Object.assign({}, Config.screentime, changes) });
    }

    function setOption(key: string, value: var): string {
        const spec = root.optionSpec[key];
        if (!spec)
            return "error: unknown option " + key;
        let v = value;
        if (spec.type === "bool") {
            if (typeof v === "string")
                v = v === "true" || v === "1" || v === "on";
            v = !!v;
        } else {
            v = Math.round(Number(v));
            if (!isFinite(v) || v < spec.min || v > spec.max)
                return "error: " + key + " must be " + spec.min + ".." + spec.max;
        }
        root._patch({ [key]: v });
        return "ok";
    }

    function pause(): void {
        root._patch({ paused: true });
    }

    function resume(): void {
        root._patch({ paused: false });
    }

    function toggle(): void {
        root._patch({ paused: !root.paused });
    }

    function exclude(id: string): void {
        const n = root._norm(id);
        if (n === "" || root.cfg.excluded.indexOf(n) >= 0)
            return;
        root._patch({ excluded: root.cfg.excluded.concat([n]) });
        root._refresh();
    }

    function include(id: string): void {
        root._patch({ excluded: root.cfg.excluded.filter(x => x !== id) });
        root._refresh();
    }

    function setCategory(id: string, category: string): void {
        const next = Object.assign({}, root.cfg.categoryOverrides);
        if (ST.CATEGORIES.indexOf(category) < 0)
            delete next[id];
        else
            next[id] = category;
        root._patch({ categoryOverrides: next });
        root._refresh();
    }

    function statusJson(): string {
        return JSON.stringify({
            enabled: root.enabled,
            paused: root.paused,
            tracking: root.tracking,
            recording: root.recording,
            idle: root.idle,
            locked: root.locked,
            loaded: root.loaded,
            storageError: root.storageError,
            todaySeconds: Math.round(root.today.total),
            todayApps: root.today.apps.length,
            options: root.cfg
        });
    }

    function todayJson(): string {
        const t = root.today;
        return JSON.stringify({
            hasData: t.hasData,
            seconds: Math.round(t.total),
            unlocks: t.unlocks,
            notifications: t.notifications,
            longest: Math.round(t.longest),
            categories: t.categories,
            apps: t.apps.slice(0, 20).map(a => ({ id: a.id, name: root.appName(a.id), category: a.category, seconds: Math.round(a.seconds), sessions: a.sessions, notifications: a.notifications }))
        });
    }

    function registerView(): void {
        root.viewConsumers += 1;
        root._ensureView();
    }

    function unregisterView(): void {
        root.viewConsumers = Math.max(0, root.viewConsumers - 1);
        if (root.viewConsumers === 0) {
            root._prev = null;
            root.view = ST.summarize([], {});
            root.viewDays = [];
        }
    }

    function setRange(r: string): void {
        root.range = r === "week" || r === "month" ? r : "day";
        root._rebuildView();
    }

    function refresh(): void {
        root._commit(Date.now());
        root._refresh();
    }

    function _dayFor(key: string): var {
        const mk = ST.monthOfDay(key);
        if (mk !== root._monthKey)
            root._rollover(mk);
        let d = root._month.days[key];
        if (!d) {
            d = ST.emptyDay();
            root._month.days[key] = d;
        }
        return d;
    }

    function _rollover(mk: string): void {
        root._flush();
        root._monthKey = mk;
        root._month = ST.emptyMonth();
        root._loaded = !root._persist;
        root._prev = null;
        if (root._persist)
            root._readCurrent(mk);
    }

    function _excluded(raw: string): bool {
        return root.cfg.excluded.indexOf(raw) >= 0;
    }

    function _apply(): void {
        const w = CompositorService.activeWindow;
        const raw = root._norm(w.appId);
        const app = root.cfg.appFocus ? raw : "";
        const prevRaw = root._cur.raw;
        root._cur = { app: app, raw: raw, ws: w.workspace, fs: !!w.fullscreen, title: w.title || "" };
        root._credit = root.tracking && root._loaded && !root.idle && !root.locked && raw !== "" && !root._excluded(raw);
        if (root._credit && raw !== prevRaw && app !== "") {
            const now = Date.now();
            if (now - (root._lastSeen[raw] || 0) > 30000) {
                ST.addSession(root._dayFor(ST.dayKey(now)), raw);
                root._dirty = true;
            }
        }
    }

    function _commit(now: real): void {
        if (root._credit) {
            const segs = ST.split(root._lastTick, now);
            if (segs.length === 0)
                root._run = 0;
            const c = root.cfg;
            const opts = { hourly: c.hourly, fullscreen: c.fullscreen && root._cur.fs, workspace: c.workspaces ? root._cur.ws : null, title: c.windowTitles ? root._cur.title : null };
            for (const seg of segs) {
                const day = root._dayFor(seg.day);
                ST.addUsage(day, seg, root._cur.app, opts);
                root._run += seg.secs;
                ST.noteRun(day, root._run);
                root._dirty = true;
            }
            if (segs.length > 0) {
                if (Object.keys(root._lastSeen).length > 200)
                    root._lastSeen = ({});
                root._lastSeen[root._cur.raw] = now;
            }
        } else {
            root._run = 0;
        }
        root._creditMedia(now);
        root._lastTick = now;
    }

    function _creditMedia(now: real): void {
        if (!root.tracking || !root.cfg.media || !root._loaded)
            return;
        const secs = (now - root._lastTick) / 1000;
        if (!(secs > 0) || secs > ST.GAP_CAP)
            return;
        const playing = Mpris.players.values.filter(p => p.isPlaying);
        if (playing.length === 0)
            return;
        const day = root._dayFor(ST.dayKey(now));
        for (const p of playing)
            ST.addMedia(day, p.identity || "", secs / playing.length);
        root._dirty = true;
    }

    function _sync(): void {
        root._commit(Date.now());
        root._apply();
    }

    function _noteNotification(n: var): void {
        if (!root.tracking || !root.cfg.notifications || !root._loaded)
            return;
        const id = root._norm(n.desktopEntry || n.appName);
        if (id === "" || root._excluded(id))
            return;
        ST.addNotification(root._dayFor(root.todayKey()), root.cfg.appFocus ? id : "");
        root._dirty = true;
    }

    function _noteUnlock(): void {
        if (!root.tracking || !root.cfg.unlocks || !root._loaded)
            return;
        ST.addUnlock(root._dayFor(root.todayKey()));
        root._dirty = true;
    }

    function _refresh(): void {
        const key = root.todayKey();
        root.today = ST.summarize([{ key: key, day: root._month.days[key] || null }], root._ctx());
        if (root.viewConsumers > 0)
            root._rebuildView();
    }

    function _dayOf(key: string): var {
        const mk = ST.monthOfDay(key);
        if (mk === root._monthKey)
            return root._month.days[key] || null;
        if (root._prev && root._prev.key === mk)
            return root._prev.month.days[key] || null;
        return null;
    }

    function _rebuildView(): void {
        const today = root.todayKey();
        const entries = [];
        for (let i = 29; i >= 0; i--) {
            const k = ST.addDays(today, -i);
            entries.push({ key: k, day: root._dayOf(k) });
        }
        const n = root.range === "week" ? 7 : (root.range === "month" ? 30 : 1);
        const slice = entries.slice(-n);
        const ctx = root._ctx();
        root.view = ST.summarize(slice, ctx);
        root.viewDays = ST.perDay(slice, ctx);
        root.averageSecs = ST.average(ST.perDay(entries.slice(-8), ctx), today);
    }

    function _ensureView(): void {
        const today = root.todayKey();
        const oldest = ST.monthOfDay(ST.addDays(today, -29));
        if (oldest === root._monthKey || !root._persist || (root._prev && root._prev.key === oldest)) {
            root._rebuildView();
            return;
        }
        root.viewLoading = true;
        root._enqueue({
            cmd: ["sh", "-c", root._readScript, "sh", root._path(oldest)],
            done: (code, text) => {
                const parsed = code === 0 ? ST.parseMonth(text) : null;
                if (root.viewConsumers > 0)
                    root._prev = { key: oldest, month: parsed || ST.emptyMonth() };
                root.viewLoading = false;
                root._rebuildView();
            }
        });
        root._rebuildView();
    }

    function _path(mk: string): string {
        return root.dir + "/" + mk + ".enc";
    }

    function _enqueue(job: var): void {
        root._queue.push(job);
        root._next();
    }

    function _next(): void {
        if (root._job !== null || root._queue.length === 0)
            return;
        root._job = root._queue.shift();
        root._gotText = false;
        root._gotExit = false;
        root._jobText = "";
        io.command = root._job.cmd;
        io.running = true;
        watchdog.restart();
    }

    function _tryFinish(): void {
        if (!root._gotText || !root._gotExit || root._job === null)
            return;
        watchdog.stop();
        const job = root._job;
        root._job = null;
        if (job.done)
            job.done(root._jobCode, root._jobText);
        root._next();
    }

    function _readCurrent(mk: string): void {
        root._enqueue({
            cmd: ["sh", "-c", root._readScript, "sh", root._path(mk)],
            done: (code, text) => {
                if (mk !== root._monthKey)
                    return;
                let parsed = null;
                if (code === 0) {
                    parsed = ST.parseMonth(text);
                    if (!parsed)
                        root._quarantine(mk);
                } else if (code !== 4) {
                    root._quarantine(mk);
                }
                if (parsed) {
                    for (const k of Object.keys(parsed.days)) {
                        const live = root._month.days[k];
                        root._month.days[k] = live ? ST.mergeDay(parsed.days[k], live) : parsed.days[k];
                    }
                }
                root._loaded = true;
                root._apply();
                root._refresh();
            }
        });
    }

    function _quarantine(mk: string): void {
        root.storageError = "unreadable";
        root._enqueue({ cmd: ["sh", "-c", 'mv -f -- "$1" "$1.bad-$(date +%s)"', "sh", root._path(mk)] });
    }

    function _flush(): void {
        if (!root._persist || !root._loaded || !root._dirty)
            return;
        root._dirty = false;
        const payload = ST.serializeMonth(root._month);
        root._enqueue({
            cmd: ["sh", "-c", root._writeScript, "sh", String(payload.length), root._path(root._monthKey)],
            stdin: payload,
            done: code => {
                if (code !== 0) {
                    root.storageError = "write";
                    root._dirty = true;
                } else if (root.storageError === "write") {
                    root.storageError = "";
                }
            }
        });
    }

    function _start(): void {
        root._enqueue({
            cmd: ["sh", "-c", "command -v openssl >/dev/null 2>&1"],
            done: code => {
                if (code !== 0) {
                    root._persist = false;
                    root._loaded = true;
                    root.storageError = "openssl";
                    root._apply();
                    root._refresh();
                    return;
                }
                root._readCurrent(root._monthKey);
                root._enqueue({
                    cmd: ["sh", "-c", 'ls -1 -- "$1" 2>/dev/null', "sh", root.dir],
                    done: (c, text) => {
                        const months = text.split("\n").map(f => f.replace(/\.enc$/, "")).filter(f => /^\d{4}-\d{2}$/.test(f));
                        const old = ST.pruneable(months, Date.now(), root.cfg.retentionDays);
                        if (old.length > 0)
                            root._enqueue({ cmd: ["sh", "-c", 'for f; do rm -f -- "$f"; done', "sh"].concat(old.map(m => root._path(m))) });
                    }
                });
            }
        });
    }

    function deleteAll(): void {
        root._queue = [];
        root._enqueue({
            cmd: ["sh", "-c", 'rm -rf -- "$1"', "sh", root.dir],
            done: () => {
                root._month = ST.emptyMonth();
                root._prev = null;
                root._dirty = false;
                root.storageError = "";
                root._refresh();
                root.dataDeleted();
            }
        });
    }

    function exportData(): void {
        root._flush();
        root._enqueue({
            cmd: ["sh", "-c", 'ls -1 -- "$1" 2>/dev/null', "sh", root.dir],
            done: (code, text) => {
                const months = text.split("\n").map(f => f.replace(/\.enc$/, "")).filter(f => /^\d{4}-\d{2}$/.test(f));
                const out = { version: 1, exported: Date.now(), months: {} };
                const step = i => {
                    if (i >= months.length) {
                        root._writeExport(out);
                        return;
                    }
                    root._enqueue({
                        cmd: ["sh", "-c", root._readScript, "sh", root._path(months[i])],
                        done: (c, t) => {
                            const parsed = c === 0 ? ST.parseMonth(t) : null;
                            if (parsed)
                                out.months[months[i]] = parsed;
                            step(i + 1);
                        }
                    });
                };
                step(0);
            }
        });
    }

    function _writeExport(data: var): void {
        const stamp = new Date().toISOString().replace(/[-:T]/g, "").slice(0, 14);
        const path = Quickshell.env("HOME") + "/israshell-screentime-" + stamp + ".json";
        const payload = ST.asciiJson(data);
        root._enqueue({
            cmd: ["sh", "-c", root._plainWriteScript, "sh", String(payload.length), path],
            stdin: payload,
            done: code => {
                if (code === 0)
                    root.exported(path);
                else
                    root.exportFailed();
            }
        });
    }

    Process {
        id: io
        stdinEnabled: true
        stdout: StdioCollector {
            onStreamFinished: {
                root._jobText = this.text;
                root._gotText = true;
                root._tryFinish();
            }
        }
        onStarted: {
            if (root._job && root._job.stdin !== undefined)
                io.write(root._job.stdin);
        }
        onExited: code => {
            root._jobCode = code;
            root._gotExit = true;
            root._tryFinish();
        }
    }

    Timer {
        id: watchdog
        interval: 20000
        onTriggered: io.signal(9)
    }

    IdleMonitor {
        id: idleMonitor
        enabled: root.tracking
        timeout: root.cfg.idleSeconds
        respectInhibitors: true
        onIsIdleChanged: root._sync()
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: {
            root._commit(Date.now());
            root._refresh();
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root._flush()
    }

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            root._meta = ({});
            root._metaRev++;
            root._refresh();
        }
    }

    Connections {
        target: CompositorService
        function onActiveWindowChanged() {
            root._sync();
        }
    }

    Connections {
        target: Config
        function onScreentimeChanged() {
            root._sync();
            root._refresh();
        }
    }

    Connections {
        target: LockscreenService
        function onLockedChanged() {
            root._sync();
        }
        function onUnlocked() {
            root._noteUnlock();
        }
    }

    Connections {
        target: NotificationService.server
        function onNotification(n) {
            root._noteNotification(n);
        }
    }

    Component.onCompleted: root._start()
}
