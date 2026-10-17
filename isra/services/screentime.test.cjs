const assert = require("assert");
const fs = require("fs");
const path = require("path");

const src = fs.readFileSync(path.join(__dirname, "screentime.js"), "utf8").replace(/^\.pragma library[^\n]*\n/, "");
const S = new Function(src + "; return {dayKey, monthKey, dayStart, addDays, split, emptyDay, emptyMonth, addUsage, addMedia, addSession, addNotification, addUnlock, noteRun, sanitizeDay, mergeDay, parseMonth, serializeMonth, asciiJson, pruneable, categoryFor, summarize, perDay, average, hm, UNATTRIBUTED, MAX_APPS, MAX_TITLES, GAP_CAP};")();

const at = (y, m, d, h = 0, mi = 0, s = 0) => new Date(y, m, d, h, mi, s).getTime();

assert.strictEqual(S.dayKey(at(2026, 9, 16, 23, 59)), "2026-10-16");
assert.strictEqual(S.monthKey(at(2026, 0, 1)), "2026-01");
assert.strictEqual(S.addDays("2026-10-31", 1), "2026-11-01");
assert.strictEqual(S.addDays("2026-03-01", -1), "2026-02-28");
assert.strictEqual(S.dayKey(S.dayStart("2026-10-16")), "2026-10-16");

const one = S.split(at(2026, 9, 16, 10, 0, 0), at(2026, 9, 16, 10, 0, 30));
assert.strictEqual(one.length, 1);
assert.strictEqual(one[0].secs, 30);
assert.strictEqual(one[0].hour, 10);

const cross = S.split(at(2026, 9, 16, 10, 59, 50), at(2026, 9, 16, 11, 0, 20));
assert.deepStrictEqual(cross.map((x) => [x.hour, x.secs]), [[10, 10], [11, 20]]);

const midnight = S.split(at(2026, 9, 16, 23, 59, 50), at(2026, 9, 17, 0, 0, 10));
assert.deepStrictEqual(midnight.map((x) => [x.day, x.hour, x.secs]), [["2026-10-16", 23, 10], ["2026-10-17", 0, 10]]);

assert.deepStrictEqual(S.split(at(2026, 9, 16, 10, 0, 0), at(2026, 9, 16, 10, 10, 0)), []);
assert.deepStrictEqual(S.split(at(2026, 9, 16, 10, 0, 5), at(2026, 9, 16, 10, 0, 5)), []);
assert.deepStrictEqual(S.split(at(2026, 9, 16, 10, 0, 5), at(2026, 9, 16, 10, 0, 1)), []);
assert.strictEqual(S.split(at(2026, 9, 16, 10, 0, 0), at(2026, 9, 16, 10, 0, S.GAP_CAP)).length, 1);

const day = S.emptyDay();
const seg = { day: "2026-10-16", hour: 9, secs: 30, at: at(2026, 9, 16, 9, 0, 0) };
S.addUsage(day, seg, "firefox", {});
S.addUsage(day, seg, "firefox", { fullscreen: true, workspace: 2, title: "Tab" });
assert.strictEqual(day.total, 60);
assert.strictEqual(day.apps.firefox.s, 60);
assert.strictEqual(day.apps.firefox.h[9], 60);
assert.strictEqual(day.apps.firefox.fs, 30);
assert.strictEqual(day.apps.firefox.ws["2"], 30);
assert.strictEqual(day.titles.firefox.Tab, 30);
assert.strictEqual(day.first, seg.at);
assert.strictEqual(day.last, seg.at + 30000);

S.addUsage(day, seg, "kitty", { hourly: false });
assert.strictEqual(day.apps.kitty.s, 30);
assert.strictEqual(day.apps.kitty.h[9], 0);

S.addUsage(day, seg, "", {});
assert.strictEqual(day.apps[S.UNATTRIBUTED].s, 30);

const big = S.emptyDay();
for (let i = 0; i < S.MAX_APPS + 20; i++)
    S.addUsage(big, seg, "app" + i, {});
assert.strictEqual(Object.keys(big.apps).length, S.MAX_APPS + 1);
assert.ok(big.apps[S.UNATTRIBUTED].s >= 20 * 30);
assert.strictEqual(big.total, (S.MAX_APPS + 20) * 30);

const titles = S.emptyDay();
for (let i = 0; i < S.MAX_TITLES + 10; i++)
    S.addUsage(titles, seg, "code", { title: "t" + i });
assert.strictEqual(Object.keys(titles.titles.code).length, S.MAX_TITLES);
S.addUsage(titles, seg, "code", { title: "x".repeat(500) });
assert.ok(Object.keys(titles.titles.code).every((k) => k.length <= 120));

S.addSession(day, "firefox");
S.addSession(day, "firefox");
S.addNotification(day, "firefox");
S.addUnlock(day);
S.noteRun(day, 90);
S.noteRun(day, 40);
S.addMedia(day, "mpv", 12);
assert.strictEqual(day.apps.firefox.ss, 2);
assert.strictEqual(day.apps.firefox.nt, 1);
assert.strictEqual(day.unlocks, 1);
assert.strictEqual(day.longest, 90);
assert.strictEqual(day.media.mpv, 12);

const garbage = S.sanitizeDay({ total: "x", longest: -4, unlocks: 2.7, apps: { a: { s: NaN, h: [1, "x", null], ss: -1, nt: 3, ws: { 1: 5, 2: "no" } }, b: 7, c: null }, titles: { a: { q: 1, r: Infinity } }, media: [1, 2] });
assert.strictEqual(garbage.total, 0);
assert.strictEqual(garbage.longest, 0);
assert.strictEqual(garbage.unlocks, 2);
assert.strictEqual(garbage.apps.a.s, 0);
assert.strictEqual(garbage.apps.a.h.length, 24);
assert.strictEqual(garbage.apps.a.h[0], 1);
assert.strictEqual(garbage.apps.a.h[1], 0);
assert.strictEqual(garbage.apps.a.ss, 0);
assert.strictEqual(garbage.apps.a.nt, 3);
assert.deepStrictEqual(garbage.apps.a.ws, { 1: 5, 2: 0 });
assert.strictEqual(garbage.apps.b.s, 0);
assert.strictEqual(garbage.apps.c.s, 0);
assert.strictEqual(garbage.titles.a.r, 0);
assert.ok(S.sanitizeDay(null).apps && S.sanitizeDay(undefined).media);

const a = S.emptyDay();
const b = S.emptyDay();
S.addUsage(a, seg, "firefox", {});
S.addUsage(b, seg, "firefox", {});
S.addUsage(b, seg, "kitty", {});
S.addSession(b, "firefox");
S.addUnlock(b);
S.noteRun(b, 50);
S.mergeDay(a, b);
assert.strictEqual(a.total, 90);
assert.strictEqual(a.apps.firefox.s, 60);
assert.strictEqual(a.apps.firefox.ss, 1);
assert.strictEqual(a.apps.kitty.s, 30);
assert.strictEqual(a.unlocks, 1);
assert.strictEqual(a.longest, 50);

const month = S.emptyMonth();
month.days["2026-10-16"] = day;
const text = S.serializeMonth(month);
const back = S.parseMonth(text);
assert.strictEqual(back.days["2026-10-16"].apps.firefox.s, 60);
assert.strictEqual(back.days["2026-10-16"].media.mpv, 12);

const uni = S.emptyMonth();
uni.days["2026-10-16"] = S.emptyDay();
S.addUsage(uni.days["2026-10-16"], seg, "日本語アプリ", { title: "café ☕" });
const uniText = S.serializeMonth(uni);
assert.ok(/^[\x00-\x7f]*$/.test(uniText));
assert.strictEqual(Buffer.byteLength(uniText), uniText.length);
assert.ok(S.parseMonth(uniText).days["2026-10-16"].apps["日本語アプリ"]);

assert.strictEqual(S.parseMonth(""), null);
assert.strictEqual(S.parseMonth(null), null);
assert.strictEqual(S.parseMonth("{not json"), null);
assert.strictEqual(S.parseMonth("[]"), null);
assert.strictEqual(S.parseMonth('{"days":5}'), null);
assert.deepStrictEqual(Object.keys(S.parseMonth('{"days":{"bad":{},"2026-10-01":{}}}').days), ["2026-10-01"]);

const now = at(2026, 9, 16);
assert.deepStrictEqual(S.pruneable(["2026-05", "2026-06", "2026-07", "2026-08", "2026-10"], now, 90), ["2026-05", "2026-06"]);
assert.deepStrictEqual(S.pruneable(["2020-01"], now, 0), []);
assert.deepStrictEqual(S.pruneable(["junk", "2026-13"], now, 90).includes("junk"), false);

assert.strictEqual(S.categoryFor(["Utility", "TextEditor", "Development", "IDE"], "", "code"), "work");
assert.strictEqual(S.categoryFor(["Network", "WebBrowser"], "", "firefox"), "web");
assert.strictEqual(S.categoryFor(["Network", "InstantMessaging"], "", "discord"), "fun");
assert.strictEqual(S.categoryFor(["Network", "FileTransfer", "Game"], "", "steam"), "fun");
assert.strictEqual(S.categoryFor(["System", "FileManager"], "", "dolphin"), "other");
assert.strictEqual(S.categoryFor(["WebBrowser"], "work", "firefox"), "work");
assert.strictEqual(S.categoryFor(["WebBrowser"], "bogus", "firefox"), "web");
assert.strictEqual(S.categoryFor(undefined, "", "x"), "other");
assert.strictEqual(S.categoryFor(["Game"], "", S.UNATTRIBUTED), "other");

const cat = { firefox: "web", kitty: "work", steam: "fun" };
const d1 = S.emptyDay();
const d2 = S.emptyDay();
S.addUsage(d1, { day: "2026-10-15", hour: 10, secs: 600, at: at(2026, 9, 15, 10) }, "firefox", {});
S.addUsage(d1, { day: "2026-10-15", hour: 11, secs: 300, at: at(2026, 9, 15, 11) }, "kitty", {});
S.addUsage(d2, { day: "2026-10-16", hour: 20, secs: 900, at: at(2026, 9, 16, 20) }, "steam", {});
S.addUsage(d2, { day: "2026-10-16", hour: 9, secs: 60, at: at(2026, 9, 16, 9) }, "keepassxc", {});
S.addUnlock(d2);
S.addNotification(d1, "firefox");
S.noteRun(d1, 500);
S.addSession(d1, "firefox");
const entries = [{ key: "2026-10-15", day: d1 }, { key: "2026-10-16", day: d2 }];
const sum = S.summarize(entries, { categoryOf: (id) => cat[id] || "other", excluded: ["keepassxc"] });
assert.strictEqual(sum.total, 1800);
assert.strictEqual(sum.apps.length, 3);
assert.strictEqual(sum.apps[0].id, "steam");
assert.ok(Math.abs(sum.apps[0].share - 0.5) < 1e-9);
assert.strictEqual(sum.categories.web, 600);
assert.strictEqual(sum.categories.work, 300);
assert.strictEqual(sum.categories.fun, 900);
assert.strictEqual(sum.categories.other, 0);
assert.strictEqual(sum.hourly.fun[20], 900);
assert.strictEqual(sum.hourly.web[10], 600);
assert.strictEqual(sum.unlocks, 1);
assert.strictEqual(sum.notifications, 1);
assert.strictEqual(sum.sessions, 1);
assert.strictEqual(sum.longest, 500);
assert.strictEqual(sum.activeDays, 2);
assert.strictEqual(sum.hourlyCoverage, 1);
assert.ok(sum.hasData);
assert.ok(!sum.apps.some((x) => x.id === "keepassxc"));

const unhourly = S.emptyDay();
S.addUsage(unhourly, seg, "firefox", { hourly: false });
const usum = S.summarize([{ key: "k", day: unhourly }], { categoryOf: () => "web" });
assert.strictEqual(usum.total, 30);
assert.strictEqual(usum.hourlyCoverage, 0);

const empty = S.summarize([], {});
assert.strictEqual(empty.hasData, false);
assert.strictEqual(empty.total, 0);
assert.deepStrictEqual(empty.apps, []);
assert.strictEqual(empty.hourly.work.length, 24);
assert.strictEqual(S.summarize([{ key: "k", day: null }], {}).hasData, false);
assert.strictEqual(S.summarize([{ key: "k", day: S.emptyDay() }], undefined).hasData, false);

const pd = S.perDay(entries, { excluded: ["keepassxc"] });
assert.deepStrictEqual(pd, [{ key: "2026-10-15", total: 900 }, { key: "2026-10-16", total: 900 }]);
assert.strictEqual(S.average(pd, "2026-10-16"), 900);
assert.strictEqual(S.average([], "x"), 0);
assert.strictEqual(S.average([{ key: "a", total: 0 }], "x"), 0);

assert.deepStrictEqual(S.hm(3725), { h: 1, m: 2 });
assert.deepStrictEqual(S.hm(-5), { h: 0, m: 0 });
assert.deepStrictEqual(S.hm(NaN), { h: 0, m: 0 });
assert.deepStrictEqual(S.hm(59), { h: 0, m: 1 });

assert.strictEqual(S.asciiJson({ a: "é" }), '{"a":"\\u00e9"}');
assert.strictEqual(S.asciiJson([1, "x"]), '[1,"x"]');
