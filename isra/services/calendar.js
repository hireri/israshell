.pragma library

function pad(n) {
    return (n < 10 ? "0" : "") + n;
}

function dayKey(x) {
    var t = new Date(x);
    return t.getFullYear() + "-" + pad(t.getMonth() + 1) + "-" + pad(t.getDate());
}

function addDays(ms, n) {
    var t = new Date(ms);
    return new Date(t.getFullYear(), t.getMonth(), t.getDate() + n).getTime();
}

function monthGrid(year, month, firstDow) {
    var offset = (new Date(year, month, 1).getDay() - firstDow + 7) % 7;
    var cells = [];
    for (var i = 0; i < 42; i++) {
        var t = new Date(year, month, i - offset + 1);
        cells.push({y: t.getFullYear(), m: t.getMonth(), d: t.getDate(), inMonth: t.getMonth() === month, key: dayKey(t), col: i % 7});
    }
    return cells;
}

function isoWeek(y, m, d) {
    var t = new Date(Date.UTC(y, m, d));
    t.setUTCDate(t.getUTCDate() + 4 - (t.getUTCDay() || 7));
    var start = Date.UTC(t.getUTCFullYear(), 0, 1);
    return Math.ceil(((t.getTime() - start) / 86400000 + 1) / 7);
}

function parseDt(v) {
    var m = /^(\d{4})(\d{2})(\d{2})(T(\d{2})(\d{2})(\d{2})?(Z)?)?$/.exec(v.trim());
    if (!m) return null;
    var y = +m[1], mo = m[2] - 1, d = +m[3];
    if (!m[4]) return {ms: new Date(y, mo, d).getTime(), allDay: true};
    var h = +m[5], mi = +m[6], s = +(m[7] || 0);
    return {ms: m[8] ? Date.UTC(y, mo, d, h, mi, s) : new Date(y, mo, d, h, mi, s).getTime(), allDay: false};
}

function unesc(s) {
    return s.replace(/\\([nN,;\\])/g, function (_, c) {
        return c === "n" || c === "N" ? "\n" : c;
    });
}

function firstUrl(s) {
    var m = /https?:\/\/[^\s>")<]*[^\s>")<.,;:!?]/.exec(s || "");
    return m ? m[0] : "";
}

function parseRrule(v) {
    var o = {};
    v.split(";").forEach(function (p) {
        var kv = p.split("=");
        o[kv[0].toUpperCase()] = kv[1] || "";
    });
    if (["DAILY", "WEEKLY", "MONTHLY", "YEARLY"].indexOf(o.FREQ) < 0) return null;
    var names = ["SU", "MO", "TU", "WE", "TH", "FR", "SA"];
    var until = o.UNTIL ? parseDt(o.UNTIL) : null;
    return {
        freq: o.FREQ,
        interval: +o.INTERVAL || 1,
        count: +o.COUNT || 0,
        until: until ? until.ms : 0,
        byday: o.BYDAY ? o.BYDAY.split(",").map(function (s) {
            return names.indexOf(s.slice(-2).toUpperCase());
        }).filter(function (i) { return i >= 0; }) : []
    };
}

function parseTrigger(params, v) {
    var m = /^([+-]?)P(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$/.exec(v.trim().toUpperCase());
    if (!m || (!m[2] && !m[3] && !m[4] && !m[5]) || /VALUE=DATE|RELATED=END/i.test(params)) return -1;
    var min = (+(m[2] || 0)) * 1440 + (+(m[3] || 0)) * 60 + (+(m[4] || 0)) + (+(m[5] || 0)) / 60;
    if (m[1] !== "-" && min > 0) return -1;
    return Math.round(min);
}

function finish(c) {
    var end = c.end !== undefined ? c.end : (c.allDay ? addDays(c.start, 1) : c.start);
    var url = c.url || "";
    return {uid: c.uid || "", calendar: "", title: c.title || "", location: c.location || "", description: c.description || "", url: url, link: url || firstUrl(c.location) || firstUrl(c.description), start: c.start, end: end, allDay: !!c.allDay, rrule: c.rrule || null, exdates: c.exdates || [], reminder: c.reminder, urgent: !!c.urgent};
}

function parseIcs(text) {
    var lines = text.replace(/\r?\n[ \t]/g, "").split(/\r?\n/);
    var events = [];
    var cur = null;
    var inAlarm = false;
    var alarms = 0;
    lines.forEach(function (line) {
        var c = line.indexOf(":");
        if (c < 0) return;
        var name = line.slice(0, c).split(";")[0].toUpperCase();
        var value = line.slice(c + 1);
        var upper = value.toUpperCase();
        if (name === "BEGIN") {
            if (upper === "VEVENT") { cur = {reminder: -1}; alarms = 0; }
            if (upper === "VALARM") { inAlarm = true; alarms++; }
        } else if (name === "END") {
            if (upper === "VALARM") inAlarm = false;
            if (upper === "VEVENT" && cur) {
                if (cur.start !== undefined) events.push(finish(cur));
                cur = null;
            }
        } else if (cur && inAlarm) {
            if (name === "TRIGGER" && alarms === 1) cur.reminder = parseTrigger(line.slice(0, c), value);
        } else if (cur) {
            var dt = parseDt(value);
            if (name === "UID") cur.uid = value;
            else if (name === "SUMMARY") cur.title = unesc(value);
            else if (name === "DESCRIPTION") cur.description = unesc(value);
            else if (name === "LOCATION") cur.location = unesc(value);
            else if (name === "URL") cur.url = unesc(value);
            else if (name === "DTSTART" && dt) { cur.start = dt.ms; cur.allDay = dt.allDay; }
            else if (name === "DTEND" && dt) cur.end = dt.ms;
            else if (name === "PRIORITY") cur.urgent = parseInt(value, 10) >= 1 && parseInt(value, 10) <= 4;
            else if (name === "RRULE") cur.rrule = parseRrule(value);
            else if (name === "EXDATE") cur.exdates = (cur.exdates || []).concat(value.split(",").map(parseDt).filter(Boolean).map(function (p) { return p.ms; }));
        }
    });
    return events;
}

function recurHit(r, k, bd, cd) {
    if (r.freq === "DAILY") return k % r.interval === 0;
    if (r.freq === "WEEKLY") {
        var days = r.byday.length ? r.byday : [bd.getDay()];
        return Math.floor((k + (bd.getDay() + 6) % 7) / 7) % r.interval === 0 && days.indexOf(cd.getDay()) >= 0;
    }
    if (r.freq === "MONTHLY") return cd.getDate() === bd.getDate() && ((cd.getFullYear() - bd.getFullYear()) * 12 + cd.getMonth() - bd.getMonth()) % r.interval === 0;
    return cd.getMonth() === bd.getMonth() && cd.getDate() === bd.getDate() && (cd.getFullYear() - bd.getFullYear()) % r.interval === 0;
}

function expand(events, fromMs, toMs) {
    var out = [];
    function emit(ev, s, e) {
        if (s < toMs && Math.max(e, s + 1) > fromMs) {
            out.push({uid: ev.uid, calendar: ev.calendar, title: ev.title, location: ev.location, description: ev.description, url: ev.url, link: ev.link, start: s, end: e, allDay: ev.allDay, reminder: ev.reminder, urgent: ev.urgent, recurring: !!ev.rrule, seriesStart: ev.start});
            return true;
        }
        return false;
    }
    events.forEach(function (ev) {
        if (!ev.rrule) {
            emit(ev, ev.start, ev.end);
            return;
        }
        var r = ev.rrule;
        var dur = ev.end - ev.start;
        var bd = new Date(ev.start);
        var k = r.count ? 0 : Math.max(0, Math.floor((fromMs - ev.start - dur) / 86400000) - 2);
        var seen = 0;
        var n = 0;
        for (; ; k++) {
            var cd = new Date(bd.getFullYear(), bd.getMonth(), bd.getDate() + k);
            if (k !== 0 && !recurHit(r, k, bd, cd)) continue;
            var os = new Date(cd.getFullYear(), cd.getMonth(), cd.getDate(), bd.getHours(), bd.getMinutes(), bd.getSeconds(), bd.getMilliseconds()).getTime();
            if (os >= toMs || (r.until && os > r.until)) break;
            if (r.count && ++seen > r.count) break;
            if (ev.exdates.indexOf(os) >= 0) continue;
            if (emit(ev, os, os + dur) && ++n >= 1000) break;
        }
    });
    return out.sort(function (a, b) { return a.start - b.start; });
}

function groupByDay(occs) {
    var out = {};
    occs.forEach(function (o) {
        var d = new Date(o.start);
        do {
            var k = dayKey(d);
            if (!out[k]) out[k] = [];
            out[k].push(o);
            d = new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1);
        } while (d.getTime() < o.end);
    });
    Object.keys(out).forEach(function (k) {
        out[k].sort(function (a, b) { return (b.allDay - a.allDay) || (a.start - b.start); });
    });
    return out;
}

function newUid() {
    var rnd = "";
    while (rnd.length < 8) rnd += Math.random().toString(36).slice(2);
    return "isra-" + Date.now().toString(36) + "-" + rnd.slice(0, 8) + "@isra";
}

function withExdate(ev, startMs) {
    var ex = (ev.exdates || []).slice();
    if (ex.indexOf(startMs) < 0) ex.push(startMs);
    return Object.assign({}, ev, {exdates: ex});
}

function utcStamp(ms) {
    var t = new Date(ms);
    return t.getUTCFullYear() + pad(t.getUTCMonth() + 1) + pad(t.getUTCDate()) + "T" + pad(t.getUTCHours()) + pad(t.getUTCMinutes()) + pad(t.getUTCSeconds()) + "Z";
}

function escText(s) {
    return String(s || "").replace(/[\\;,]/g, "\\$&").replace(/\r\n|\r|\n/g, "\\n");
}

function fold(line) {
    var out = line.slice(0, 75);
    for (var i = 75; i < line.length; i += 74) out += "\r\n " + line.slice(i, i + 74);
    return out;
}

function serializeEvent(ev) {
    var names = ["SU", "MO", "TU", "WE", "TH", "FR", "SA"];
    var allDay = !!ev.allDay;
    var start = ev.start;
    var end = ev.end > start ? ev.end : (allDay ? addDays(start, 1) : start);
    var r = ev.rrule;
    var lines = ["BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//isra//calendar//EN", "BEGIN:VEVENT", "UID:" + (ev.uid || newUid()), "DTSTAMP:" + utcStamp(Date.now())];
    lines.push(allDay ? "DTSTART;VALUE=DATE:" + dayKey(start).replace(/-/g, "") : "DTSTART:" + utcStamp(start));
    lines.push(allDay ? "DTEND;VALUE=DATE:" + dayKey(end).replace(/-/g, "") : "DTEND:" + utcStamp(end));
    lines.push("SUMMARY:" + escText(ev.title));
    if (ev.location) lines.push("LOCATION:" + escText(ev.location));
    if (ev.url) lines.push("URL:" + escText(ev.url));
    if (ev.urgent) lines.push("PRIORITY:1");
    if (ev.description) lines.push("DESCRIPTION:" + escText(ev.description));
    if (r) {
        var rule = ["FREQ=" + r.freq];
        if (r.interval > 1) rule.push("INTERVAL=" + r.interval);
        if (r.count > 0) rule.push("COUNT=" + r.count);
        if (r.until > 0) rule.push("UNTIL=" + utcStamp(r.until));
        if (r.byday && r.byday.length) rule.push("BYDAY=" + r.byday.filter(function (i) { return names[i]; }).map(function (i) { return names[i]; }).join(","));
        lines.push("RRULE:" + rule.join(";"));
    }
    (ev.exdates || []).forEach(function (x) {
        lines.push(allDay ? "EXDATE;VALUE=DATE:" + dayKey(x).replace(/-/g, "") : "EXDATE:" + utcStamp(x));
    });
    if (ev.reminder >= 0) {
        lines.push("BEGIN:VALARM", "ACTION:DISPLAY", "DESCRIPTION:" + escText(ev.title || "Reminder"), "TRIGGER:" + (ev.reminder ? "-PT" + ev.reminder + "M" : "-PT0S"), "END:VALARM");
    }
    lines.push("END:VEVENT", "END:VCALENDAR");
    return lines.map(fold).join("\r\n") + "\r\n";
}
