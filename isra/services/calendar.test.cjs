const assert = require("assert");
const fs = require("fs");
const path = require("path");

const src = fs.readFileSync(path.join(__dirname, "calendar.js"), "utf8").replace(/^\.pragma library[^\n]*\n/, "");
const C = new Function(src + "; return {dayKey, monthGrid, isoWeek, parseIcs, expand, groupByDay, serializeEvent, newUid, withExdate};")();

const at = (y, m, d, h = 0, mi = 0) => new Date(y, m, d, h, mi).getTime();
const starts = (occs) => occs.map((o) => o.start);
const uids = (occs) => occs.map((o) => o.uid);
const one = (lines) => C.parseIcs(["BEGIN:VEVENT", "UID:x", "SUMMARY:s", ...lines, "END:VEVENT"].join("\n"))[0];

assert.strictEqual(C.dayKey(at(2026, 0, 5, 23, 59)), "2026-01-05");
assert.strictEqual(C.dayKey(new Date(2026, 9, 15)), "2026-10-15");

const g0 = C.monthGrid(2026, 9, 0);
assert.strictEqual(g0.length, 42);
assert.deepStrictEqual(g0[0], {y: 2026, m: 8, d: 27, inMonth: false, key: "2026-09-27", col: 0});
assert.strictEqual(g0[4].key, "2026-10-01");
assert.strictEqual(g0[4].inMonth, true);
assert.strictEqual(g0.filter((c) => c.inMonth).length, 31);
assert.ok(g0.every((c, i) => c.col === i % 7));

const g1 = C.monthGrid(2026, 9, 1);
assert.strictEqual(g1.length, 42);
assert.strictEqual(g1[0].key, "2026-09-28");
assert.strictEqual(g1[0].col, 0);
assert.strictEqual(g1[3].key, "2026-10-01");
assert.strictEqual(g1.filter((c) => c.inMonth).length, 31);

const feb = C.monthGrid(2024, 1, 0);
assert.strictEqual(feb.length, 42);
assert.strictEqual(feb[0].key, "2024-01-28");
assert.strictEqual(feb[4].key, "2024-02-01");
assert.strictEqual(feb.filter((c) => c.inMonth).length, 29);

assert.strictEqual(C.isoWeek(2026, 0, 1), 1);
assert.strictEqual(C.isoWeek(2024, 11, 30), 1);
assert.strictEqual(C.isoWeek(2021, 0, 3), 53);
assert.strictEqual(C.isoWeek(2026, 9, 15), 42);

const feed = [
    "BEGIN:VCALENDAR", "VERSION:2.0",
    "BEGIN:VEVENT", "UID:a1",
    "SUMMARY:Team\\, sync\\; weekly\\nnotes", "LOCATION:Room 4",
    "DTSTART;TZID=Europe/Berlin:20261005T093000", "DTEND;TZID=Europe/Berlin:20261005T100000",
    "RRULE:FREQ=WEEKLY;BYDAY=2MO,WE;COUNT=6",
    "BEGIN:VALARM", "TRIGGER:-PT10M", "SUMMARY:Alarm leak", "END:VALARM",
    "END:VEVENT",
    "BEGIN:VEVENT", "UID:a2", "SUMMARY:Utc thi", " ng",
    "DTSTART:20261015T093000Z", "DTEND:20261015T103000Z", "END:VEVENT",
    "BEGIN:VEVENT", "UID:a3", "SUMMARY:Holiday",
    "DTSTART;VALUE=DATE:20261012", "DTEND;VALUE=DATE:20261015", "END:VEVENT",
    "BEGIN:VEVENT", "UID:a4", "SUMMARY:No start", "END:VEVENT",
    "END:VCALENDAR",
].join("\r\n");

const evs = C.parseIcs(feed);
assert.deepStrictEqual(uids(evs), ["a1", "a2", "a3"]);
const [a1, a2, a3] = evs;
assert.strictEqual(a1.title, "Team, sync; weekly\nnotes");
assert.strictEqual(a1.location, "Room 4");
assert.strictEqual(a1.start, at(2026, 9, 5, 9, 30));
assert.strictEqual(a1.end, at(2026, 9, 5, 10, 0));
assert.strictEqual(a1.allDay, false);
assert.deepStrictEqual(a1.rrule, {freq: "WEEKLY", interval: 1, count: 6, until: 0, byday: [1, 3]});
assert.deepStrictEqual(a1.exdates, []);
assert.strictEqual(a2.title, "Utc thing");
assert.strictEqual(a2.start, Date.UTC(2026, 9, 15, 9, 30));
assert.strictEqual(a2.end, Date.UTC(2026, 9, 15, 10, 30));
assert.strictEqual(a2.rrule, null);
assert.strictEqual(a3.allDay, true);
assert.strictEqual(a3.start, at(2026, 9, 12));
assert.strictEqual(a3.end, at(2026, 9, 15));
assert.strictEqual(one(["DTSTART;VALUE=DATE:20261012"]).end, at(2026, 9, 13));
assert.strictEqual(one(["DTSTART:20261012T080000"]).end, at(2026, 9, 12, 8));

const weekly = one(["DTSTART:20261005T093000", "DTEND:20261005T100000", "RRULE:FREQ=WEEKLY;BYDAY=MO,WE;COUNT=6"]);
const wAll = C.expand([weekly], at(2026, 9, 1), at(2026, 10, 30));
assert.deepStrictEqual(starts(wAll), [
    at(2026, 9, 5, 9, 30), at(2026, 9, 7, 9, 30), at(2026, 9, 12, 9, 30),
    at(2026, 9, 14, 9, 30), at(2026, 9, 19, 9, 30), at(2026, 9, 21, 9, 30),
]);
assert.strictEqual(wAll[0].end - wAll[0].start, 30 * 60000);
assert.deepStrictEqual(starts(C.expand([weekly], at(2026, 9, 13), at(2026, 9, 20))), [at(2026, 9, 14, 9, 30), at(2026, 9, 19, 9, 30)]);
assert.strictEqual(C.expand([weekly], at(2026, 9, 22), at(2027, 0, 31)).length, 0);

const monthly = one(["DTSTART:20260115T100000", "DTEND:20260115T110000", "RRULE:FREQ=MONTHLY;UNTIL=20260615T235959"]);
assert.deepStrictEqual(starts(C.expand([monthly], at(2026, 0, 1), at(2027, 11, 31))), [0, 1, 2, 3, 4, 5].map((m) => at(2026, m, 15, 10)));
const monthly31 = one(["DTSTART:20260131T120000", "DTEND:20260131T130000", "RRULE:FREQ=MONTHLY;COUNT=4"]);
assert.deepStrictEqual(starts(C.expand([monthly31], at(2026, 0, 1), at(2026, 11, 31))), [at(2026, 0, 31, 12), at(2026, 2, 31, 12), at(2026, 4, 31, 12), at(2026, 6, 31, 12)]);

const daily = one(["DTSTART:20261010T080000", "DTEND:20261010T090000", "RRULE:FREQ=DAILY", "EXDATE;TZID=Europe/Berlin:20261012T080000"]);
assert.deepStrictEqual(starts(C.expand([daily], at(2026, 9, 10), at(2026, 9, 14))), [at(2026, 9, 10, 8), at(2026, 9, 11, 8), at(2026, 9, 13, 8)]);
assert.deepStrictEqual(starts(C.expand([daily], at(2026, 9, 20), at(2026, 9, 21))), [at(2026, 9, 20, 8)]);
assert.deepStrictEqual(starts(C.expand([daily, weekly], at(2026, 9, 10), at(2026, 9, 13))), [at(2026, 9, 10, 8), at(2026, 9, 11, 8), at(2026, 9, 12, 9, 30)]);

const yearly = one(["DTSTART:20200303T090000", "DTEND:20200303T100000", "RRULE:FREQ=YEARLY;INTERVAL=2"]);
assert.deepStrictEqual(starts(C.expand([yearly], at(2026, 0, 1), at(2028, 11, 31))), [at(2026, 2, 3, 9), at(2028, 2, 3, 9)]);

const day = C.parseIcs([
    "BEGIN:VEVENT", "UID:h", "SUMMARY:Trip", "DTSTART;VALUE=DATE:20261012", "DTEND;VALUE=DATE:20261015", "END:VEVENT",
    "BEGIN:VEVENT", "UID:t", "SUMMARY:Timed", "DTSTART:20261012T080000", "DTEND:20261012T090000", "END:VEVENT",
    "BEGIN:VEVENT", "UID:n", "SUMMARY:Night", "DTSTART:20261020T220000", "DTEND:20261021T010000", "END:VEVENT",
    "BEGIN:VEVENT", "UID:e", "SUMMARY:Ends midnight", "DTSTART:20261022T220000", "DTEND:20261023T000000", "END:VEVENT",
].join("\n"));
assert.strictEqual(C.expand(day, at(2026, 9, 15), at(2026, 9, 16)).length, 0);
const g = C.groupByDay(C.expand(day, at(2026, 9, 1), at(2026, 10, 1)));
assert.deepStrictEqual(Object.keys(g).sort(), ["2026-10-12", "2026-10-13", "2026-10-14", "2026-10-20", "2026-10-21", "2026-10-22"]);
assert.deepStrictEqual(uids(g["2026-10-12"]), ["h", "t"]);
assert.deepStrictEqual(uids(g["2026-10-13"]), ["h"]);
assert.deepStrictEqual(uids(g["2026-10-14"]), ["h"]);
assert.strictEqual(g["2026-10-15"], undefined);
assert.deepStrictEqual(uids(g["2026-10-20"]), ["n"]);
assert.deepStrictEqual(uids(g["2026-10-21"]), ["n"]);
assert.deepStrictEqual(uids(g["2026-10-22"]), ["e"]);
assert.strictEqual(g["2026-10-23"], undefined);

assert.strictEqual(a1.reminder, 10);
assert.strictEqual(a1.description, "");
assert.strictEqual(a1.calendar, "");
assert.strictEqual(a2.reminder, -1);

const remindOf = (...lines) => C.parseIcs(["BEGIN:VEVENT", "UID:r", "DTSTART:20261005T093000Z", ...lines, "END:VEVENT"].join("\n"))[0].reminder;
assert.strictEqual(remindOf("BEGIN:VALARM", "TRIGGER:-PT1H30M", "END:VALARM"), 90);
assert.strictEqual(remindOf("BEGIN:VALARM", "TRIGGER:-PT1H", "END:VALARM"), 60);
assert.strictEqual(remindOf("BEGIN:VALARM", "TRIGGER:-PT15M", "END:VALARM"), 15);
assert.strictEqual(remindOf("BEGIN:VALARM", "TRIGGER:-P1D", "END:VALARM"), 1440);
assert.strictEqual(remindOf("BEGIN:VALARM", "TRIGGER:-P1DT2H", "END:VALARM"), 1560);
assert.strictEqual(remindOf("BEGIN:VALARM", "TRIGGER:PT0S", "END:VALARM"), 0);
assert.strictEqual(remindOf("BEGIN:VALARM", "TRIGGER:-PT0S", "END:VALARM"), 0);
assert.strictEqual(remindOf("BEGIN:VALARM", "TRIGGER:PT15M", "END:VALARM"), -1);
assert.strictEqual(remindOf("BEGIN:VALARM", "TRIGGER;RELATED=END:-PT15M", "END:VALARM"), -1);
assert.strictEqual(remindOf("BEGIN:VALARM", "TRIGGER;VALUE=DATE-TIME:20261005T090000Z", "END:VALARM"), -1);
assert.strictEqual(remindOf("BEGIN:VALARM", "TRIGGER:-PT5M", "END:VALARM", "BEGIN:VALARM", "TRIGGER:-PT30M", "END:VALARM"), 5);
assert.strictEqual(remindOf(), -1);
const withAlarmText = C.parseIcs(["BEGIN:VEVENT", "UID:d", "DTSTART:20261005T093000Z", "DESCRIPTION:Hello\\, world", "BEGIN:VALARM", "TRIGGER:-PT1H30M", "DESCRIPTION:alarm text", "END:VALARM", "END:VEVENT"].join("\n"))[0];
assert.strictEqual(withAlarmText.description, "Hello, world");
assert.strictEqual(withAlarmText.reminder, 90);

const mk = (over) => Object.assign({uid: "rt@isra", calendar: "", title: "", location: "", description: "", url: "", link: "",start: at(2026, 9, 5, 9, 30), end: at(2026, 9, 5, 10, 0), allDay: false, rrule: null, exdates: [], reminder: -1, urgent: false}, over);
const rtCases = [
    mk({title: "Standup", location: "Room 4"}),
    mk({title: "Holiday", allDay: true, start: at(2026, 9, 12), end: at(2026, 9, 15)}),
    mk({title: "Weekly", rrule: {freq: "WEEKLY", interval: 1, count: 0, until: 0, byday: [1, 3]}, exdates: [at(2026, 9, 7, 9, 30)]}),
    mk({title: "Every 3 days", rrule: {freq: "DAILY", interval: 3, count: 0, until: Date.UTC(2027, 0, 1, 12), byday: []}}),
    mk({title: "Monthly", allDay: true, start: at(2026, 0, 31), end: at(2026, 1, 1), rrule: {freq: "MONTHLY", interval: 2, count: 4, until: 0, byday: []}, exdates: [at(2026, 2, 31)]}),
    mk({title: "Pre", reminder: 15}),
    mk({title: "At start", reminder: 0}),
    mk({title: "Escapes, text; with\\slash\nsecond line", description: "Line one, a; b\nLine two \\ end " + "x".repeat(120), reminder: 1440}),
    mk({title: "Explicit url", url: "https://meet.example.com/abc-def", link: "https://meet.example.com/abc-def"}),
    mk({title: "Url escapes", url: "https://x.example.com/a,b;c", link: "https://x.example.com/a,b;c"}),
    mk({title: "Zoom", description: "Join: https://zoom.us/j/123456789, passcode 4.", link: "https://zoom.us/j/123456789"}),
    mk({title: "Room link", location: "https://room.example.com/r", link: "https://room.example.com/r"}),
    mk({title: "Url and location", url: "https://meet.example.com/u", location: "https://room.example.com/r", link: "https://meet.example.com/u"}),
];
for (const e of rtCases) assert.deepStrictEqual(C.parseIcs(C.serializeEvent(e)), [Object.assign({}, e, {calendar: ""})]);

const ics = C.serializeEvent(mk({title: "a,b;c", start: Date.UTC(2026, 9, 15, 9, 30), end: Date.UTC(2026, 9, 15, 10, 30)}));
assert.ok(ics.startsWith("BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//isra//calendar//EN\r\nBEGIN:VEVENT\r\n"));
assert.ok(ics.endsWith("END:VEVENT\r\nEND:VCALENDAR\r\n"));
assert.ok(ics.includes("SUMMARY:a\\,b\\;c\r\n"));
assert.ok(ics.includes("DTSTART:20261015T093000Z\r\n"));
const long = C.serializeEvent(mk({title: "x".repeat(90), description: "d".repeat(200), reminder: 5}));
assert.ok(long.split("\r\n").every((l) => l.length <= 75));
assert.ok(long.split("\r\n").some((l) => l.startsWith(" ")));
assert.ok(!/[^\r]\n/.test(long));
const solo = C.serializeEvent(mk({allDay: true, start: at(2026, 9, 12), end: at(2026, 9, 12)}));
assert.ok(solo.includes("DTSTART;VALUE=DATE:20261012\r\n"));
assert.ok(solo.includes("DTEND;VALUE=DATE:20261013\r\n"));
assert.deepStrictEqual(C.parseIcs(C.serializeEvent({uid: "s@isra", start: at(2026, 9, 5, 9, 30), end: at(2026, 9, 5, 10, 0)})), [
    {uid: "s@isra", calendar: "", title: "", location: "", description: "", url: "", link: "", start: at(2026, 9, 5, 9, 30), end: at(2026, 9, 5, 10, 0), allDay: false, rrule: null, exdates: [], reminder: -1, urgent: false},
]);

const recurringNote = one(["DTSTART:20261005T093000", "DTEND:20261005T100000", "RRULE:FREQ=WEEKLY;COUNT=2", "DESCRIPTION:Bring notes", "BEGIN:VALARM", "TRIGGER:-PT10M", "END:VALARM"]);
const occ = C.expand([recurringNote], at(2026, 9, 1), at(2026, 10, 1));
assert.deepStrictEqual(starts(occ), [at(2026, 9, 5, 9, 30), at(2026, 9, 12, 9, 30)]);
occ.forEach((o) => {
    assert.strictEqual(o.recurring, true);
    assert.strictEqual(o.seriesStart, at(2026, 9, 5, 9, 30));
    assert.strictEqual(o.description, "Bring notes");
    assert.strictEqual(o.reminder, 10);
    assert.strictEqual(o.calendar, "");
});
const single = C.expand([one(["DTSTART:20261015T093000Z", "DTEND:20261015T103000Z"])], at(2026, 9, 1), at(2026, 10, 30));
assert.strictEqual(single[0].recurring, false);
assert.strictEqual(single[0].seriesStart, Date.UTC(2026, 9, 15, 9, 30));

const series = one(["DTSTART:20261005T093000", "DTEND:20261005T100000", "RRULE:FREQ=DAILY;COUNT=3"]);
const skipped = C.withExdate(series, at(2026, 9, 6, 9, 30));
assert.deepStrictEqual(skipped.exdates, [at(2026, 9, 6, 9, 30)]);
assert.deepStrictEqual(C.withExdate(skipped, at(2026, 9, 6, 9, 30)).exdates, [at(2026, 9, 6, 9, 30)]);
assert.deepStrictEqual(series.exdates, []);
assert.deepStrictEqual(starts(C.expand([skipped], at(2026, 9, 1), at(2026, 10, 1))), [at(2026, 9, 5, 9, 30), at(2026, 9, 7, 9, 30)]);

const ids = new Set();
for (let i = 0; i < 1000; i++) ids.add(C.newUid());
assert.strictEqual(ids.size, 1000);
assert.ok([...ids].every((u) => /^isra-[a-z0-9]+-[a-z0-9]+@isra$/.test(u)));

const linkOf = (...lines) => one(["DTSTART:20261005T093000Z", ...lines]);
assert.strictEqual(linkOf("DESCRIPTION:Dial https://example.com/c!?").link, "https://example.com/c");
assert.strictEqual(linkOf("DESCRIPTION:Notes https://example.com/a.").link, "https://example.com/a");
assert.strictEqual(linkOf("DESCRIPTION:Try <https://example.com/d>, ok").link, "https://example.com/d");
assert.strictEqual(linkOf('DESCRIPTION:Quote "https://example.com/e" end').link, "https://example.com/e");
const urlProp = linkOf("URL:https://meet.example.com/x", "DESCRIPTION:https://zoom.us/j/1", "LOCATION:https://room.example.com/r");
assert.strictEqual(urlProp.url, "https://meet.example.com/x");
assert.strictEqual(urlProp.link, "https://meet.example.com/x");
const locWins = linkOf("LOCATION:Room https://room.example.com/r", "DESCRIPTION:https://zoom.us/j/2");
assert.strictEqual(locWins.url, "");
assert.strictEqual(locWins.link, "https://room.example.com/r");
const alarmUrl = linkOf("URL:https://real.example.com", "BEGIN:VALARM", "TRIGGER:-PT5M", "URL:https://alarm.example.com", "END:VALARM");
assert.strictEqual(alarmUrl.url, "https://real.example.com");
assert.strictEqual(alarmUrl.reminder, 5);
const alarmOnly = linkOf("BEGIN:VALARM", "TRIGGER:-PT5M", "URL:https://alarm.example.com", "END:VALARM");
assert.strictEqual(alarmOnly.url, "");
assert.strictEqual(alarmOnly.link, "");
assert.strictEqual(linkOf("URL;VALUE=URI:https://meet.example.com/v").url, "https://meet.example.com/v");
const linked = C.expand([linkOf("URL:https://meet.example.com/r", "DTEND:20261005T100000Z", "RRULE:FREQ=DAILY;COUNT=2")], at(2026, 9, 1), at(2026, 10, 1));
assert.strictEqual(linked.length, 2);
linked.forEach((o) => {
    assert.strictEqual(o.url, "https://meet.example.com/r");
    assert.strictEqual(o.link, "https://meet.example.com/r");
});

console.log("ok");

const urg = C.parseIcs(C.serializeEvent(mk({title: "U", reminder: 5, urgent: true})))[0];
assert.strictEqual(urg.urgent, true);
assert.strictEqual(C.parseIcs(C.serializeEvent(mk({title: "N", reminder: 5})))[0].urgent, false);

const hsrc = fs.readFileSync(path.join(__dirname, "holidays.js"), "utf8").replace(/^\.pragma library[^\n]*\n/, "");
const H = new Function(hsrc + "; return {between, regionFor};")();
const hol = (region, y) => H.between(region, at(y, 0, 1), at(y + 1, 0, 1)).reduce((o, e) => (o[e.title] = new Date(e.start).toDateString(), o), {});
assert.strictEqual(hol("US", 2026)["Thanksgiving"], new Date(2026, 10, 26).toDateString());
assert.strictEqual(hol("US", 2026)["Memorial Day"], new Date(2026, 4, 25).toDateString());
assert.strictEqual(hol("GB", 2026)["Good Friday"], new Date(2026, 3, 3).toDateString());
assert.strictEqual(hol("GB", 2026)["Easter Monday"], new Date(2026, 3, 6).toDateString());
assert.strictEqual(hol("DE", 2026)["Whit Monday"], new Date(2026, 4, 25).toDateString());
assert.strictEqual(hol("CA", 2026)["Victoria Day"], new Date(2026, 4, 18).toDateString());
assert.strictEqual(hol("CA", 2025)["Victoria Day"], new Date(2025, 4, 19).toDateString());
assert.strictEqual(hol("CA", 2024)["Victoria Day"], new Date(2024, 4, 20).toDateString());
assert.strictEqual(H.between("US", at(2026, 6, 4), at(2026, 6, 5)).length, 1);
assert.strictEqual(H.between("US", at(2026, 6, 5), at(2026, 6, 6)).length, 0);
assert.strictEqual(H.between("XX", 0, 1e13).length, 0);
assert.strictEqual(H.regionFor("en_US"), "US");
assert.strictEqual(H.regionFor("ja_JP"), "");
