.pragma library

var HOURS = 24;
var MAX_APPS = 120;
var MAX_TITLES = 20;
var MAX_TITLE_LEN = 120;
var MAX_WS = 16;
var MAX_PLAYERS = 16;
var GAP_CAP = 180;
var UNATTRIBUTED = "_";
var CATEGORIES = ["work", "web", "fun", "other"];

var FUN = ["Game", "InstantMessaging", "Chat", "IRCClient", "AudioVideo", "Audio", "Video", "Music", "Player", "Recorder", "Social", "Feed"];
var WORK = ["Development", "IDE", "TextEditor", "TerminalEmulator", "Office", "Spreadsheet", "WordProcessor", "Presentation", "Science", "Math", "Engineering", "ProjectManagement", "Database"];
var WEB = ["WebBrowser", "Network"];

function pad(n) {
    return (n < 10 ? "0" : "") + n;
}

function dayKey(ms) {
    var t = new Date(ms);
    return t.getFullYear() + "-" + pad(t.getMonth() + 1) + "-" + pad(t.getDate());
}

function monthKey(ms) {
    var t = new Date(ms);
    return t.getFullYear() + "-" + pad(t.getMonth() + 1);
}

function monthOfDay(key) {
    return String(key).slice(0, 7);
}

function dayStart(key) {
    var p = String(key).split("-");
    return new Date(Number(p[0]), Number(p[1]) - 1, Number(p[2])).getTime();
}

function addDays(key, n) {
    var p = String(key).split("-");
    return dayKey(new Date(Number(p[0]), Number(p[1]) - 1, Number(p[2]) + n).getTime());
}

function zeros() {
    var a = [];
    for (var i = 0; i < HOURS; i++)
        a.push(0);
    return a;
}

function round1(x) {
    return Math.round(x * 10) / 10;
}

function num(x) {
    return typeof x === "number" && isFinite(x) && x >= 0 ? x : 0;
}

function emptyApp() {
    return { s: 0, h: zeros(), ss: 0, nt: 0, fs: 0, ws: {} };
}

function emptyDay() {
    return { total: 0, longest: 0, unlocks: 0, first: 0, last: 0, apps: {}, titles: {}, media: {} };
}

function emptyMonth() {
    return { v: 1, days: {} };
}

function split(startMs, endMs) {
    var secs = (endMs - startMs) / 1000;
    if (!(secs > 0) || secs > GAP_CAP)
        return [];
    var out = [];
    var t = startMs;
    while (t < endMs) {
        var d = new Date(t);
        var next = new Date(d.getFullYear(), d.getMonth(), d.getDate(), d.getHours() + 1).getTime();
        if (!(next > t))
            next = t + 3600000;
        var stop = Math.min(next, endMs);
        out.push({ day: dayKey(t), hour: d.getHours(), secs: (stop - t) / 1000, at: t });
        t = stop;
    }
    return out;
}

function appSlot(day, appId) {
    var id = String(appId || UNATTRIBUTED);
    if (!day.apps[id] && Object.keys(day.apps).length >= MAX_APPS)
        id = UNATTRIBUTED;
    if (!day.apps[id])
        day.apps[id] = emptyApp();
    return day.apps[id];
}

function bump(map, key, secs, cap) {
    if (map[key] === undefined && Object.keys(map).length >= cap)
        return false;
    map[key] = round1((map[key] || 0) + secs);
    return true;
}

function addUsage(day, seg, appId, o) {
    var a = appSlot(day, appId);
    var id = a === day.apps[UNATTRIBUTED] ? UNATTRIBUTED : String(appId);
    var s = seg.secs;
    a.s = round1(a.s + s);
    if (o.hourly !== false)
        a.h[seg.hour] = round1(a.h[seg.hour] + s);
    day.total = round1(day.total + s);
    if (!day.first || seg.at < day.first)
        day.first = seg.at;
    var end = seg.at + s * 1000;
    if (end > day.last)
        day.last = end;
    if (o.fullscreen)
        a.fs = round1(a.fs + s);
    if (o.workspace !== undefined && o.workspace !== null && o.workspace >= 0)
        bump(a.ws, String(o.workspace), s, MAX_WS);
    if (o.title && id !== UNATTRIBUTED) {
        if (!day.titles[id])
            day.titles[id] = {};
        bump(day.titles[id], String(o.title).slice(0, MAX_TITLE_LEN), s, MAX_TITLES);
    }
    return id;
}

function addMedia(day, player, secs) {
    bump(day.media, String(player || UNATTRIBUTED).slice(0, 60), secs, MAX_PLAYERS);
}

function addSession(day, appId) {
    appSlot(day, appId).ss += 1;
}

function addNotification(day, appId) {
    appSlot(day, appId).nt += 1;
}

function addUnlock(day) {
    day.unlocks += 1;
}

function noteRun(day, secs) {
    if (secs > day.longest)
        day.longest = round1(secs);
}

function sanitizeMap(raw, cap) {
    var out = {};
    if (!raw || typeof raw !== "object")
        return out;
    var keys = Object.keys(raw);
    for (var i = 0; i < keys.length && i < cap; i++)
        out[keys[i]] = num(raw[keys[i]]);
    return out;
}

function sanitizeApp(raw) {
    var a = emptyApp();
    if (!raw || typeof raw !== "object")
        return a;
    a.s = num(raw.s);
    a.ss = Math.floor(num(raw.ss));
    a.nt = Math.floor(num(raw.nt));
    a.fs = num(raw.fs);
    if (Array.isArray(raw.h))
        for (var i = 0; i < HOURS; i++)
            a.h[i] = num(raw.h[i]);
    a.ws = sanitizeMap(raw.ws, MAX_WS);
    return a;
}

function sanitizeDay(raw) {
    var d = emptyDay();
    if (!raw || typeof raw !== "object")
        return d;
    d.total = num(raw.total);
    d.longest = num(raw.longest);
    d.unlocks = Math.floor(num(raw.unlocks));
    d.first = num(raw.first);
    d.last = num(raw.last);
    if (raw.apps && typeof raw.apps === "object") {
        var ids = Object.keys(raw.apps);
        for (var i = 0; i < ids.length && i < MAX_APPS; i++)
            d.apps[ids[i]] = sanitizeApp(raw.apps[ids[i]]);
    }
    if (raw.titles && typeof raw.titles === "object") {
        var tk = Object.keys(raw.titles);
        for (var j = 0; j < tk.length && j < MAX_APPS; j++)
            d.titles[tk[j]] = sanitizeMap(raw.titles[tk[j]], MAX_TITLES);
    }
    d.media = sanitizeMap(raw.media, MAX_PLAYERS);
    return d;
}

function mergeMaps(a, b, cap) {
    var ks = Object.keys(b);
    for (var i = 0; i < ks.length; i++)
        bump(a, ks[i], b[ks[i]], cap);
}

function mergeDay(a, b) {
    a.total = round1(a.total + b.total);
    a.longest = Math.max(a.longest, b.longest);
    a.unlocks += b.unlocks;
    a.first = a.first && b.first ? Math.min(a.first, b.first) : (a.first || b.first);
    a.last = Math.max(a.last, b.last);
    var ids = Object.keys(b.apps);
    for (var i = 0; i < ids.length; i++) {
        var src = b.apps[ids[i]];
        var dst = appSlot(a, ids[i]);
        dst.s = round1(dst.s + src.s);
        dst.ss += src.ss;
        dst.nt += src.nt;
        dst.fs = round1(dst.fs + src.fs);
        for (var h = 0; h < HOURS; h++)
            dst.h[h] = round1(dst.h[h] + src.h[h]);
        mergeMaps(dst.ws, src.ws, MAX_WS);
    }
    var tk = Object.keys(b.titles);
    for (var j = 0; j < tk.length; j++) {
        if (!a.titles[tk[j]])
            a.titles[tk[j]] = {};
        mergeMaps(a.titles[tk[j]], b.titles[tk[j]], MAX_TITLES);
    }
    mergeMaps(a.media, b.media, MAX_PLAYERS);
    return a;
}

function parseMonth(text) {
    if (!text)
        return null;
    var raw;
    try {
        raw = JSON.parse(text);
    } catch (e) {
        return null;
    }
    if (!raw || typeof raw !== "object" || !raw.days || typeof raw.days !== "object")
        return null;
    var m = emptyMonth();
    var keys = Object.keys(raw.days);
    for (var i = 0; i < keys.length && i < 31; i++)
        if (/^\d{4}-\d{2}-\d{2}$/.test(keys[i]))
            m.days[keys[i]] = sanitizeDay(raw.days[keys[i]]);
    return m;
}

function asciiJson(value) {
    return JSON.stringify(value).replace(/[\u007f-￿]/g, function (c) {
        return "\\u" + ("0000" + c.charCodeAt(0).toString(16)).slice(-4);
    });
}

function serializeMonth(month) {
    return asciiJson(month);
}

function pruneable(monthKeys, nowMs, retentionDays) {
    if (!(retentionDays > 0))
        return [];
    var cutoff = nowMs - retentionDays * 86400000;
    return monthKeys.filter(function (k) {
        var p = String(k).split("-");
        if (p.length !== 2)
            return false;
        var end = new Date(Number(p[0]), Number(p[1]), 1).getTime();
        return end <= cutoff;
    });
}

function categoryFor(desktopCategories, override, appId) {
    if (CATEGORIES.indexOf(override) >= 0)
        return override;
    if (appId === UNATTRIBUTED)
        return "other";
    var cats = Array.isArray(desktopCategories) ? desktopCategories : [];
    function hit(list) {
        for (var i = 0; i < cats.length; i++)
            if (list.indexOf(cats[i]) >= 0)
                return true;
        return false;
    }
    if (hit(FUN))
        return "fun";
    if (hit(WORK))
        return "work";
    if (hit(WEB))
        return "web";
    return "other";
}

function blankSummary() {
    var hourly = {};
    var categories = {};
    for (var i = 0; i < CATEGORIES.length; i++) {
        hourly[CATEGORIES[i]] = zeros();
        categories[CATEGORIES[i]] = 0;
    }
    return { hasData: false, total: 0, unlocks: 0, notifications: 0, sessions: 0, longest: 0, first: 0, last: 0, activeDays: 0, fullscreen: 0, hourlyCoverage: 1, apps: [], categories: categories, hourly: hourly, workspaces: {}, media: {} };
}

function summarize(entries, ctx) {
    var excluded = (ctx && ctx.excluded) || [];
    var catOf = (ctx && ctx.categoryOf) || function () {
        return "other";
    };
    var res = blankSummary();
    var byApp = {};
    var hourSum = 0;
    for (var e = 0; e < entries.length; e++) {
        var day = entries[e].day;
        if (!day)
            continue;
        var dayTotal = 0;
        var ids = Object.keys(day.apps);
        for (var i = 0; i < ids.length; i++) {
            var id = ids[i];
            if (excluded.indexOf(id) >= 0)
                continue;
            var a = day.apps[id];
            var cat = id === UNATTRIBUTED ? "other" : catOf(id);
            if (CATEGORIES.indexOf(cat) < 0)
                cat = "other";
            var row = byApp[id] || (byApp[id] = { id: id, seconds: 0, sessions: 0, notifications: 0, fullscreen: 0, category: cat, hours: zeros() });
            row.seconds += a.s;
            row.sessions += a.ss;
            row.notifications += a.nt;
            row.fullscreen += a.fs;
            dayTotal += a.s;
            res.categories[cat] += a.s;
            res.notifications += a.nt;
            res.sessions += a.ss;
            res.fullscreen += a.fs;
            for (var h = 0; h < HOURS; h++) {
                res.hourly[cat][h] += a.h[h];
                row.hours[h] += a.h[h];
                hourSum += a.h[h];
            }
            var wk = Object.keys(a.ws);
            for (var w = 0; w < wk.length; w++)
                res.workspaces[wk[w]] = (res.workspaces[wk[w]] || 0) + a.ws[wk[w]];
        }
        var mk = Object.keys(day.media);
        for (var m = 0; m < mk.length; m++)
            res.media[mk[m]] = (res.media[mk[m]] || 0) + day.media[mk[m]];
        res.total += dayTotal;
        res.unlocks += day.unlocks;
        res.longest = Math.max(res.longest, day.longest);
        if (day.first && (!res.first || day.first < res.first))
            res.first = day.first;
        res.last = Math.max(res.last, day.last);
        if (dayTotal > 0)
            res.activeDays += 1;
    }
    var list = Object.keys(byApp).map(function (k) {
        return byApp[k];
    });
    list.sort(function (x, y) {
        return y.seconds - x.seconds;
    });
    for (var n = 0; n < list.length; n++)
        list[n].share = res.total > 0 ? list[n].seconds / res.total : 0;
    res.apps = list;
    res.hasData = res.total > 0 || res.unlocks > 0 || res.notifications > 0;
    res.hourlyCoverage = res.total > 0 ? Math.min(1, hourSum / res.total) : 1;
    return res;
}

function perDay(entries, ctx) {
    var excluded = (ctx && ctx.excluded) || [];
    return entries.map(function (en) {
        var t = 0;
        if (en.day) {
            var ids = Object.keys(en.day.apps);
            for (var i = 0; i < ids.length; i++)
                if (excluded.indexOf(ids[i]) < 0)
                    t += en.day.apps[ids[i]].s;
        }
        return { key: en.key, total: t };
    });
}

function average(totals, exceptKey) {
    var sum = 0;
    var n = 0;
    for (var i = 0; i < totals.length; i++) {
        if (totals[i].key === exceptKey || !(totals[i].total > 0))
            continue;
        sum += totals[i].total;
        n++;
    }
    return n > 0 ? sum / n : 0;
}

function hm(secs) {
    var m = Math.round(num(secs) / 60);
    return { h: Math.floor(m / 60), m: m % 60 };
}
