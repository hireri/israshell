const assert = require("assert");
const fs = require("fs");
const path = require("path");

const strip = (s) => s.replace(/^\.pragma library[^\n]*\n/, "").replace(/^\.import[^\n]*\n/m, "");
const P = new Function(strip(fs.readFileSync(path.join(__dirname, "platform.js"), "utf8")) + ";return {PKG,INIT,detectScript,parseDetect,checks,command,supports,withPriv};")();
const H = new Function("P", strip(fs.readFileSync(path.join(__dirname, "healthChecks.js"), "utf8")) + ";return {CHECKS,checksFor,byId,run};")(P);

const SEVERITIES = ["ok", "info", "warn", "bad", "unavailable", "permission"];
const GROUPS = ["packages", "storage", "hardware", "services", "system"];
const STATIC_IDS = ["updates.flatpak", "storage.mounts", "storage.inodes", "storage.smart", "storage.trash", "storage.logs", "hw.temps", "hw.battery", "sys.reboot", "sys.timesync", "sys.memory"];

const lines = (...l) => l.join("\n");
const PL = {pkg: "pacman", init: "runit", aur: "yay", priv: "sudo", svdir: "/run/runit/service", os: "artix"};
const get = (id) => H.byId(id, H.checksFor(PL));
const parse = (id, out, code = 0, ctx) => H.run(get(id), out, code, ctx);

const PKGS = [""].concat(Object.keys(P.PKG));
const INITS = [""].concat(Object.keys(P.INIT));
const COMBOS = [{}];
PKGS.forEach((pkg) => INITS.forEach((init) => COMBOS.push({pkg, init, aur: pkg === "pacman" ? "yay" : "", priv: "sudo", svdir: "/run/runit/service", os: "artix"})));

function clean(v, where) {
    if (v === undefined) assert.fail(where + " is undefined");
    if (typeof v === "number") assert.ok(Number.isFinite(v), where + " is not finite: " + v);
    if (v && typeof v === "object") Object.keys(v).forEach((k) => clean(v[k], where + "." + k));
}

assert.deepStrictEqual(H.CHECKS.map((c) => c.id), STATIC_IDS);
assert.deepStrictEqual(H.checksFor({}).map((c) => c.id), STATIC_IDS);
assert.deepStrictEqual(H.checksFor(PL).map((c) => c.id), ["updates.repo", "updates.aur", "updates.flatpak", "pkg.orphans", "pkg.pacnew", "pkg.cache", "pkg.deps", "pkg.news", "storage.mounts", "storage.inodes", "storage.smart", "storage.trash", "storage.logs", "hw.temps", "hw.battery", "svc.list", "sys.reboot", "sys.timesync", "sys.memory"]);
assert.strictEqual(H.byId("nope", H.checksFor(PL)), null);

COMBOS.forEach((plat) => {
    const list = H.checksFor(plat);
    list.forEach((c) => {
        assert.ok(GROUPS.includes(c.group), c.id);
        assert.ok(Number.isInteger(c.timeout) && c.timeout > 0, c.id);
        assert.ok(typeof c.when === "string" && c.when.length > 0, c.id);
        assert.ok(typeof c.cmd === "string" && c.cmd.length > 0, c.id);
        assert.strictEqual(typeof c.parse, "function", c.id);
        assert.strictEqual(H.byId(c.id, list), c);
        for (const out of ["", "%%% junk\n\t"]) {
            const r = H.run(c, out, 0, {});
            assert.ok(SEVERITIES.includes(r.severity), c.id);
            clean(r, c.id);
        }
        assert.deepStrictEqual(H.run(c, "x", 127, {}), {severity: "unavailable", reason: "missing"}, c.id);
        assert.deepStrictEqual(H.run(c, "", 127, {}), {severity: "unavailable", reason: "missing"}, c.id);
        assert.deepStrictEqual(H.run(c, "", 124, {}), {severity: "unavailable", reason: "timeout"}, c.id);
        assert.deepStrictEqual(H.run(c, "x", 124, {}), {severity: "unavailable", reason: "timeout"}, c.id);
    });
});

assert.deepStrictEqual(H.run({parse() { throw new Error("boom"); }}, "", 0, {}), {severity: "unavailable", reason: "parse"});
assert.deepStrictEqual(H.run({parse() { return {severity: "nope"}; }}, "", 0, {}), {severity: "unavailable", reason: "parse"});

const REPO = lines("linux 7.2.9-1 -> 7.2.10-1", "linux-headers 7.2.9-1 -> 7.2.10-1");
assert.deepStrictEqual(parse("updates.repo", "", 2), {severity: "ok", count: 0, items: []});
assert.deepStrictEqual(parse("updates.repo", REPO, 0).items[0], {name: "linux", from: "7.2.9-1", to: "7.2.10-1"});
assert.strictEqual(parse("updates.repo", REPO, 0).severity, "info");
assert.strictEqual(parse("updates.repo", REPO, 0).count, 2);
assert.strictEqual(parse("updates.repo", "", 1).reason, "failed");

const YAY = lines(
    "lmms-git 1.3.0.alpha.1.r999.ge215cd0c3-1 -> 1.3.0.alpha.1.r1024.g067c3ad41-1 [65d22h]",
    "lmstudio-bin 0.4.25-1 -> 0.4.26-4 [3d4h]",
    "vercel 64.3.1-1 -> 64.4.0-1 [51m]"
);
assert.strictEqual(parse("updates.aur", YAY, 0).count, 3);
assert.deepStrictEqual(parse("updates.aur", YAY, 0).items[2], {name: "vercel", from: "64.3.1-1", to: "64.4.0-1"});
assert.deepStrictEqual(parse("updates.aur", "", 1), {severity: "ok", count: 0, items: []});
assert.strictEqual(parse("updates.aur", "", 2).reason, "failed");

const FLAT = "org.mozilla.firefox\t130.0\norg.gimp.GIMP\t2.10.38\n";
assert.deepStrictEqual(parse("updates.flatpak", FLAT, 0).items[1], {name: "org.gimp.GIMP", from: "", to: "2.10.38"});
assert.strictEqual(parse("updates.flatpak", FLAT, 0).severity, "info");
assert.deepStrictEqual(parse("updates.flatpak", "", 0), {severity: "ok", count: 0, items: []});
assert.strictEqual(parse("updates.flatpak", "", 1).reason, "failed");
const FI = parse("updates.flatpak", "org.gimp.GIMP\t2.10.38\ninstalled:8:13\n", 0);
assert.strictEqual(FI.count, 1);
assert.strictEqual(FI.apps, 8);
assert.strictEqual(FI.runtimes, 13);
assert.deepStrictEqual(parse("updates.flatpak", "installed:8:13\n", 0), {severity: "ok", count: 0, items: [], apps: 8, runtimes: 13});

const ANT = lines(
    "Name            : ant",
    "Version         : 1.10.15-1",
    "Description     : Java based build tool",
    "Architecture    : any",
    "URL             : https://ant.apache.org/",
    "Licenses        : Apache-2.0",
    "Groups          : None",
    "Provides        : apache-ant",
    "Depends On      : java-environment  bash  coreutils  which",
    "Optional Deps   : junit: junit tasks",
    "                  java-hamcrest: junit tasks",
    "Required By     : None",
    "Optional For    : None",
    "Conflicts With  : apache-ant",
    "Replaces        : apache-ant",
    "Installed Size  : 3.16 MiB",
    "Packager        : Dudemanguy <dudemanguy@artixlinux.org>",
    "Build Date      : Sun 08 Sep 2024 09:46:49 PM CEST",
    "Install Date    : Mon 22 Jun 2026 11:48:07 PM CEST",
    "Install Reason  : Installed as a dependency for another package",
    "Install Script  : No",
    "Validated By    : Signature"
);
const CJSON = lines(
    "Name            : cjson",
    "Version         : 1.7.19-1",
    "Description     : Ultralightweight JSON parser in ANSI C",
    "Architecture    : x86_64",
    "URL             : https://github.com/DaveGamble/cJSON",
    "Licenses        : MIT",
    "Groups          : None",
    "Provides        : None",
    "Depends On      : glibc",
    "Optional Deps   : None",
    "Required By     : None",
    "Optional For    : None",
    "Conflicts With  : None",
    "Replaces        : None",
    "Installed Size  : 87.73 KiB",
    "Packager        : nikolar <nikolar@artixlinux.org>",
    "Build Date      : Thu 25 Sep 2025 01:24:14 PM CEST",
    "Install Date    : Fri 24 Jul 2026 02:42:14 AM CEST",
    "Install Reason  : Installed as a dependency for another package",
    "Install Script  : No",
    "Validated By    : Signature"
);
const ORPHANS = [ANT, CJSON].join("\n\n");
const many = (n, size) => Array.from({length: n}, (_, i) => "Name            : p" + i + "\nInstalled Size  : " + size).join("\n\n");
const orph = parse("pkg.orphans", ORPHANS, 0);
assert.deepStrictEqual(orph.items, ["ant", "cjson"]);
assert.strictEqual(orph.count, 2);
assert.strictEqual(orph.bytes, 3313500 + 89836);
assert.strictEqual(orph.severity, "info");
assert.strictEqual(parse("pkg.orphans", many(1, "512.00 KiB")).bytes, 524288);
assert.strictEqual(parse("pkg.orphans", many(1, "1.2 GiB")).bytes, 1288490189);
assert.strictEqual(parse("pkg.orphans", many(20, "1.00 KiB")).severity, "info");
assert.strictEqual(parse("pkg.orphans", many(21, "1.00 KiB")).severity, "warn");
assert.strictEqual(parse("pkg.orphans", many(21, "1.00 KiB")).bytes, 21 * 1024);
assert.deepStrictEqual(parse("pkg.orphans", ""), {severity: "ok", count: 0, bytes: 0, items: []});

const PACNEW = lines(
    "/etc/mkinitcpio.conf.pacnew",
    "/etc/locale.gen.pacnew",
    "/etc/dnscrypt-proxy/dnscrypt-proxy.toml.pacnew",
    "/etc/pacman.d/mirrorlist.pacnew",
    "/etc/tpm2-tss/fapi-profiles/P_ECCP384SHA384.json.pacnew",
    "/etc/tpm2-tss/fapi-profiles/P_RSA3072SHA384.json.pacnew"
);
assert.strictEqual(parse("pkg.pacnew", PACNEW, 1).count, 6);
assert.strictEqual(parse("pkg.pacnew", PACNEW, 0).severity, "warn");
assert.deepStrictEqual(parse("pkg.pacnew", "", 1), {severity: "ok", count: 0, items: []});

assert.deepStrictEqual(parse("pkg.cache", "4112531058\t/var/cache/pacman/pkg\n"), {severity: "ok", bytes: 4112531058});
assert.deepStrictEqual(parse("pkg.cache", "11811160065\t/var/cache/pacman/pkg"), {severity: "info", bytes: 11811160065});
assert.deepStrictEqual(parse("pkg.cache", "", 1), {severity: "ok", bytes: 0});

assert.deepStrictEqual(parse("pkg.deps", "No database errors have been found!\n", 0), {severity: "ok", issues: []});
assert.deepStrictEqual(parse("pkg.deps", "error: libfoo: dependency libbar is missing\n", 0), {severity: "bad", issues: ["error: libfoo: dependency libbar is missing"]});
assert.strictEqual(parse("pkg.deps", "", 1).reason, "failed");

const item = (title, link, date) => "<item><title>" + title + "</title><link>" + link + "</link><description>&lt;p&gt;</description><pubDate>" + date + "</pubDate><guid isPermaLink=\"false\">" + link + "</guid></item>";
const D1 = "Tue, 22 Sep 2026 09:09:27 +0000";
const D2 = "Tue, 21 Jul 2026 13:01:46 +0000";
const D3 = "Fri, 12 Jun 2026 18:41:28 +0000";
const NEWS = lines(
    "<?xml version=\"1.0\" encoding=\"utf-8\"?>",
    "<rss version=\"2.0\"><channel><title>Arch Linux: Recent news updates</title><link>https://archlinux.org/news/</link>",
    item("Mkinitcpio &gt;=42 requires manual intervention for TPM2-based unlocking of LUKS devices", "https://archlinux.org/news/mkinitcpio-42-requires-manual-intervention-for-tpm2-based-unlocking-of-luks-devices/", D1),
    item("virtualbox-ext-vnc &gt;= 7.2.12-2 requires manual intervention", "https://archlinux.org/news/virtualbox-ext-vnc-7212-2-requires-manual-intervention/", D2),
    item("Active AUR malicious packages incident", "https://archlinux.org/news/active-aur-malicious-packages-incident/", D3),
    "</channel></rss>"
);
const news = parse("pkg.news", NEWS, 0);
assert.strictEqual(news.items.length, 3);
assert.strictEqual(news.items[0].title, "Mkinitcpio >=42 requires manual intervention for TPM2-based unlocking of LUKS devices");
assert.strictEqual(news.items[0].link, "https://archlinux.org/news/mkinitcpio-42-requires-manual-intervention-for-tpm2-based-unlocking-of-luks-devices/");
assert.strictEqual(news.items[0].date, Date.parse(D1));
assert.strictEqual(news.unread, 3);
assert.strictEqual(news.severity, "bad");
assert.strictEqual(parse("pkg.news", NEWS, 0, {seen: Date.parse(D1)}).severity, "ok");
assert.strictEqual(parse("pkg.news", NEWS, 0, {seen: Date.parse(D1)}).unread, 0);
assert.strictEqual(parse("pkg.news", NEWS, 0, {seen: Date.parse(D2)}).unread, 1);
assert.strictEqual(parse("pkg.news", NEWS, 0, {seen: Date.parse(D2)}).severity, "bad");
assert.strictEqual(parse("pkg.news", NEWS, 0, {}).unread, 3);
assert.strictEqual(parse("pkg.news", NEWS, 0, {seen: undefined}).unread, 3);
assert.strictEqual(parse("pkg.news", NEWS, 6).reason, "offline");
assert.deepStrictEqual(parse("pkg.news", "", 0), {severity: "ok", unread: 0, items: []});
assert.strictEqual(news.items[0].kind, "manual");
assert.strictEqual(news.items[2].kind, "security");
assert.strictEqual(news.items[0].summary, "");
const read = parse("pkg.news", NEWS, 0, {seen: 0, read: [news.items[0].link]});
assert.strictEqual(read.items[0].unread, false);
assert.strictEqual(read.unread, 2);
assert.strictEqual(read.severity, "bad");
const read2 = parse("pkg.news", NEWS, 0, {seen: 0, read: [news.items[0].link, news.items[1].link]});
assert.strictEqual(read2.severity, "info");
const BODY = "<rss><channel><item><title>Foo</title><link>https://x/b</link><description>&lt;p&gt;Hello   &lt;code&gt;world&lt;/code&gt; " + "word ".repeat(60) + "&lt;/p&gt;</description><pubDate>" + D3 + "</pubDate></item></channel></rss>";
const body = parse("pkg.news", BODY, 0, {seen: 0}).items[0];
assert.ok(body.summary.startsWith("Hello world word"));
assert.ok(body.summary.endsWith("…") && body.summary.length <= 162);
assert.strictEqual(body.kind, "other");

const ONLY_INFO = lines(
    "<rss><channel>",
    item("Active AUR malicious packages incident", "https://archlinux.org/news/active-aur-malicious-packages-incident/", D3),
    "</channel></rss>"
);
assert.deepStrictEqual(parse("pkg.news", ONLY_INFO, 0, {seen: 0}).severity, "info");
assert.strictEqual(parse("pkg.news", ONLY_INFO, 0, {seen: Date.parse(D3)}).severity, "ok");
const TRICKY = lines(
    "<rss><channel>",
    "<item><title><![CDATA[Foo &amp; bar]]></title><link>https://x/1</link><pubDate>" + D3 + "</pubDate></item>",
    "<item><title>Tom &amp;#39;s &#39;quoted&#39; &lt;x&gt;</title><link>https://x/2</link><pubDate>" + D3 + "</pubDate></item>",
    "</channel></rss>"
);
const tricky = parse("pkg.news", TRICKY, 0);
assert.strictEqual(tricky.items[0].title, "Foo &amp; bar");
assert.strictEqual(tricky.items[1].title, "Tom &#39;s 'quoted' <x>");

const DF = lines(
    "Filesystem     Type     1-blocks         Used    Available Capacity Mounted on",
    "/dev/nvme0n1p2 ext4 983148589056 739712114688 198624370688      79% /",
    "/dev/nvme0n1p1 vfat    206453248     26535424    179917824      13% /boot/efi",
    "/dev/sda2      ext4 471210188800  86867296256 360331501568      20% /mnt/data"
);
const df = parse("storage.mounts", DF, 0);
assert.strictEqual(df.severity, "ok");
assert.strictEqual(df.mounts.length, 3);
assert.deepStrictEqual(df.mounts[0], {source: "/dev/nvme0n1p2", fstype: "ext4", mount: "/", total: 983148589056, used: 739712114688, avail: 198624370688, pct: 79});
assert.strictEqual(parse("storage.mounts", lines("Filesystem Type 1-blocks Used Available Capacity Mounted on", "/dev/sdb1 ext4 1000 900 100 90% /mnt/My Disk")).severity, "warn");
assert.strictEqual(parse("storage.mounts", lines("/dev/sdb1 ext4 1000 900 100 90% /mnt/My Disk")).mounts[0].mount, "/mnt/My Disk");
assert.strictEqual(parse("storage.mounts", "/dev/sdb1 ext4 1000 990 10 99% /x").severity, "bad");
assert.deepStrictEqual(parse("storage.mounts", ""), {severity: "ok", mounts: []});

const DFI = lines(
    "Filesystem       Inodes   IUsed    IFree IUse% Mounted on",
    "/dev/nvme0n1p2 61038592 4747956 56290636    8% /",
    "/dev/nvme0n1p1        0       0        0     - /boot/efi",
    "/dev/sda2      29294592  271420 29023172    1% /mnt/data"
);
assert.deepStrictEqual(parse("storage.inodes", DFI, 0), {
    severity: "ok",
    mounts: [{mount: "/", pct: 8}, {mount: "/boot/efi", pct: null}, {mount: "/mnt/data", pct: 1}]
});
assert.strictEqual(parse("storage.inodes", "/x 10 9 1 95% /full").severity, "bad");
assert.strictEqual(parse("storage.inodes", "/boot/efi 0 0 0 - /boot/efi").severity, "ok");

const SMART_PERM_REAL = lines(
    "DEV:sda",
    "smartctl 7.5 2025-04-30 r5714 [x86_64-linux-7.2.9-artix1-1] (local build)",
    "Copyright (C) 2002-25, Bruce Allen, Christian Franke, www.smartmontools.org",
    "",
    "Smartctl open device: /dev/sda failed: Permission denied"
);
assert.deepStrictEqual(parse("storage.smart", SMART_PERM_REAL, 2), {severity: "permission", device: "sda"});
assert.deepStrictEqual(parse("storage.smart", "DEV:sda\n", 0), {severity: "permission", device: "sda"});
assert.deepStrictEqual(parse("storage.smart", "", 3), {severity: "unavailable", reason: "failed"});

const NVME = lines(
    "DEV:nvme0n1",
    "smartctl 7.5 2025-04-30 r5714 [x86_64-linux-7.2.9-artix1-1] (local build)",
    "=== START OF SMART DATA SECTION ===",
    "SMART overall-health self-assessment test result: PASSED",
    "",
    "SMART/Health Information (NVMe Log 0x02)",
    "Critical Warning:                   0x00",
    "Temperature:                        41 Celsius",
    "Available Spare:                    100%",
    "Percentage Used:                    12%",
    "Power On Hours:                     1,234"
);
assert.deepStrictEqual(parse("storage.smart", NVME, 0), {severity: "ok", device: "nvme0n1", passed: true, percentUsed: 12, tempC: 41, powerOnHours: 1234});
assert.strictEqual(parse("storage.smart", NVME.replace("Percentage Used:                    12%", "Percentage Used:                    85%"), 0).severity, "warn");
assert.strictEqual(parse("storage.smart", NVME.replace("result: PASSED", "result: FAILED!"), 0).severity, "bad");
assert.strictEqual(parse("storage.smart", NVME.replace("result: PASSED", "result: FAILED!"), 0).passed, false);

const SATA = lines(
    "DEV:sda",
    "=== START OF READ SMART DATA SECTION ===",
    "SMART Health Status: OK",
    "",
    "ID# ATTRIBUTE_NAME          FLAGS    VALUE WORST THRESH TYPE      UPDATED  WHEN_FAILED RAW_VALUE",
    "  5 Reallocated_Sector_Ct   0x0033   100   100   010    Pre-fail  Always       -       0",
    "  9 Power_On_Hours          0x0032   088   088   000    Old_age   Always       -       8457",
    "194 Temperature_Celsius     0x0022   035   050   000    Old_age   Always       -       35 (0 18 0 0 0)"
);
assert.deepStrictEqual(parse("storage.smart", SATA, 0), {severity: "ok", device: "sda", passed: true, percentUsed: null, tempC: 35, powerOnHours: 8457});
assert.strictEqual(parse("storage.smart", SATA.replace("SMART Health Status: OK", "SMART Health Status: FAILING"), 0).severity, "bad");

const TRASH_REAL = "16688\t/home/aveline/.local/share/Trash\n";
assert.deepStrictEqual(parse("storage.trash", TRASH_REAL, 0), {severity: "ok", bytes: 16688});
assert.deepStrictEqual(parse("storage.trash", "", 1), {severity: "ok", bytes: 0});
assert.deepStrictEqual(parse("storage.logs", "9889868\t/var/log\n", 1), {severity: "ok", bytes: 9889868});
assert.deepStrictEqual(parse("storage.logs", "", 0), {severity: "ok", bytes: 0});

const HWMON = lines(
    "acpitz\t\t16800",
    "nvme\tComposite\t34850",
    "nvme\tSensor 1\t33850",
    "amdgpu\tedge\t51000",
    "amdgpu\tjunction\t56000",
    "amdgpu\tmem\t66000",
    "amdgpu\tedge\t30000",
    "k10temp\tTctl\t34500",
    "k10temp\tTccd1\t28875",
    "gigabyte_wmi\t\t22000",
    "gigabyte_wmi\t\t43000",
    "gigabyte_wmi\t\t34000",
    "gigabyte_wmi\t\t33000",
    "gigabyte_wmi\t\t36000",
    "gigabyte_wmi\t\t37000"
) + "\n";
const temps = parse("hw.temps", HWMON, 0);
assert.strictEqual(temps.severity, "ok");
assert.strictEqual(temps.sensors.length, 15);
assert.deepStrictEqual(temps.sensors[0], {name: "acpitz", label: "", celsius: 16.8});
assert.deepStrictEqual(temps.sensors[1], {name: "nvme", label: "Composite", celsius: 34.9});
assert.strictEqual(temps.sensors[5].celsius, 66);
assert.strictEqual(parse("hw.temps", "cpu\tPackage\t91000\n", 0).severity, "bad");
assert.strictEqual(parse("hw.temps", "cpu\tPackage\t89940\n", 0).severity, "warn");
assert.strictEqual(parse("hw.temps", "cpu\tPackage\t89999\n", 0).severity, "bad");
assert.strictEqual(parse("hw.temps", "cpu\tPackage\t80000\n", 0).severity, "warn");
assert.strictEqual(parse("hw.temps", "cpu\tPackage\t79900\n", 0).severity, "ok");
assert.deepStrictEqual(parse("hw.temps", "x\t\t0\nx\t\t160000\n", 0), {severity: "ok", sensors: []});
assert.deepStrictEqual(parse("hw.temps", "", 0), {severity: "ok", sensors: []});

const BAT = lines(
    "== /sys/class/power_supply/BAT0",
    "POWER_SUPPLY_NAME=BAT0",
    "POWER_SUPPLY_TYPE=Battery",
    "POWER_SUPPLY_STATUS=Discharging",
    "POWER_SUPPLY_PRESENT=1",
    "POWER_SUPPLY_TECHNOLOGY=Li-ion",
    "POWER_SUPPLY_CYCLE_COUNT=412",
    "POWER_SUPPLY_ENERGY_FULL_DESIGN=57000000",
    "POWER_SUPPLY_ENERGY_FULL=48320000",
    "POWER_SUPPLY_ENERGY_NOW=36240000",
    "POWER_SUPPLY_CAPACITY=75",
    "== /sys/class/power_supply/BAT1",
    "POWER_SUPPLY_NAME=BAT1",
    "POWER_SUPPLY_STATUS=Full",
    "POWER_SUPPLY_CHARGE_FULL_DESIGN=5000000",
    "POWER_SUPPLY_CHARGE_FULL=3000000",
    "POWER_SUPPLY_CAPACITY=100"
);
const bat = parse("hw.battery", BAT, 0);
assert.strictEqual(bat.severity, "ok");
assert.strictEqual(bat.present, true);
assert.deepStrictEqual(bat.batteries[0], {name: "BAT0", percent: 75, status: "Discharging", healthPct: 85, cycles: 412});
assert.deepStrictEqual(bat.batteries[1], {name: "BAT1", percent: 100, status: "Full", healthPct: 60, cycles: null});
assert.strictEqual(parse("hw.battery", BAT.replace("CHARGE_FULL=3000000", "CHARGE_FULL=2500000"), 0).severity, "warn");
assert.deepStrictEqual(parse("hw.battery", "", 0), {severity: "ok", present: false, batteries: []});

const SVC = lines(
    "sshd\trun\t1\t4500",
    "dbus\trun\t0\t",
    "sddm\tdown\t0\t",
    "bad name!\trun\t1\t",
    "dbus\tdown\t1\t",
    "x\tbogus\t1\t",
    "foo\tfailed\t1\t"
);
const svc = parse("svc.list", SVC, 0);
assert.strictEqual(svc.severity, "bad");
assert.deepStrictEqual(svc.services, [
    {name: "sshd", state: "run", pid: null, seconds: 4500, normallyUp: true, scope: "system"},
    {name: "dbus", state: "run", pid: null, seconds: null, normallyUp: false, scope: "system"},
    {name: "sddm", state: "down", pid: null, seconds: null, normallyUp: false, scope: "system"},
    {name: "foo", state: "failed", pid: null, seconds: null, normallyUp: true, scope: "system"}
]);
assert.deepStrictEqual(svc.failed, ["foo"]);
assert.strictEqual(parse("svc.list", "dbus\trun\t1\t\n", 0).severity, "ok");
assert.deepStrictEqual(parse("svc.list", "", 0), {severity: "ok", services: [], failed: []});
assert.deepStrictEqual(parse("svc.list", "", 3), {severity: "unavailable", reason: "failed"});

assert.deepStrictEqual(parse("sys.reboot", "7.2.9-artix1-1\n7.2.10-artix1-1\n", 0), {severity: "warn", needed: true, running: "7.2.9-artix1-1", installed: "7.2.10-artix1-1"});
assert.deepStrictEqual(parse("sys.reboot", "7.2.10-artix1-1\n7.2.10-artix1-1\n", 0), {severity: "ok", needed: false, running: "7.2.10-artix1-1", installed: "7.2.10-artix1-1"});
assert.deepStrictEqual(parse("sys.reboot", "6.19.0-1\n7.2.9-artix1-1\n7.2.10-artix1-1\n", 0), {severity: "warn", needed: true, running: "6.19.0-1", installed: "7.2.10-artix1-1"});
assert.strictEqual(parse("sys.reboot", "6.9.0\n6.10.0\n", 0).installed, "6.10.0");
assert.deepStrictEqual(parse("sys.reboot", "7.2.9-artix1-1\n", 0), {severity: "ok", needed: false, running: "7.2.9-artix1-1", installed: null});
assert.deepStrictEqual(parse("sys.reboot", "", 0), {severity: "ok", needed: false, running: null, installed: null});

const CHRONY = lines(
    "Reference ID    : A29FC87B (time.cloudflare.com)",
    "Stratum         : 4",
    "Ref time (UTC)  : Fri Oct 16 19:53:07 2026",
    "System time     : 0.000255107 seconds slow of NTP time",
    "Last offset     : -0.000025531 seconds",
    "RMS offset      : 0.000804056 seconds",
    "Frequency       : 23.855 ppm slow",
    "Residual freq   : +0.000 ppm",
    "Skew            : 0.235 ppm",
    "Root delay      : 0.034803756 seconds",
    "Root dispersion : 0.001945994 seconds",
    "Update interval : 1035.5 seconds",
    "Leap status     : Normal"
);
const ts = parse("sys.timesync", CHRONY, 0);
assert.strictEqual(ts.severity, "ok");
assert.strictEqual(ts.synced, true);
assert.ok(Math.abs(ts.offsetMs - -0.255107) < 1e-9);
assert.strictEqual(parse("sys.timesync", lines("System time     : 0.600000000 seconds fast of NTP time", "Leap status     : Normal"), 0).severity, "warn");
assert.strictEqual(parse("sys.timesync", lines("System time     : 0.600000000 seconds fast of NTP time", "Leap status     : Normal"), 0).offsetMs, 600);
const unsynced = parse("sys.timesync", lines("System time     : 0.000000000 seconds fast of NTP time", "Leap status     : Not synchronised"), 0);
assert.deepStrictEqual(unsynced, {severity: "warn", synced: false, offsetMs: 0});
assert.strictEqual(parse("sys.timesync", "506 Cannot talk to daemon", 1).reason, "failed");

const MEM = lines(
    "MemTotal:       31971660 kB",
    "MemFree:         1601048 kB",
    "MemAvailable:   18627380 kB",
    "Buffers:         1504148 kB",
    "Cached:         15918076 kB",
    "SwapCached:            0 kB",
    "SwapTotal:      33554428 kB",
    "SwapFree:       33554428 kB"
);
assert.deepStrictEqual(parse("sys.memory", MEM, 0), {
    severity: "ok",
    memTotal: 31971660 * 1024,
    memAvailable: 18627380 * 1024,
    swapTotal: 33554428 * 1024,
    swapFree: 33554428 * 1024
});
assert.strictEqual(parse("sys.memory", lines("MemTotal: 1000 kB", "MemAvailable: 50 kB"), 0).severity, "warn");
assert.strictEqual(parse("sys.memory", lines("MemTotal: 1000 kB", "MemAvailable: 100 kB"), 0).severity, "ok");
assert.deepStrictEqual(parse("sys.memory", "", 0), {severity: "ok", memTotal: 0, memAvailable: 0, swapTotal: 0, swapFree: 0});
