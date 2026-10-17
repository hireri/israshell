pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.style
import "healthChecks.js" as HC
import "platform.js" as P

Singleton {
    id: root

    readonly property var cfg: Config.health
    readonly property bool enabled: root.cfg.enabled
    readonly property bool running: root._job !== "" || root._probing
    readonly property bool probed: root._probed
    readonly property real lastRun: root._lastRun

    property var platform: P.parseDetect("")
    readonly property var checkList: HC.checksFor(root.platform)

    property var results: ({})
    property var applicable: ({})
    property int consumers: 0

    readonly property var rank: ({ ok: 0, info: 1, warn: 2, bad: 3 })
    readonly property var dismissed: root.cfg.dismissed ?? ({})
    readonly property var hidden: root._hiddenIds(root.results, root.dismissed)
    readonly property int hiddenCount: Object.keys(root.hidden).length
    readonly property var groupWorst: root._groupWorst(root.results, root.applicable, root.cfg.disabledChecks, root.hidden)
    readonly property string worst: root._worstOf(Object.keys(root.groupWorst).map(g => root.groupWorst[g]))
    readonly property var attentionIds: root._attentionIds(root.results, root.applicable, root.cfg.disabledChecks, root.hidden)
    readonly property int attention: root.attentionIds.length
    readonly property var highlights: root._highlights(root.results, root.applicable, root.cfg.disabledChecks, root.hidden)

    readonly property real progress: root._total > 0 ? 1 - (root._pending.length + (root._job !== "" ? 1 : 0)) / root._total : 0

    property int _total: 0
    property bool _probed: false
    property bool _probing: false
    property real _lastRun: 0
    property string _job: ""
    property var _pending: []

    function checks(group: string): var {
        return root.checkList.filter(c => c.group === group);
    }

    function isEnabled(id: string): bool {
        return root.cfg.disabledChecks.indexOf(id) < 0;
    }

    function isApplicable(id: string): bool {
        return root.applicable[id] === true;
    }

    function result(id: string): var {
        return root.results[id] ?? null;
    }

    function _live(c: var, applicable: var, disabled: var, hidden: var): bool {
        return applicable[c.id] === true && disabled.indexOf(c.id) < 0 && hidden[c.id] !== true;
    }

    // What a finding looked like when it was dismissed. If this changes (a new failing unit, another kernel,
    // a worse severity) the dismissal no longer applies. Counts are left out on purpose so routine churn doesn't resurface it.
    function _sig(r: var): string {
        return [r.severity, (r.failed ?? []).join(","), (r.issues ?? []).length, r.installed ?? "", r.unread ?? ""].join("|");
    }

    function _hiddenIds(results: var, dismissed: var): var {
        const out = {};
        const now = Date.now();
        for (const id of Object.keys(dismissed)) {
            const d = dismissed[id];
            const r = results[id];
            if (r && d.until > now && d.sig === root._sig(r))
                out[id] = true;
        }
        return out;
    }

    function dismiss(id: string): void {
        const r = root.results[id];
        if (!r)
            return;
        const now = Date.now();
        const keep = {};
        for (const k of Object.keys(root.dismissed))
            if (root.dismissed[k].until > now)
                keep[k] = root.dismissed[k];
        keep[id] = { sig: root._sig(r), until: now + 7 * 86400000 };
        Config.update({ health: Object.assign({}, Config.health, { dismissed: keep }) });
    }

    function restoreDismissed(): void {
        Config.update({ health: Object.assign({}, Config.health, { dismissed: {} }) });
    }

    function _worstOf(list: var): string {
        let best = "ok";
        for (const s of list)
            if ((root.rank[s] ?? -1) > root.rank[best])
                best = s;
        return best;
    }

    function _groupWorst(results: var, applicable: var, disabled: var, hidden: var): var {
        const out = {};
        for (const c of root.checkList) {
            const r = results[c.id];
            if (!r || !root._live(c, applicable, disabled, hidden))
                continue;
            out[c.group] = root._worstOf([out[c.group] ?? "ok", r.severity]);
        }
        return out;
    }

    function _attentionIds(results: var, applicable: var, disabled: var, hidden: var): var {
        const out = [];
        for (const c of root.checkList) {
            const r = results[c.id];
            if (r && root._live(c, applicable, disabled, hidden) && (r.severity === "warn" || r.severity === "bad"))
                out.push(c.id);
        }
        return out;
    }

    function _t(key: string, a: var, b: var): string {
        return Localization.t("systemApp." + key).replace("%1", a).replace("%2", b);
    }

    function _highlights(results: var, applicable: var, disabled: var, hidden: var): var {
        const get = id => {
            const c = HC.byId(id, root.checkList);
            const r = results[id];
            return c && r && root._live(c, applicable, disabled, hidden) ? r : null;
        };
        const out = [];
        const add = (id, sev, icon, page, short, text) => out.push({ id: id, sev: sev, icon: icon, page: page, short: short, text: text });
        const worstMount = list => (list ?? []).reduce((a, m) => (m.pct ?? -1) > (a?.pct ?? -1) ? m : a, null);

        let r = get("svc.list");
        if (r && (r.failed?.length ?? 0) > 0)
            add("svc.list", "bad", "automation", "system", root._t("hl_failed", r.failed.length), root._t("hl_failed", r.failed.length));
        r = get("pkg.deps");
        if (r && (r.issues?.length ?? 0) > 0)
            add("pkg.deps", "bad", "inventory-2", "packages", root._t("hl_deps"), root._t("hl_deps"));
        r = get("storage.smart");
        if (r && r.passed === false)
            add("storage.smart", "bad", "folder", "storage", root._t("hl_smart"), root._t("hl_smart"));
        r = get("storage.mounts");
        let m = r ? worstMount(r.mounts) : null;
        if (m && (r.severity === "warn" || r.severity === "bad"))
            add("storage.mounts", r.severity, "folder", "storage", m.mount + " " + m.pct + "%", root._t("hl_disk", m.mount, m.pct));
        r = get("storage.inodes");
        m = r ? worstMount(r.mounts) : null;
        if (m && (r.severity === "warn" || r.severity === "bad"))
            add("storage.inodes", r.severity, "folder", "storage", m.pct + "%", root._t("hl_inodes", m.mount, m.pct));
        r = get("sys.reboot");
        if (r && r.needed)
            add("sys.reboot", "warn", "reboot", "system", root._t("hl_reboot_short"), root._t("hl_reboot"));
        r = get("hw.temps");
        if (r && (r.severity === "warn" || r.severity === "bad")) {
            const top = (r.sensors ?? []).reduce((a, x) => Math.max(a, x.celsius), 0);
            add("hw.temps", r.severity, "thermostat", "system", Math.round(top) + "°C", root._t("hl_hot", Math.round(top)));
        }
        r = get("hw.battery");
        if (r && r.severity === "warn")
            add("hw.battery", "warn", "battery", "system", root._t("hl_battery_short"), root._t("hl_battery"));
        r = get("sys.memory");
        if (r && r.severity === "warn")
            add("sys.memory", "warn", "memory", "system", root._t("hl_memory"), root._t("hl_memory"));
        r = get("sys.timesync");
        if (r && r.severity === "warn")
            add("sys.timesync", "warn", "analog-clock", "system", root._t("hl_time"), root._t("hl_time"));
        let updates = 0;
        for (const id of ["updates.repo", "updates.aur", "updates.flatpak"])
            updates += get(id)?.count ?? 0;
        if (updates > 0)
            add("updates", "info", "arrow-upward", "packages", String(updates), root._t("hl_updates", updates));
        r = get("pkg.pacnew");
        if (r && r.count > 0)
            add("pkg.pacnew", "info", "inventory-2", "packages", root._t("hl_pacnew_short", r.count), root._t("hl_pacnew", r.count));
        r = get("pkg.news");
        if (r && r.unread > 0)
            add("pkg.news", r.severity === "bad" ? "bad" : "info", "about", "packages", root._t("hl_news_short"), root._t("hl_news", r.unread));
        r = get("pkg.orphans");
        if (r && r.count > 0)
            add("pkg.orphans", "info", "inventory-2", "packages", root._t("hl_orphans_short", r.count), root._t("hl_orphans", r.count));

        return out.map((h, i) => ({ h: h, i: i })).sort((a, b) => ((a.h.sev === "bad" ? 0 : 1) - (b.h.sev === "bad" ? 0 : 1)) || a.i - b.i).map(x => x.h);
    }

    function setCheckEnabled(id: string, on: bool): void {
        const rest = root.cfg.disabledChecks.filter(x => x !== id);
        Config.update({ health: Object.assign({}, Config.health, { disabledChecks: on ? rest : rest.concat([id]) }) });
        if (on)
            root.refreshOne(id);
    }

    function setOption(key: string, value: var): string {
        if (key === "intervalMinutes") {
            const v = Math.round(Number(value));
            if (!isFinite(v) || v < 5 || v > 1440)
                return "error: intervalMinutes must be 5..1440";
            Config.update({ health: Object.assign({}, Config.health, { intervalMinutes: v }) });
            return "ok";
        }
        if (key === "enabled") {
            Config.update({ health: Object.assign({}, Config.health, { enabled: value === true || value === "true" || value === "1" }) });
            return "ok";
        }
        if (key === "barChipLevel") {
            if (value !== "info" && value !== "warn" && value !== "bad" && value !== "always")
                return "error: barChipLevel must be info, warn, bad or always";
            Config.update({ health: Object.assign({}, Config.health, { barChipLevel: value }) });
            return "ok";
        }
        return "error: unknown option " + key;
    }

    function registerView(): void {
        root.consumers += 1;
        if (root.enabled && root._probed && Date.now() - root._lastRun > 120000)
            root.refresh();
    }

    function unregisterView(): void {
        root.consumers = Math.max(0, root.consumers - 1);
    }

    function refresh(): void {
        if (!root.enabled || !root._probed)
            return;
        root._lastRun = Date.now();
        for (const c of root.checkList)
            root._schedule(c.id);
        root._total = root._pending.length + (root._job !== "" ? 1 : 0);
    }

    function refreshOne(id: string): void {
        if (root.enabled && root._probed)
            root._schedule(id);
    }

    function _schedule(id: string): void {
        if (!root.isApplicable(id) || !root.isEnabled(id) || root._pending.indexOf(id) >= 0 || root._job === id)
            return;
        root._pending = root._pending.concat([id]);
        root._next();
    }

    function _next(): void {
        if (root._job !== "" || root._pending.length === 0)
            return;
        const id = root._pending[0];
        root._pending = root._pending.slice(1);
        const check = HC.byId(id, root.checkList);
        if (!check) {
            root._next();
            return;
        }
        root._job = id;
        runner.gotText = false;
        runner.gotExit = false;
        runner.command = ["timeout", String(check.timeout), "env", "LC_ALL=C", "sh", "-c", check.cmd];
        runner.running = true;
    }

    function _finish(code: int, text: string): void {
        const id = root._job;
        const check = HC.byId(id, root.checkList);
        root._job = "";
        if (check) {
            const r = HC.run(check, text, code, { seen: root.cfg.newsSeen > 0 ? root.cfg.newsSeen : Date.now() - 14 * 86400000, read: root.cfg.newsRead ?? [] });
            const prev = root.results[id];
            if (id === "pkg.news" && r.severity === "unavailable" && prev?.items?.length > 0)
                Object.assign(r, prev);
            r.at = Date.now();
            root.results = Object.assign({}, root.results, { [id]: r });
            cacheSave.restart();
        }
        root._next();
    }

    function _probe(): void {
        root._probing = true;
        detector.running = true;
    }

    function _probeChecks(): void {
        let script = "";
        for (const c of root.checkList)
            script += "( " + c.when + " ) >/dev/null 2>&1 && echo '" + c.id + " 1' || echo '" + c.id + " 0'\n";
        prober.command = ["sh", "-c", script];
        prober.running = true;
    }

    function can(action: string): bool {
        return P.supports(root.platform, action);
    }

    function markNewsSeen(): void {
        Config.update({ health: Object.assign({}, Config.health, { newsSeen: Date.now() }) });
        root.refreshOne("pkg.news");
    }

    function markNewsRead(link: string): void {
        const read = (root.cfg.newsRead ?? []).filter(l => l !== link).concat([link]).slice(-50);
        Config.update({ health: Object.assign({}, Config.health, { newsRead: read }) });
        root.refreshOne("pkg.news");
    }

    readonly property var _terminal: ["kitty", "--hold", "sh", "-c"]

    function _inTerminal(cmd: string): void {
        Quickshell.execDetached({ command: root._terminal.concat(['printf "\\033[1m$ %s\\033[0m\\n\\n" "$1"; eval "$1"', "sh", cmd]), workingDirectory: Quickshell.env("HOME") });
    }

    // Runs without a terminal; only opens one if the command fails. quiet === null means only a terminal can ask for the password.
    function _runOrTerminal(quiet: var, fallback: string): void {
        if (quiet === null || quiet === undefined) {
            root._inTerminal(fallback);
            return;
        }
        if (quietRun.running)
            return;
        quietRun.fallback = fallback;
        quietRun.command = ["sh", "-c", quiet];
        quietRun.running = true;
    }

    function runAction(action: string, arg: string, scope: string): string {
        switch (action) {
        case "update": {
            const flatpak = (root.results["updates.flatpak"]?.count ?? 0) > 0 ? "flatpak update" : "";
            const c = P.command(root.platform, action, arg);
            if (c.error && flatpak === "")
                return root._actionError(action, c.error);
            root._inTerminal([c.cmd ?? "", flatpak].filter(x => x !== "").join("; "));
            return "ok";
        }
        case "reboot": {
            const c = P.command(root.platform, action, arg);
            if (c.error)
                return root._actionError(action, c.error);
            root._runOrTerminal(c.cmd, c.cmd);
            return "ok";
        }
        case "restartService":
        case "stopService":
        case "startService": {
            const c = P.command(root.platform, action, arg, scope);
            if (c.error)
                return root._actionError(action, c.error);
            root._runOrTerminal(c.quiet, c.cmd);
            return "ok";
        }
        case "pacdiff":
        case "cleanCache":
        case "removeOrphans":
        case "serviceLogs": {
            const c = P.command(root.platform, action, arg, scope);
            if (c.error)
                return root._actionError(action, c.error);
            root._inTerminal(c.cmd);
            return "ok";
        }
        case "reviewLogs":
            root._inTerminal(P.withPriv("sudo du -h --max-depth=1 /var/log | sort -h | tail -20" + (root.platform.init === "systemd" ? "; journalctl --disk-usage" : ""), root.platform));
            return "ok";
        case "emptyTrash":
            emptyTrash.running = true;
            return "ok";
        case "openNews":
            if (!/^https:\/\/archlinux\.org\//.test(arg))
                return "error: bad url";
            Quickshell.execDetached({ command: ["xdg-open", arg] });
            root.markNewsRead(arg);
            return "ok";
        }
        return "error: unknown action " + action;
    }

    function _actionError(action: string, msg: string): string {
        console.warn("[HealthService]", action + ":", msg);
        return "error: " + msg;
    }

    function _restore(text: string): void {
        if (Object.keys(root.results).length > 0)
            return;
        try {
            const d = JSON.parse(text);
            root.results = d.results ?? {};
            if (root._lastRun === 0)
                root._lastRun = d.lastRun ?? 0;
        } catch (e) {
        }
    }

    function statusJson(): string {
        return JSON.stringify({
            enabled: root.enabled,
            probed: root.probed,
            running: root.running,
            worst: root.worst,
            attention: root.attention,
            groups: root.groupWorst,
            platform: root.platform,
            lastRun: root.lastRun
        });
    }

    function resultsJson(): string {
        return JSON.stringify(root.results);
    }

    Process {
        id: detector
        command: ["sh", "-c", P.detectScript()]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = P.parseDetect(this.text);
                if (p.pkg === "")
                    console.warn("[HealthService] no supported package manager found, package checks are off");
                if (p.init === "")
                    console.warn("[HealthService] no supported service manager found, service checks are off");
                console.log("[HealthService] platform: pkg=" + (p.pkg || "none") + " init=" + (p.init || "none") + (p.aur ? " aur=" + p.aur : "") + " priv=" + p.priv);
                root.platform = p;
                root._probeChecks();
            }
        }
    }

    Process {
        id: prober
        stdout: StdioCollector {
            onStreamFinished: {
                const map = {};
                for (const line of this.text.split("\n")) {
                    const p = line.trim().split(" ");
                    if (p.length === 2)
                        map[p[0]] = p[1] === "1";
                }
                root.applicable = map;
                root._probed = true;
                root._probing = false;
                if (root.enabled && root.consumers > 0)
                    root.refresh();
                else if (root.enabled)
                    firstRun.start();
            }
        }
    }

    Process {
        id: runner
        property string out: ""
        property int exitCode: 0
        property bool gotText: false
        property bool gotExit: false

        function tryFinish() {
            if (!runner.gotText || !runner.gotExit)
                return;
            runner.gotText = false;
            runner.gotExit = false;
            root._finish(runner.exitCode, runner.out);
        }

        stdout: StdioCollector {
            onStreamFinished: {
                runner.out = this.text;
                runner.gotText = true;
                runner.tryFinish();
            }
        }
        onExited: code => {
            runner.exitCode = code;
            runner.gotExit = true;
            runner.tryFinish();
        }
    }

    Process {
        id: quietRun
        property string fallback: ""
        onExited: code => {
            // 126 is pkexec reporting the password dialog was dismissed; don't reopen it in a terminal
            if (code !== 0 && code !== 126)
                root._inTerminal(quietRun.fallback);
        }
    }

    Process {
        id: emptyTrash
        command: ["sh", "-c", 'rm -rf -- "$HOME/.local/share/Trash/files" "$HOME/.local/share/Trash/info" "$HOME/.local/share/Trash/expunged"']
        onExited: root.refreshOne("storage.trash")
    }

    FileView {
        id: cacheFile
        path: Quickshell.cacheDir + "/system-health.json"
        onLoaded: root._restore(cacheFile.text())
    }

    Timer {
        id: cacheSave
        interval: 3000
        onTriggered: {
            const keep = {};
            for (const c of root.checkList)
                if (root.results[c.id])
                    keep[c.id] = root.results[c.id];
            cacheFile.setText(JSON.stringify({ results: keep, lastRun: root._lastRun }));
        }
    }

    Timer {
        id: firstRun
        interval: 15000
        onTriggered: root.refresh()
    }

    Timer {
        interval: Math.max(5, root.cfg.intervalMinutes) * 60000
        running: root.enabled && root._probed
        repeat: true
        onTriggered: root.refresh()
    }

    Connections {
        target: Config
        function onHealthChanged() {
            if (root.enabled && root._probed && root._lastRun === 0)
                root.refresh();
        }
    }

    Component.onCompleted: root._probe()
}
