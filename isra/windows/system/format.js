.pragma library

function duration(secs) {
    var s = Math.max(0, Number(secs) || 0);
    var m = Math.round(s / 60);
    if (m < 1)
        return s >= 1 ? "<1m" : "0m";
    var h = Math.floor(m / 60);
    return h > 0 ? h + "h " + (m % 60 < 10 ? "0" : "") + (m % 60) + "m" : m + "m";
}

function bytes(n) {
    var v = Math.max(0, Number(n) || 0);
    var units = ["B", "KiB", "MiB", "GiB", "TiB"];
    var i = 0;
    while (v >= 1024 && i < units.length - 1) {
        v /= 1024;
        i++;
    }
    return (i === 0 || v >= 100 ? Math.round(v) : Math.round(v * 10) / 10) + " " + units[i];
}

function clock(ms) {
    if (!(ms > 0))
        return "";
    var d = new Date(ms);
    return (d.getHours() < 10 ? "0" : "") + d.getHours() + ":" + (d.getMinutes() < 10 ? "0" : "") + d.getMinutes();
}

function ago(ms, now) {
    var s = Math.max(0, Math.round(((now || Date.now()) - ms) / 1000));
    if (s < 60)
        return "<1m";
    var m = Math.round(s / 60);
    if (m < 60)
        return m + "m";
    var h = Math.round(m / 60);
    return h < 48 ? h + "h" : Math.round(h / 24) + "d";
}

function pctText(x) {
    return Math.round(Math.max(0, Math.min(1, Number(x) || 0)) * 100) + "%";
}

function needsRestart(name) {
    return /^(linux(-(lts|zen|hardened|rt))?|linux-firmware|systemd|glibc|nvidia(-.+)?|[a-z]+-ucode)$/.test(String(name));
}

function hash(s) {
    var h = 0;
    s = String(s);
    for (var i = 0; i < s.length; i++)
        h = (h * 31 + s.charCodeAt(i)) >>> 0;
    return h;
}

function pacmanTime(line) {
    var m = /^\[(\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d)([+-]\d\d)(\d\d)\]/.exec(String(line));
    return m ? Date.parse(m[1] + m[2] + ":" + m[3]) : 0;
}
