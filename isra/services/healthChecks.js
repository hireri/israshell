.pragma library
.import "platform.js" as P

var SEVERITIES = ["ok", "info", "warn", "bad", "unavailable", "permission"];

var SMART_RE = /SMART overall-health|SMART Health Status|Percentage Used|Power On Hours|Power_On_Hours|SMART Attributes Data/i;

function text(s) {
    return s === null || s === undefined ? "" : String(s);
}

function lines(s) {
    return text(s).split("\n").map(function (l) { return l.trim(); }).filter(function (l) { return l.length > 0; });
}

function duBytes(stdout) {
    var n = parseInt(lines(stdout)[0] || "", 10);
    return isFinite(n) ? n : 0;
}




function compareVersions(a, b) {
    var pa = String(a).match(/\d+|\D+/g) || [];
    var pb = String(b).match(/\d+|\D+/g) || [];
    var n = Math.max(pa.length, pb.length);
    for (var i = 0; i < n; i++) {
        if (pa[i] === undefined) return -1;
        if (pb[i] === undefined) return 1;
        var x = pa[i];
        var y = pb[i];
        if (/^\d/.test(x) && /^\d/.test(y)) {
            var d = parseInt(x, 10) - parseInt(y, 10);
            if (d !== 0) return d < 0 ? -1 : 1;
        } else if (x !== y) {
            return x < y ? -1 : 1;
        }
    }
    return 0;
}

function usageSeverity(pcts) {
    var worst = "ok";
    pcts.forEach(function (p) {
        if (p === null) return;
        if (p >= 95) worst = "bad";
        else if (p >= 85 && worst === "ok") worst = "warn";
    });
    return worst;
}


function parseSmartAttr(ls, id) {
    var start = -1;
    for (var i = 0; i < ls.length && start < 0; i++) {
        if (/^ID# ATTRIBUTE_NAME/.test(ls[i])) start = i;
    }
    for (var j = start + 1; start >= 0 && j < ls.length; j++) {
        var f = ls[j].split(/\s+/);
        if (!/^\d+$/.test(f[0])) break;
        if (f[0] === String(id) && f.length >= 10) {
            var raw = parseInt(f[9], 10);
            return isFinite(raw) ? raw : null;
        }
    }
    return null;
}

function parseSmart(stdout, code) {
    if (code === 3) return {severity: "unavailable", reason: "failed"};
    var all = text(stdout);
    var dev = /^DEV:(\S+)/m.exec(all);
    var device = dev ? dev[1] : null;
    var body = all.replace(/^DEV:.*$/m, "");
    var ls = lines(body);
    if (/SMART support is:\s*Unavailable|Unknown USB bridge/i.test(body)) return {severity: "unavailable", reason: "unsupported", device: device};
    if (!ls.length || /Permission denied/i.test(body) || !SMART_RE.test(body)) {
        return {severity: "permission", device: device};
    }
    var h = /overall-health self-assessment test result:\s*(\w+)/i.exec(body) || /SMART Health Status:\s*(\w+)/i.exec(body);
    var passed = h ? /^(PASSED|OK)$/i.test(h[1]) : null;
    var p = /Percentage Used:\s*(\d+)%/i.exec(body);
    var percentUsed = p ? parseInt(p[1], 10) : null;
    var t = /^Temperature:\s+(\d+)\s*Celsius/im.exec(body);
    var tempC = t ? parseInt(t[1], 10) : parseSmartAttr(ls, 194);
    var oh = /Power On Hours:\s*([\d,]+)/i.exec(body);
    var powerOnHours = oh ? parseInt(oh[1].replace(/,/g, ""), 10) : parseSmartAttr(ls, 9);
    var severity = passed === false ? "bad" : (percentUsed !== null && percentUsed >= 80 ? "warn" : "ok");
    return {severity: severity, device: device, passed: passed, percentUsed: percentUsed, tempC: tempC, powerOnHours: powerOnHours};
}

function parseDf(stdout) {
    var out = [];
    lines(stdout).forEach(function (l) {
        var m = /^(\S+)\s+(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)%\s+(.+)$/.exec(l);
        if (m) out.push({source: m[1], fstype: m[2], mount: m[7], total: parseInt(m[3], 10), used: parseInt(m[4], 10), avail: parseInt(m[5], 10), pct: parseInt(m[6], 10)});
    });
    return out;
}


function parseBattery(stdout) {
    var blocks = [];
    var cur = null;
    text(stdout).split("\n").forEach(function (raw) {
        var l = raw.trim();
        var h = /^== (.+)$/.exec(l);
        if (h) {
            cur = {path: h[1], kv: {}};
            blocks.push(cur);
            return;
        }
        var kv = /^POWER_SUPPLY_([A-Z_]+)=(.*)$/.exec(l);
        if (kv && cur) cur.kv[kv[1]] = kv[2];
    });
    var batteries = blocks.map(function (b) {
        var k = b.kv;
        var full = field(k, ["ENERGY_FULL", "CHARGE_FULL"]);
        var design = field(k, ["ENERGY_FULL_DESIGN", "CHARGE_FULL_DESIGN"]);
        return {
            name: k.NAME || b.path.split("/").pop(),
            percent: field(k, ["CAPACITY"]),
            status: k.STATUS || null,
            healthPct: full !== null && design !== null && design > 0 ? Math.round(full / design * 100) : null,
            cycles: field(k, ["CYCLE_COUNT"])
        };
    });
    var low = batteries.some(function (b) { return b.healthPct !== null && b.healthPct < 60; });
    return {severity: low ? "warn" : "ok", present: batteries.length > 0, batteries: batteries};
}

function field(kv, keys) {
    for (var i = 0; i < keys.length; i++) {
        var v = kv[keys[i]];
        if (v !== undefined && /^\d+$/.test(v)) return parseInt(v, 10);
    }
    return null;
}

var CHECKS = [
    {
        id: "updates.flatpak",
        group: "packages",
        timeout: 60,
        when: "command -v flatpak >/dev/null",
        cmd: "out=$(flatpak remote-ls --updates --columns=application,version 2>/dev/null); c=$?; printf '%s\\n' \"$out\"; echo \"installed:$(flatpak list --app 2>/dev/null | wc -l):$(flatpak list --runtime 2>/dev/null | wc -l)\"; exit $c",
        parse: function (stdout, code) {
            if (code !== 0) return {severity: "unavailable", reason: "failed"};
            var apps = null, runtimes = null;
            var rows = lines(stdout).filter(function (l) {
                var m = /^installed:(\d+):(\d+)$/.exec(l);
                if (m) { apps = parseInt(m[1], 10); runtimes = parseInt(m[2], 10); }
                return !m;
            });
            var items = rows.map(function (l) {
                var f = l.split("\t");
                return {name: f[0].trim(), from: "", to: (f[1] || "").trim()};
            });
            var r = {severity: items.length ? "info" : "ok", count: items.length, items: items};
            if (apps !== null) { r.apps = apps; r.runtimes = runtimes; }
            return r;
        }
    },
    {
        id: "storage.mounts",
        group: "storage",
        timeout: 10,
        when: "command -v df >/dev/null",
        cmd: "df -PTB1 -x tmpfs -x devtmpfs -x efivarfs -x squashfs -x overlay 2>/dev/null",
        parse: function (stdout, code) {
            var mounts = parseDf(stdout);
            if (code !== 0 && !mounts.length) return {severity: "unavailable", reason: "failed"};
            return {severity: usageSeverity(mounts.map(function (m) { return m.pct; })), mounts: mounts};
        }
    },
    {
        id: "storage.inodes",
        group: "storage",
        timeout: 10,
        when: "command -v df >/dev/null",
        cmd: "df -Pi -x tmpfs -x devtmpfs -x efivarfs -x squashfs -x overlay 2>/dev/null",
        parse: function (stdout, code) {
            var mounts = [];
            lines(stdout).forEach(function (l) {
                var m = /^(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+%|-)\s+(.+)$/.exec(l);
                if (m) mounts.push({mount: m[6], pct: m[5] === "-" ? null : parseInt(m[5], 10)});
            });
            if (code !== 0 && !mounts.length) return {severity: "unavailable", reason: "failed"};
            return {severity: usageSeverity(mounts.map(function (m) { return m.pct; })), mounts: mounts};
        }
    },
    {
        id: "storage.smart",
        group: "storage",
        timeout: 20,
        when: "command -v smartctl >/dev/null",
        cmd: "d=$(lsblk -dno NAME,TYPE | awk '$2==\"disk\"{print $1; exit}'); [ -n \"$d\" ] || exit 3; echo DEV:$d; if sudo -n true 2>/dev/null; then sudo -n smartctl -a /dev/$d 2>&1; else smartctl -a /dev/$d 2>&1; fi",
        parse: parseSmart
    },
    {
        id: "storage.trash",
        group: "storage",
        timeout: 20,
        when: "true",
        cmd: "du -sb \"$HOME/.local/share/Trash\" 2>/dev/null",
        parse: function (stdout) {
            return {severity: "ok", bytes: duBytes(stdout)};
        }
    },
    {
        id: "storage.logs",
        group: "storage",
        timeout: 30,
        when: "[ -d /var/log ]",
        cmd: "du -sb /var/log 2>/dev/null",
        parse: function (stdout) {
            return {severity: "ok", bytes: duBytes(stdout)};
        }
    },
    {
        id: "hw.temps",
        group: "hardware",
        timeout: 5,
        when: "[ -d /sys/class/hwmon ]",
        cmd: "for h in /sys/class/hwmon/hwmon*; do [ -d $h ] || continue; n=$(cat $h/name 2>/dev/null); for f in $h/temp*_input; do [ -r $f ] || continue; l=$(cat ${f%_input}_label 2>/dev/null); printf '%s\\t%s\\t%s\\n' \"$n\" \"$l\" \"$(cat $f 2>/dev/null)\"; done; done",
        parse: function (stdout) {
            var sensors = [];
            text(stdout).split("\n").forEach(function (raw) {
                var f = raw.replace(/\r$/, "").split("\t");
                if (f.length < 3) return;
                var milli = parseInt(f[2], 10);
                if (!isFinite(milli)) return;
                var c = Math.round(milli / 100) / 10;
                if (c <= 0 || c > 150) return;
                sensors.push({name: f[0].trim(), label: f[1].trim(), celsius: c});
            });
            var hottest = sensors.reduce(function (m, s) { return Math.max(m, s.celsius); }, 0);
            var severity = hottest >= 90 ? "bad" : (hottest >= 80 ? "warn" : "ok");
            return {severity: severity, sensors: sensors};
        }
    },
    {
        id: "hw.battery",
        group: "hardware",
        timeout: 5,
        when: "ls /sys/class/power_supply/BAT* >/dev/null 2>&1",
        cmd: "for b in /sys/class/power_supply/BAT*; do [ -e $b ] || continue; echo == $b; cat $b/uevent 2>/dev/null; done",
        parse: parseBattery
    },
    {
        id: "sys.reboot",
        group: "system",
        timeout: 5,
        when: "[ -d /usr/lib/modules ] || [ -d /lib/modules ]",
        cmd: "uname -r; ls /usr/lib/modules 2>/dev/null || ls /lib/modules 2>/dev/null; [ -e /run/reboot-required ] && echo REBOOT_REQUIRED; true",
        parse: function (stdout) {
            var ls = lines(stdout);
            var flagged = ls.indexOf("REBOOT_REQUIRED") >= 0;
            ls = ls.filter(function (l) { return l !== "REBOOT_REQUIRED" && !/^extramodules/.test(l); });
            var running = ls.length ? ls[0] : null;
            var installedList = ls.slice(1);
            var needed = flagged || (installedList.length > 0 && installedList.indexOf(running) < 0);
            var installed = null;
            installedList.forEach(function (v) {
                if (installed === null || compareVersions(v, installed) > 0) installed = v;
            });
            return {severity: needed ? "warn" : "ok", needed: needed, running: running, installed: installed};
        }
    },
    {
        id: "sys.timesync",
        group: "system",
        timeout: 5,
        when: "command -v chronyc >/dev/null || command -v timedatectl >/dev/null",
        cmd: "{ command -v chronyc >/dev/null && chronyc tracking 2>&1; } || { command -v timedatectl >/dev/null && echo \"NTPSynchronized=$(timedatectl show -p NTPSynchronized --value 2>/dev/null)\"; }",
        parse: function (stdout) {
            var ntp = /^NTPSynchronized=(yes|no)$/m.exec(text(stdout));
            if (ntp) return {severity: ntp[1] === "yes" ? "ok" : "warn", synced: ntp[1] === "yes", offsetMs: null};
            var leapM = /^Leap status\s*:\s*(.+)$/m.exec(text(stdout));
            if (!leapM) return {severity: "unavailable", reason: "failed"};
            var leap = leapM[1].trim();
            var off = /^System time\s*:\s*([\d.]+) seconds (fast|slow)/m.exec(text(stdout));
            var offsetMs = null;
            if (off) {
                offsetMs = Math.round(parseFloat(off[1]) * 1e9) / 1e6;
                if (off[2] === "slow") offsetMs = -offsetMs;
            }
            var warn = leap !== "Normal" || (offsetMs !== null && Math.abs(offsetMs) > 500);
            return {severity: warn ? "warn" : "ok", synced: leap !== "Not synchronised", offsetMs: offsetMs};
        }
    },
    {
        id: "sys.memory",
        group: "system",
        timeout: 5,
        when: "[ -r /proc/meminfo ]",
        cmd: "cat /proc/meminfo",
        parse: function (stdout) {
            var kv = {};
            lines(stdout).forEach(function (l) {
                var m = /^(\w+):\s+(\d+)\s*kB/.exec(l);
                if (m) kv[m[1]] = parseInt(m[2], 10) * 1024;
            });
            var total = kv.MemTotal || 0;
            var avail = kv.MemAvailable || 0;
            return {
                severity: total > 0 && avail * 10 < total ? "warn" : "ok",
                memTotal: total,
                memAvailable: avail,
                swapTotal: kv.SwapTotal || 0,
                swapFree: kv.SwapFree || 0
            };
        }
    }
];

var ORDER = ["updates.repo", "updates.aur", "updates.flatpak", "pkg.orphans", "pkg.pacnew", "pkg.cache", "pkg.deps", "pkg.news", "storage.mounts", "storage.inodes", "storage.smart", "storage.trash", "storage.logs", "hw.temps", "hw.battery", "svc.list", "sys.reboot", "sys.timesync", "sys.memory"];

function checksFor(plat) {
    var all = CHECKS.concat(P.checks(plat));
    return ORDER.map(function (id) {
        for (var i = 0; i < all.length; i++) {
            if (all[i].id === id) return all[i];
        }
        return null;
    }).filter(function (c) { return c !== null; });
}

function byId(id, list) {
    var l = list || CHECKS;
    for (var i = 0; i < l.length; i++) {
        if (l[i].id === id) return l[i];
    }
    return null;
}

function run(check, stdout, code, ctx) {
    if (code === 127) return {severity: "unavailable", reason: "missing"};
    if (code === 124) return {severity: "unavailable", reason: "timeout"};
    try {
        var r = check.parse(stdout, code, ctx);
        if (r && SEVERITIES.indexOf(r.severity) >= 0) return r;
    } catch (e) {
    }
    return {severity: "unavailable", reason: "parse"};
}
