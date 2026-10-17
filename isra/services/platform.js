.pragma library

var SIZE_MULT = {B: 1, KiB: 1024, MiB: 1048576, GiB: 1073741824, TiB: 1099511627776};
var GIB = 1073741824;
var SAFE_NAME = /^[A-Za-z0-9._@:+-]+$/;
var LIST_NAME = /^[A-Za-z0-9._@:+\\-]+$/;
var SAFE_PATH = /^\/[A-Za-z0-9._\/-]+$/;

function text(s) {
    return s === null || s === undefined ? "" : String(s);
}

function lines(s) {
    return text(s).split("\n").map(function (l) { return l.trim(); }).filter(function (l) { return l.length > 0; });
}

function sizeBytes(s) {
    var m = /^([\d.]+)\s*(B|KiB|MiB|GiB|TiB)$/.exec(s.trim());
    return m ? Math.round(parseFloat(m[1]) * SIZE_MULT[m[2]]) : 0;
}

function duBytes(stdout) {
    var n = parseInt(lines(stdout).pop() || "", 10);
    return isFinite(n) ? n : 0;
}

function decodeEntities(s) {
    return s.replace(/&#x([0-9a-f]+);/gi, function (m, h) { return String.fromCharCode(parseInt(h, 16)); })
        .replace(/&#(\d+);/g, function (m, d) { return String.fromCharCode(parseInt(d, 10)); })
        .replace(/&lt;/g, "<")
        .replace(/&gt;/g, ">")
        .replace(/&quot;/g, "\"")
        .replace(/&apos;/g, "'")
        .replace(/&amp;/g, "&");
}

function xmlTag(xml, tag) {
    var m = new RegExp("<" + tag + "(?:\\s[^>]*)?>([\\s\\S]*?)</" + tag + ">").exec(xml);
    if (!m) return "";
    var cdata = /^\s*<!\[CDATA\[([\s\S]*?)\]\]>\s*$/.exec(m[1]);
    return cdata ? cdata[1].trim() : decodeEntities(m[1].trim());
}

function okCodes(codes, fn) {
    return function (stdout, code, ctx) {
        if (codes.indexOf(code) < 0) return {severity: "unavailable", reason: "failed"};
        return fn(stdout, code, ctx);
    };
}

function parseArrowUpdates(stdout) {
    var items = [];
    lines(stdout).forEach(function (l) {
        var m = /^(\S+)\s+(\S+)\s+->\s+(\S+)/.exec(l);
        if (m) items.push({name: m[1], from: m[2], to: m[3]});
    });
    return {severity: items.length ? "info" : "ok", count: items.length, items: items};
}

function parseTsvUpdates(stdout) {
    var items = [];
    text(stdout).split("\n").forEach(function (l) {
        var f = l.replace(/\r$/, "").split("\t");
        if (f.length < 3 || f[0].trim() === "") return;
        items.push({name: f[0].trim(), from: f[1].trim(), to: f[2].trim()});
    });
    return {severity: items.length ? "info" : "ok", count: items.length, items: items};
}

function parseNames(stdout) {
    var items = lines(stdout).filter(function (l) { return /^\S+$/.test(l); });
    var severity = items.length === 0 ? "ok" : (items.length <= 20 ? "info" : "warn");
    return {severity: severity, count: items.length, bytes: null, items: items};
}

function parseFileList(stdout) {
    var items = lines(stdout);
    return {severity: items.length ? "warn" : "ok", count: items.length, items: items};
}

function parseCache(stdout) {
    var bytes = duBytes(stdout);
    return {severity: bytes > 10 * GIB ? "info" : "ok", bytes: bytes};
}

function parseServices(stdout) {
    var seen = {};
    var services = [];
    text(stdout).split("\n").forEach(function (l) {
        var f = l.replace(/\r$/, "").split("\t");
        if (f.length < 3) return;
        var name = f[0].trim();
        var state = f[1].trim();
        var scope = f[4] !== undefined && f[4].trim() === "u" ? "user" : "system";
        if (!LIST_NAME.test(name) || seen[name + "/" + scope] || ["run", "down", "failed"].indexOf(state) < 0) return;
        seen[name + "/" + scope] = true;
        var secs = parseInt(f[3], 10);
        services.push({name: name, state: state, pid: null, seconds: state === "run" && secs > 0 ? secs : null, normallyUp: f[2].trim() === "1", scope: scope});
    });
    return servicesResult(services);
}

function servicesResult(services) {
    var failed = services.filter(function (s) { return s.state === "failed"; }).map(function (s) { return s.name; });
    return {severity: failed.length ? "bad" : "ok", services: services, failed: failed};
}

function parseDinit(stdout, code) {
    if (/permission denied|connecting to socket/i.test(text(stdout))) return {severity: "permission"};
    if (code !== 0) return {severity: "unavailable", reason: "failed"};
    var services = [];
    lines(stdout).forEach(function (l) {
        var m = /^\[(.*)\]\s+(\S+)(.*)$/.exec(l);
        if (!m || !LIST_NAME.test(m[2])) return;
        var flags = m[1];
        var rest = m[3];
        var state = /X/.test(flags) || /failed|exit status: [1-9]/i.test(rest) ? "failed" : (/\+/.test(flags) ? "run" : "down");
        services.push({name: m[2], state: state, pid: null, seconds: null, normallyUp: flags.indexOf("[") >= 0, scope: "system"});
    });
    return servicesResult(services);
}

function confFind(patterns) {
    return "find /etc -xdev \\( " + patterns.map(function (p) { return "-name '" + p + "'"; }).join(" -o ") + " \\) 2>/dev/null";
}

function confReview(patterns) {
    return "for f in $(" + confFind(patterns) + "); do o=$(printf '%s' \"$f\" | sed -E 's/\\.(pacnew|pacsave|dpkg-dist|dpkg-new|ucf-dist|rpmnew|rpmsave|apk-new|new-[^/]*|new)$//'); printf '\\n== %s\\n' \"$f\"; sudo diff -u \"$o\" \"$f\"; done; echo; echo 'Merge each file by hand, then delete the leftover copy.'";
}

function confCheck(patterns) {
    return {id: "pkg.pacnew", group: "packages", timeout: 30, when: "[ -d /etc ]", cmd: confFind(patterns), parse: parseFileList};
}

function cacheCheck(dirs) {
    return {id: "pkg.cache", group: "packages", timeout: 30, when: dirs.map(function (d) { return "[ -d " + d + " ]"; }).join(" || "), cmd: "du -sbcL " + dirs.join(" ") + " 2>/dev/null | tail -n1", parse: parseCache};
}

var NEWS_CHECK = {
    id: "pkg.news",
    group: "packages",
    timeout: 15,
    when: "command -v curl >/dev/null",
    cmd: "curl -fsS --max-time 10 https://archlinux.org/feeds/news/ 2>/dev/null",
    parse: function (stdout, code, ctx) {
        if (code !== 0) return {severity: "unavailable", reason: "offline"};
        var seen = ctx && isFinite(ctx.seen) ? ctx.seen : 0;
        var read = ctx && ctx.read ? ctx.read : [];
        var blocks = (text(stdout).match(/<item[\s>][\s\S]*?<\/item>/g) || []).slice(0, 10);
        var items = blocks.map(function (b) {
            var date = Date.parse(xmlTag(b, "pubDate"));
            if (!isFinite(date)) date = 0;
            var title = xmlTag(b, "title");
            var link = xmlTag(b, "link");
            var summary = xmlTag(b, "description").replace(/<[^>]*>/g, " ").replace(/\s+/g, " ").trim();
            if (summary.length > 160) summary = summary.slice(0, 160).replace(/\s+\S*$/, "") + "…";
            var kind = /manual intervention|requires manual|action required/i.test(title) ? "manual" : /malicious|security|vulnerab|incident|compromis|CVE-/i.test(title) ? "security" : "other";
            return {title: title, link: link, date: date, unread: date > seen && read.indexOf(link) < 0, summary: summary, kind: kind};
        });
        var unread = items.filter(function (i) { return i.unread; });
        var severity = "ok";
        if (unread.some(function (i) { return i.kind === "manual"; })) severity = "bad";
        else if (unread.length) severity = "info";
        return {severity: severity, unread: unread.length, items: items};
    }
};

var PKG = {
    pacman: {
        detect: "command -v pacman >/dev/null",
        checks: function (plat) {
            var out = [
                {id: "updates.repo", group: "packages", timeout: 120, when: "command -v checkupdates >/dev/null", cmd: "checkupdates 2>/dev/null", parse: okCodes([0, 2], parseArrowUpdates)},
                {
                    id: "pkg.orphans", group: "packages", timeout: 30, when: "true",
                    cmd: "pacman -Qdtq 2>/dev/null | xargs -r pacman -Qi 2>/dev/null",
                    parse: function (stdout) {
                        var items = [];
                        var bytes = 0;
                        lines(stdout).forEach(function (l) {
                            var n = /^Name\s*:\s*(.+)$/.exec(l);
                            if (n) items.push(n[1]);
                            var s = /^Installed Size\s*:\s*(.+)$/.exec(l);
                            if (s) bytes += sizeBytes(s[1]);
                        });
                        var severity = items.length === 0 ? "ok" : (items.length <= 20 ? "info" : "warn");
                        return {severity: severity, count: items.length, bytes: bytes, items: items};
                    }
                },
                confCheck(["*.pacnew", "*.pacsave"]),
                cacheCheck(["/var/cache/pacman/pkg"]),
                {
                    id: "pkg.deps", group: "packages", timeout: 60, when: "true",
                    cmd: "pacman -Dk 2>&1",
                    parse: function (stdout, code) {
                        var issues = lines(stdout).filter(function (l) { return l !== "No database errors have been found!"; });
                        if (issues.length) return {severity: "bad", issues: issues};
                        if (code !== 0) return {severity: "unavailable", reason: "failed"};
                        return {severity: "ok", issues: []};
                    }
                },
                NEWS_CHECK
            ];
            if (plat.aur)
                out.splice(1, 0, {id: "updates.aur", group: "packages", timeout: 60, when: "command -v " + plat.aur + " >/dev/null", cmd: plat.aur + " -Qua 2>/dev/null", parse: okCodes([0, 1], parseArrowUpdates)});
            return out;
        },
        actions: {
            update: function (plat) { return plat.aur ? plat.aur + (plat.priv === "doas" ? " --sudo doas" : "") + " -Syu" : "sudo pacman -Syu"; },
            removeOrphans: function () { return "sudo pacman -Rns $(pacman -Qdtq)"; },
            pacdiff: function () { return "if command -v pacdiff >/dev/null; then sudo -E pacdiff; else " + confReview(["*.pacnew", "*.pacsave"]) + "; fi"; },
            cleanCache: function () { return "if command -v paccache >/dev/null; then sudo paccache -r; else sudo pacman -Sc; fi"; }
        }
    },
    apt: {
        detect: "command -v apt-get >/dev/null && command -v dpkg >/dev/null",
        checks: function () {
            return [
                {id: "updates.repo", group: "packages", timeout: 60, when: "command -v apt >/dev/null", cmd: String.raw`out=$(apt list --upgradable 2>/dev/null); c=$?; printf '%s\n' "$out" | awk '/upgradable from/ { split($1, a, "/"); f = $NF; sub(/\]$/, "", f); print a[1] "\t" f "\t" $2 }'; exit $c`, parse: okCodes([0], parseTsvUpdates)},
                {id: "pkg.orphans", group: "packages", timeout: 60, when: "true", cmd: "out=$(apt-get -s autoremove 2>/dev/null); c=$?; printf '%s\\n' \"$out\" | awk '/^Remv /{print $2}'; exit $c", parse: okCodes([0], parseNames)},
                confCheck(["*.dpkg-dist", "*.dpkg-new", "*.ucf-dist"]),
                cacheCheck(["/var/cache/apt/archives"]),
                {
                    id: "pkg.deps", group: "packages", timeout: 60, when: "true",
                    cmd: "dpkg --audit 2>&1",
                    parse: function (stdout, code) {
                        var issues = lines(stdout);
                        if (issues.length) return {severity: "bad", issues: issues};
                        return code === 0 ? {severity: "ok", issues: []} : {severity: "unavailable", reason: "failed"};
                    }
                }
            ];
        },
        actions: {
            update: function () { return "sudo apt update && sudo apt upgrade"; },
            removeOrphans: function () { return "sudo apt autoremove"; },
            pacdiff: function () { return confReview(["*.dpkg-dist", "*.dpkg-new", "*.ucf-dist"]); },
            cleanCache: function () { return "sudo apt-get autoclean"; }
        }
    },
    dnf: {
        detect: "command -v dnf >/dev/null",
        checks: function () {
            return [
                {id: "updates.repo", group: "packages", timeout: 120, when: "true", cmd: String.raw`out=$(dnf -q check-update 2>/dev/null); c=$?; printf '%s\n' "$out" | awk '/^Obsolet/ { exit } NF == 3 && $1 ~ /\./ { n = $1; sub(/\.[^.]+$/, "", n); print n "\t\t" $2 }'; exit $c`, parse: okCodes([0, 100], parseTsvUpdates)},
                {id: "pkg.orphans", group: "packages", timeout: 120, when: "true", cmd: "dnf -q repoquery --unneeded --qf '%{name}\\n' 2>/dev/null", parse: okCodes([0], parseNames)},
                confCheck(["*.rpmnew", "*.rpmsave"]),
                cacheCheck(["/var/cache/dnf", "/var/cache/libdnf5"]),
                {
                    id: "pkg.deps", group: "packages", timeout: 120, when: "true",
                    cmd: "dnf -q check 2>&1",
                    parse: function (stdout, code) {
                        var issues = lines(stdout).filter(function (l) { return /has missing requires|has installed conflict|is a duplicate|obsoleted by/i.test(l); });
                        if (issues.length) return {severity: "bad", issues: issues};
                        return code === 0 ? {severity: "ok", issues: []} : {severity: "unavailable", reason: "failed"};
                    }
                }
            ];
        },
        actions: {
            update: function () { return "sudo dnf upgrade --refresh"; },
            removeOrphans: function () { return "sudo dnf autoremove"; },
            pacdiff: function () { return "if command -v rpmconf >/dev/null; then sudo rpmconf -a; else " + confReview(["*.rpmnew", "*.rpmsave"]) + "; fi"; },
            cleanCache: function () { return "sudo dnf clean packages"; }
        }
    },
    zypper: {
        detect: "command -v zypper >/dev/null",
        checks: function () {
            return [
                {id: "updates.repo", group: "packages", timeout: 120, when: "true", cmd: String.raw`out=$(zypper -q --no-refresh list-updates 2>/dev/null); c=$?; printf '%s\n' "$out" | awk -F'|' '$1 ~ /^ *v *$/ { for (i = 2; i <= NF; i++) gsub(/^ +| +$/, "", $i); print $3 "\t" $4 "\t" $5 }'; exit $c`, parse: okCodes([0], parseTsvUpdates)},
                {id: "pkg.orphans", group: "packages", timeout: 60, when: "true", cmd: String.raw`out=$(zypper -q --no-refresh packages --unneeded 2>/dev/null); c=$?; printf '%s\n' "$out" | awk -F'|' '$1 ~ /i/ { gsub(/^ +| +$/, "", $3); print $3 }'; exit $c`, parse: okCodes([0], parseNames)},
                confCheck(["*.rpmnew", "*.rpmsave"]),
                cacheCheck(["/var/cache/zypp/packages"])
            ];
        },
        actions: {
            update: function (plat) { return plat.os === "opensuse-tumbleweed" ? "sudo zypper dup" : "sudo zypper update"; },
            removeOrphans: function () { return String.raw`p=$(zypper -q --no-refresh packages --unneeded | awk -F'|' '$1 ~ /i/ { gsub(/^ +| +$/, "", $3); print $3 }'); if [ -n "$p" ]; then sudo zypper rm --clean-deps $p; else echo 'Nothing to remove'; fi`; },
            pacdiff: function () { return confReview(["*.rpmnew", "*.rpmsave"]); },
            cleanCache: function () { return "sudo zypper clean"; }
        }
    },
    xbps: {
        detect: "command -v xbps-install >/dev/null",
        checks: function () {
            return [
                {id: "updates.repo", group: "packages", timeout: 120, when: "true", cmd: String.raw`out=$(xbps-install -Mun 2>/dev/null); c=$?; printf '%s\n' "$out" | awk '$2 == "update" || $2 == "install" { p = $1; n = p; sub(/-[^-]*$/, "", n); print n "\t\t" substr(p, length(n) + 2) }'; exit $c`, parse: okCodes([0, 6], parseTsvUpdates)},
                {id: "pkg.orphans", group: "packages", timeout: 30, when: "true", cmd: String.raw`xbps-query -O 2>/dev/null | sed 's/-[^-]*$//'`, parse: okCodes([0], parseNames)},
                confCheck(["*.new-*", "*.new"]),
                cacheCheck(["/var/cache/xbps"])
            ];
        },
        actions: {
            update: function () { return "sudo xbps-install -Su"; },
            removeOrphans: function () { return "sudo xbps-remove -o"; },
            pacdiff: function () { return confReview(["*.new-*", "*.new"]); },
            cleanCache: function () { return "sudo xbps-remove -O"; }
        }
    },
    apk: {
        detect: "command -v apk >/dev/null",
        checks: function () {
            return [
                {id: "updates.repo", group: "packages", timeout: 60, when: "true", cmd: String.raw`out=$(apk list -u 2>/dev/null); c=$?; printf '%s\n' "$out" | awk '/upgradable from/ { p = $1; n = p; sub(/-[^-]+-r[0-9]+$/, "", n); f = $NF; sub(/\]$/, "", f); print n "\t" substr(f, length(n) + 2) "\t" substr(p, length(n) + 2) }'; exit $c`, parse: okCodes([0], parseTsvUpdates)},
                confCheck(["*.apk-new"]),
                cacheCheck(["/var/cache/apk"])
            ];
        },
        actions: {
            update: function () { return "sudo apk update && sudo apk upgrade"; },
            pacdiff: function () { return confReview(["*.apk-new"]); },
            cleanCache: function () { return "sudo apk cache clean"; }
        }
    }
};

function fileLogs(dirs) {
    return function (name) {
        var files = ["/var/log/" + name + "/current", "/var/log/" + name + ".log", "/var/log/" + name + "/" + name + ".log"].concat(dirs.map(function (d) { return d + "/" + name + "/log/main/current"; }));
        return "for f in " + files.join(" ") + "; do if sudo test -e \"$f\"; then exec sudo tail -n 200 -F \"$f\"; fi; done; echo 'No log file for " + name + ", showing syslog matches'; sudo grep -h -- '" + name + "' /var/log/messages /var/log/syslog /var/log/socklog/everything/current 2>/dev/null | tail -n 200";
    };
}

var SOFT_REBOOT = "loginctl reboot 2>/dev/null || sudo reboot";

function runitSv(verb, n, plat, scope) {
    var user = scope === "user";
    return (user ? "" : "sudo ") + "sv " + verb + " " + (user ? plat.usvdir : plat.svdir) + "/" + n;
}

var INIT = {
    systemd: {
        detect: "[ -d /run/systemd/system ]",
        list: function () {
            return String.raw`{ systemctl list-unit-files --type=service --state=enabled --no-legend --plain 2>/dev/null | sed 's/^/E /'; systemctl list-units --type=service --all --no-legend --plain 2>/dev/null | sed 's/^/U /'; } | awk '$1 == "E" { e[$2] = 1; next } $1 == "U" { c++ } $1 == "U" && $3 == "loaded" { s = $4 == "failed" ? "failed" : ($4 == "active" ? "run" : "down"); t = $2; sub(/@[^.]*\./, "@.", t); u = ($2 in e) || (t in e) ? 1 : 0; n = $2; sub(/\.service$/, "", n); if (s != "down" || u) print n "\t" s "\t" u "\t" } END { if (!c) exit 3 }'`;
        },
        parse: okCodes([0], parseServices),
        actions: {
            restartService: function (n) { return "sudo systemctl restart " + n; },
            stopService: function (n) { return "sudo systemctl stop " + n; },
            startService: function (n) { return "sudo systemctl start " + n; },
            serviceLogs: function (n) { return "sudo journalctl -b -n 200 -f -u " + n; },
            reboot: function () { return "systemctl reboot"; }
        }
    },
    runit: {
        detect: "pgrep -x runsvdir >/dev/null",
        list: function (plat) {
            return "D=" + plat.svdir + "; U=" + plat.usvdir + String.raw`; for p in $(pgrep -x runsv); do n=$(tr '\0' ' ' 2>/dev/null </proc/$p/cmdline | awk '{ print $2 }'); n=$(basename "$n" 2>/dev/null); [ -n "$n" ] || continue; if [ -d "$D/$n" ]; then d=$D/$n; sc=s; elif [ -n "$U" ] && [ -d "$U/$n" ]; then d=$U/$n; sc=u; else continue; fi; c=$(pgrep -P $p -l | awk '$2 != "runsv" && $2 != "svlogd" && $2 != "vlogger" && $2 != "logger" { print $1; exit }'); st=down; s=; if [ -n "$c" ]; then st=run; s=$(ps -o etimes= -p $c | tr -d ' '); fi; u=1; [ -e "$d/down" ] && u=0; printf '%s\t%s\t%s\t%s\t%s\n' "$n" "$st" "$u" "$s" "$sc"; done`;
        },
        parse: okCodes([0], parseServices),
        actions: {
            restartService: function (n, plat, scope) { return runitSv("restart", n, plat, scope); },
            stopService: function (n, plat, scope) { return runitSv("stop", n, plat, scope); },
            startService: function (n, plat, scope) { return runitSv("start", n, plat, scope); },
            serviceLogs: function (n, plat, scope) { return fileLogs([scope === "user" ? plat.usvdir : plat.svdir])(n); },
            reboot: function () { return SOFT_REBOOT; }
        }
    },
    openrc: {
        detect: "command -v rc-status >/dev/null && [ -d /run/openrc ]",
        list: function () {
            return String.raw`{ rc-update show 2>/dev/null | awk -F'|' '{ gsub(/ /, "", $1); if ($1 != "") print "E " $1 }'; rc-status --servicelist 2>/dev/null | sed 's/^/S /'; } | awk '$1 == "E" { e[$2] = 1; next } $1 == "S" && index($0, "[") { c++; n = $2; st = substr($0, index($0, "[") + 1); split(st, w, " "); x = w[1]; s = x == "started" || x == "starting" || x == "stopping" ? "run" : (x == "crashed" ? "failed" : "down"); u = (n in e) ? 1 : 0; if (s != "down" || u) print n "\t" s "\t" u "\t" } END { if (!c) exit 3 }'`;
        },
        parse: okCodes([0], parseServices),
        actions: {
            restartService: function (n) { return "sudo rc-service " + n + " restart"; },
            stopService: function (n) { return "sudo rc-service " + n + " stop"; },
            startService: function (n) { return "sudo rc-service " + n + " start"; },
            serviceLogs: function (n) { return fileLogs([])(n); },
            reboot: function () { return SOFT_REBOOT; }
        }
    },
    s6: {
        detect: "command -v s6-rc >/dev/null && [ -d /run/s6-rc ]",
        list: function () {
            return String.raw`{ s6-rc -a list 2>/dev/null | sed 's/^/A /'; s6-rc-db contents default 2>/dev/null | sed 's/^/E /'; s6-rc-db list services 2>/dev/null | sed 's/^/S /'; } | awk '$1 == "A" { a[$2] = 1; next } $1 == "E" { e[$2] = 1; next } $1 == "S" { c++; n = $2; if (n ~ /^s6rc-/ || n ~ /-log$/) next; s = (n in a) ? "run" : "down"; u = (n in e) ? 1 : 0; if (s == "run" || u) print n "\t" s "\t" u "\t" } END { if (!c) exit 3 }'`;
        },
        parse: okCodes([0], parseServices),
        actions: {
            restartService: function (n) { return "if [ -d /run/service/" + n + " ]; then sudo s6-svc -r /run/service/" + n + "; else sudo s6-rc -d change " + n + " && sudo s6-rc -u change " + n + "; fi"; },
            stopService: function (n) { return "sudo s6-rc -d change " + n; },
            startService: function (n) { return "sudo s6-rc -u change " + n; },
            serviceLogs: function (n) { return fileLogs([])(n.replace(/-srv$/, "")); },
            reboot: function () { return SOFT_REBOOT; }
        }
    },
    dinit: {
        detect: "command -v dinitctl >/dev/null && { [ -S /run/dinitctl ] || pgrep -x dinit >/dev/null; }",
        list: function () { return "dinitctl --system list 2>&1"; },
        parse: parseDinit,
        actions: {
            restartService: function (n) { return "sudo dinitctl --system restart " + n; },
            stopService: function (n) { return "sudo dinitctl --system stop " + n; },
            startService: function (n) { return "sudo dinitctl --system start " + n; },
            serviceLogs: function (n) { return "sudo dinitctl --system catlog " + n + " 2>/dev/null || { " + fileLogs([])(n) + "; }"; },
            reboot: function () { return SOFT_REBOOT; }
        }
    }
};

var PKG_ORDER = ["pacman", "apt", "dnf", "zypper", "xbps", "apk"];
var INIT_ORDER = ["systemd", "runit", "s6", "openrc", "dinit"];

function has(o, k) {
    return Object.prototype.hasOwnProperty.call(o, k);
}

function detectScript() {
    var s = "";
    s += PKG_ORDER.map(function (k) { return "if " + PKG[k].detect + "; then echo 'pkg " + k + "'; "; }).join("el") + "fi\n";
    s += INIT_ORDER.map(function (k) { return "if " + INIT[k].detect + "; then echo 'init " + k + "'; "; }).join("el") + "fi\n";
    s += "for h in paru yay; do if command -v $h >/dev/null; then echo \"aur $h\"; break; fi; done\n";
    s += "if command -v sudo >/dev/null; then echo 'priv sudo'; elif command -v doas >/dev/null; then echo 'priv doas'; fi\n";
    s += "for p in $(pgrep -x runsvdir); do d=$(tr '\\0' '\\n' </proc/$p/cmdline 2>/dev/null | grep -m1 '^/'); case \"$(tr '\\0' ' ' </proc/$p/cmdline 2>/dev/null)\" in *-P*) echo \"svdir $d\";; *) echo \"usvdir $d\";; esac; done\n";
    s += "[ -r /etc/os-release ] && . /etc/os-release && echo \"os $ID\"\n";
    return s;
}

function parseDetect(stdout) {
    var p = {pkg: "", init: "", aur: "", priv: "sudo", svdir: "", usvdir: "", os: ""};
    lines(stdout).forEach(function (l) {
        var m = /^(pkg|init|aur|priv|svdir|usvdir|os)\s+(\S+)$/.exec(l);
        if (!m) return;
        if (m[1] === "pkg" && has(PKG, m[2])) p.pkg = m[2];
        else if (m[1] === "init" && has(INIT, m[2])) p.init = m[2];
        else if (m[1] === "aur" && /^(paru|yay)$/.test(m[2])) p.aur = m[2];
        else if (m[1] === "priv" && /^(sudo|doas)$/.test(m[2])) p.priv = m[2];
        else if (m[1] === "svdir" && SAFE_PATH.test(m[2])) p.svdir = m[2];
        else if (m[1] === "usvdir" && SAFE_PATH.test(m[2])) p.usvdir = m[2];
        else if (m[1] === "os" && SAFE_NAME.test(m[2].replace(/"/g, ""))) p.os = m[2].replace(/"/g, "");
    });
    if (p.pkg !== "pacman") p.aur = "";
    if (p.init === "runit" && !p.svdir) p.svdir = "/run/runit/service";
    return p;
}

function checks(plat) {
    var out = [];
    if (plat && has(PKG, plat.pkg)) out = out.concat(PKG[plat.pkg].checks(plat));
    if (plat && has(INIT, plat.init))
        out.push({id: "svc.list", group: "services", timeout: 15, when: "true", cmd: INIT[plat.init].list(plat), parse: INIT[plat.init].parse});
    return out;
}

function withPriv(cmd, plat) {
    return plat.priv === "doas" ? cmd.replace(/\bsudo -E /g, "doas ").replace(/\bsudo /g, "doas ") : cmd;
}

function command(plat, action, arg, scope) {
    var serviceAction = ["restartService", "stopService", "startService", "serviceLogs", "reboot"].indexOf(action) >= 0;
    var backend = serviceAction ? (has(INIT, plat.init) ? INIT[plat.init] : null) : (has(PKG, plat.pkg) ? PKG[plat.pkg] : null);
    if (!backend) return {error: serviceAction ? "no supported service manager found" : "no supported package manager found"};
    var fn = has(backend.actions, action) ? backend.actions[action] : null;
    if (!fn) return {error: action + " is not supported with " + (serviceAction ? plat.init : plat.pkg)};
    if (serviceAction && action !== "reboot" && !SAFE_NAME.test(text(arg))) return {error: "bad service name"};
    if (scope === "user" && plat.init === "runit" && !plat.usvdir) return {error: "no user service directory found"};
    var raw = fn(arg, plat, scope);
    var cmd = withPriv(raw, plat);
    // quiet: runs without a terminal, privileged parts through polkit; null when only a terminal can ask for a password
    var quiet = raw.indexOf("sudo ") < 0 ? cmd : (plat.priv === "doas" ? null : raw.replace(/\bsudo /g, "pkexec "));
    return {cmd: cmd, quiet: quiet};
}

function supports(plat, action) {
    var b = has(PKG, plat.pkg) ? PKG[plat.pkg] : null;
    var i = has(INIT, plat.init) ? INIT[plat.init] : null;
    return !!((b && has(b.actions, action)) || (i && has(i.actions, action)));
}
