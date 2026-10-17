const assert = require("assert");
const fs = require("fs");
const os = require("os");
const path = require("path");
const {spawnSync} = require("child_process");

const strip = (s) => s.replace(/^\.pragma library[^\n]*\n/, "").replace(/^\.import[^\n]*\n/m, "");
const P = new Function(strip(fs.readFileSync(path.join(__dirname, "platform.js"), "utf8")) + ";return {PKG,INIT,detectScript,parseDetect,checks,command,supports,withPriv};")();
const H = new Function("P", strip(fs.readFileSync(path.join(__dirname, "healthChecks.js"), "utf8")) + ";return {CHECKS,checksFor,byId,run};")(P);

const lines = (...l) => l.join("\n");
const PKGS = Object.keys(P.PKG);
const INITS = Object.keys(P.INIT);
const plat = (pkg, init, extra) => Object.assign({pkg, init, aur: "", priv: "sudo", svdir: "/run/runit/service", os: "test"}, extra || {});
const COMBOS = [{}];
[""].concat(PKGS).forEach((pkg) => [""].concat(INITS).forEach((init) => COMBOS.push(plat(pkg, init, {aur: pkg === "pacman" ? "yay" : ""}))));

const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "platform-test-"));
const fixture = (name, body) => {
    const f = path.join(tmp, name);
    fs.writeFileSync(f, body);
    return "'" + f + "'";
};
const sh = (cmd) => spawnSync("/bin/sh", ["-c", cmd], {encoding: "utf8"});
const shSyntax = (cmd) => {
    const r = spawnSync("/bin/sh", ["-n"], {input: cmd, encoding: "utf8"});
    assert.strictEqual(r.status, 0, "sh -n failed for: " + cmd + "\n" + r.stderr);
};
const pipeline = (p, id, edits) => {
    const c = H.byId(id, H.checksFor(p));
    assert.ok(c, id + " missing for " + JSON.stringify(p));
    let cmd = c.cmd;
    edits.forEach((e) => {
        assert.ok(cmd.includes(e[0]), "producer not found in " + id + ": " + e[0]);
        cmd = cmd.split(e[0]).join(e[1]);
    });
    const r = sh(cmd);
    return {stdout: r.stdout, code: r.status, result: H.run(c, r.stdout, r.status)};
};

{
    assert.deepStrictEqual(P.parseDetect(lines("pkg pacman", "init runit", "aur paru", "priv sudo", "svdir /var/service", "os artix")),
        {pkg: "pacman", init: "runit", aur: "paru", priv: "sudo", svdir: "/var/service", usvdir: "", os: "artix"});
    assert.deepStrictEqual(P.parseDetect(lines("pkg nix", "init bogus", "aur trizen", "priv su", "svdir relative", "os ???")),
        {pkg: "", init: "", aur: "", priv: "sudo", svdir: "", usvdir: "", os: ""});
    assert.strictEqual(P.parseDetect(lines("pkg apt", "aur yay")).aur, "");
    assert.strictEqual(P.parseDetect("init runit").svdir, "/run/runit/service");
    assert.strictEqual(P.parseDetect("init runit\nsvdir /x;rm").svdir, "/run/runit/service");
    assert.strictEqual(P.parseDetect("init runit\nsvdir /x; rm -rf ~").svdir, "/run/runit/service");
    assert.strictEqual(P.parseDetect("svdir /x;rm").svdir, "");
    assert.strictEqual(P.parseDetect('os "opensuse-tumbleweed"').os, "opensuse-tumbleweed");
    assert.deepStrictEqual(P.parseDetect(""), {pkg: "", init: "", aur: "", priv: "sudo", svdir: "", usvdir: "", os: ""});
}

{
    const script = P.detectScript();
    shSyntax(script);
    const r = sh(script);
    r.stdout.split("\n").filter((l) => l.length > 0).forEach((l) => {
        assert.ok(/^(pkg|init|aur|priv|svdir|usvdir|os) \S+$/.test(l), "unexpected detect line: " + l);
    });
    P.parseDetect(r.stdout);
}

{
    const seen = new Set();
    COMBOS.forEach((p) => H.checksFor(p).forEach((c) => {
        seen.add(c.cmd);
        seen.add(c.when);
    }));
    seen.forEach((cmd) => shSyntax(cmd));
    INITS.forEach((init) => shSyntax(P.INIT[init].list ? P.INIT[init].list(plat("", init)) : "true"));
}

{
    const f = fixture("apt-upgradable", lines("Listing...", "bash/stable 5.2.15-2+b2 amd64 [upgradable from: 5.2.15-2+b1]"));
    const p = pipeline(plat("apt", ""), "updates.repo", [["apt list --upgradable 2>/dev/null", "cat " + f]]);
    assert.strictEqual(p.code, 0);
    assert.deepStrictEqual(p.result, {severity: "info", count: 1, items: [{name: "bash", from: "5.2.15-2+b1", to: "5.2.15-2+b2"}]});
}

{
    const f = fixture("apt-autoremove", lines("Reading package lists...", "Remv libfoo1 [1.0-1]", "Remv libbar2 [2.0-3]", "Inst libbaz3 (3.0 Debian:12/stable [amd64])"));
    const p = pipeline(plat("apt", ""), "pkg.orphans", [["apt-get -s autoremove 2>/dev/null", "cat " + f]]);
    assert.deepStrictEqual(p.result, {severity: "info", count: 2, bytes: null, items: ["libfoo1", "libbar2"]});
}

{
    const body = lines(
        "bash.x86_64    5.2.26-3.fc40    updates",
        "kernel-core.x86_64    6.8.5-301.fc40    updates",
        "",
        "Obsoleting Packages",
        "foo.noarch    2.0-1.fc40    updates",
        "    bar-1.0-1.fc40.x86_64"
    );
    const f = fixture("dnf-check-update", body);
    const dnf = (code) => pipeline(plat("dnf", ""), "updates.repo", [["dnf -q check-update 2>/dev/null", "{ cat " + f + "; exit " + code + "; }"]]);
    const p100 = dnf(100);
    assert.strictEqual(p100.code, 100);
    assert.deepStrictEqual(p100.result, {
        severity: "info",
        count: 2,
        items: [
            {name: "bash", from: "", to: "5.2.26-3.fc40"},
            {name: "kernel-core", from: "", to: "6.8.5-301.fc40"}
        ]
    });
    assert.deepStrictEqual(dnf(0).result.items.map((i) => i.name), ["bash", "kernel-core"]);
    assert.deepStrictEqual(dnf(1).result, {severity: "unavailable", reason: "failed"});
}

{
    const f = fixture("zypper-list-updates", lines(
        "S | Repository | Name | Current Version | Available Version | Arch",
        "--+------------+------+-----------------+-------------------+-------",
        "v | repo-oss | bash | 5.2.15-1.1 | 5.2.21-1.1 | x86_64",
        "v | repo-update | kernel-default | 6.4.0-1.1 | 6.4.1-1.1 | x86_64"
    ));
    const p = pipeline(plat("zypper", ""), "updates.repo", [["zypper -q --no-refresh list-updates 2>/dev/null", "cat " + f]]);
    assert.deepStrictEqual(p.result, {
        severity: "info",
        count: 2,
        items: [
            {name: "bash", from: "5.2.15-1.1", to: "5.2.21-1.1"},
            {name: "kernel-default", from: "6.4.0-1.1", to: "6.4.1-1.1"}
        ]
    });
}

{
    const f = fixture("zypper-unneeded", lines(
        "S | Repository | Name | Version | Arch",
        "--+------------+------+---------+-------",
        "i | repo-oss | libfoo | 1.0 | x86_64",
        "i | repo-oss | libbar | 2.1 | x86_64"
    ));
    const p = pipeline(plat("zypper", ""), "pkg.orphans", [["zypper -q --no-refresh packages --unneeded 2>/dev/null", "cat " + f]]);
    assert.deepStrictEqual(p.result, {severity: "info", count: 2, bytes: null, items: ["libfoo", "libbar"]});
}

{
    const f = fixture("xbps-install", lines(
        "bash-5.2.21_1 update x86_64 https://repo-default.voidlinux.org/current 1234 567",
        "python3-setuptools-69.0.3_1 install noarch https://repo-default.voidlinux.org/current 88 44"
    ));
    const p = pipeline(plat("xbps", ""), "updates.repo", [["xbps-install -Mun 2>/dev/null", "{ cat " + f + "; }"]]);
    assert.deepStrictEqual(p.result, {
        severity: "info",
        count: 2,
        items: [
            {name: "bash", from: "", to: "5.2.21_1"},
            {name: "python3-setuptools", from: "", to: "69.0.3_1"}
        ]
    });
}

{
    const f = fixture("xbps-query", lines("bash-5.2.21_1", "python3-setuptools-69.0.3_1"));
    const p = pipeline(plat("xbps", ""), "pkg.orphans", [["xbps-query -O 2>/dev/null", "cat " + f]]);
    assert.deepStrictEqual(p.result, {severity: "info", count: 2, bytes: null, items: ["bash", "python3-setuptools"]});
}

{
    const f = fixture("apk-upgradable", lines(
        "curl-8.5.0-r0 x86_64 {curl} (curl) [upgradable from: curl-8.4.0-r0]",
        "musl-1.2.4_git20230717-r4 x86_64 {musl} (MIT) [upgradable from: musl-1.2.4_git20230717-r3]"
    ));
    const p = pipeline(plat("apk", ""), "updates.repo", [["apk list -u 2>/dev/null", "cat " + f]]);
    assert.deepStrictEqual(p.result, {
        severity: "info",
        count: 2,
        items: [
            {name: "curl", from: "8.4.0-r0", to: "8.5.0-r0"},
            {name: "musl", from: "1.2.4_git20230717-r3", to: "1.2.4_git20230717-r4"}
        ]
    });
}

{
    const f1 = fixture("systemd-unit-files", "sshd.service enabled enabled\nbar.service enabled enabled\ngetty@.service enabled enabled\n");
    const f2 = fixture("systemd-units", lines(
        "sshd.service loaded active running OpenSSH Daemon",
        "foo.service loaded failed failed Foo",
        "bar.service loaded inactive dead Bar",
        "baz.service not-found inactive dead baz.service",
        "getty@tty1.service loaded active running Getty on tty1"
    ) + "\n");
    const edits = [
        ["systemctl list-unit-files --type=service --state=enabled --no-legend --plain 2>/dev/null", "cat " + f1],
        ["systemctl list-units --type=service --all --no-legend --plain 2>/dev/null", "cat " + f2]
    ];
    const p = pipeline(plat("", "systemd"), "svc.list", edits);
    assert.strictEqual(p.code, 0);
    assert.deepStrictEqual(p.result.services, [
        {name: "sshd", state: "run", pid: null, seconds: null, normallyUp: true, scope: "system"},
        {name: "foo", state: "failed", pid: null, seconds: null, normallyUp: false, scope: "system"},
        {name: "bar", state: "down", pid: null, seconds: null, normallyUp: true, scope: "system"},
        {name: "getty@tty1", state: "run", pid: null, seconds: null, normallyUp: true, scope: "system"}
    ]);
    assert.deepStrictEqual(p.result.failed, ["foo"]);
    assert.strictEqual(p.result.severity, "bad");

    const empty = fixture("systemd-units-empty", "");
    const pe = pipeline(plat("", "systemd"), "svc.list", [edits[0], ["systemctl list-units --type=service --all --no-legend --plain 2>/dev/null", "cat " + empty]]);
    assert.strictEqual(pe.code, 3);
    assert.strictEqual(pe.result.severity, "unavailable");
}

{
    const f1 = fixture("rc-update-show", "                sshd | default\n");
    const f2 = fixture("rc-status", " sshd    [  started  ]\n cronie [  crashed  ]\n nfs [  stopped  ]\n");
    const p = pipeline(plat("", "openrc"), "svc.list", [
        ["rc-update show 2>/dev/null", "cat " + f1],
        ["rc-status --servicelist 2>/dev/null", "cat " + f2]
    ]);
    assert.deepStrictEqual(p.result, {
        severity: "bad",
        services: [
            {name: "sshd", state: "run", pid: null, seconds: null, normallyUp: true, scope: "system"},
            {name: "cronie", state: "failed", pid: null, seconds: null, normallyUp: false, scope: "system"}
        ],
        failed: ["cronie"]
    });
}

{
    const fa = fixture("s6-active", "sshd\nsshd-log\ns6rc-oneshot-runner\ncronie\n");
    const fe = fixture("s6-enabled", "sshd\nnfs\ncronie\nsshd-log\n");
    const fs6 = fixture("s6-services", "sshd\nsshd-log\ns6rc-oneshot-runner\nnfs\ncronie\nbluetoothd\n");
    const p = pipeline(plat("", "s6"), "svc.list", [
        ["s6-rc -a list 2>/dev/null", "cat " + fa],
        ["s6-rc-db contents default 2>/dev/null", "cat " + fe],
        ["s6-rc-db list services 2>/dev/null", "cat " + fs6]
    ]);
    assert.deepStrictEqual(p.result.services, [
        {name: "sshd", state: "run", pid: null, seconds: null, normallyUp: true, scope: "system"},
        {name: "nfs", state: "down", pid: null, seconds: null, normallyUp: true, scope: "system"},
        {name: "cronie", state: "run", pid: null, seconds: null, normallyUp: true, scope: "system"}
    ]);
    assert.strictEqual(p.result.severity, "ok");
    const fempty = fixture("s6-services-empty", "");
    const pe = pipeline(plat("", "s6"), "svc.list", [
        ["s6-rc -a list 2>/dev/null", "cat " + fa],
        ["s6-rc-db contents default 2>/dev/null", "cat " + fe],
        ["s6-rc-db list services 2>/dev/null", "cat " + fempty]
    ]);
    assert.strictEqual(pe.code, 3);
    assert.strictEqual(pe.result.severity, "unavailable");
}

{
    const dinitSvc = H.byId("svc.list", H.checksFor(plat("", "dinit")));
    const out = lines(
        "[[+]     ] boot",
        "[{+}     ] sshd",
        "[     {-}] nfs",
        "[     {X}] foo (exit status: 1)"
    );
    assert.deepStrictEqual(H.run(dinitSvc, out, 0).services, [
        {name: "boot", state: "run", pid: null, seconds: null, normallyUp: true, scope: "system"},
        {name: "sshd", state: "run", pid: null, seconds: null, normallyUp: false, scope: "system"},
        {name: "nfs", state: "down", pid: null, seconds: null, normallyUp: false, scope: "system"},
        {name: "foo", state: "failed", pid: null, seconds: null, normallyUp: false, scope: "system"}
    ]);
    assert.deepStrictEqual(H.run(dinitSvc, out, 0).failed, ["foo"]);
    assert.strictEqual(H.run(dinitSvc, out, 0).severity, "bad");
    assert.deepStrictEqual(H.run(dinitSvc, "dinitctl: Permission denied\n", 1), {severity: "permission"});
}

{
    const actions = [];
    PKGS.forEach((pkg) => Object.keys(P.PKG[pkg].actions).forEach((action) => {
        const r = P.command(plat(pkg, ""), action, "sshd");
        assert.ok(typeof r.cmd === "string" && r.cmd.length > 0, pkg + " " + action);
        actions.push(r.cmd);
    }));
    INITS.forEach((init) => Object.keys(P.INIT[init].actions).forEach((action) => {
        const r = P.command(plat("", init), action, "sshd");
        assert.ok(typeof r.cmd === "string" && r.cmd.length > 0, init + " " + action);
        actions.push(r.cmd);
    }));
    actions.forEach((cmd) => shSyntax(cmd));

    assert.deepStrictEqual(P.command(plat("pacman", "systemd"), "restartService", "a;rm -rf"), {error: "bad service name"});
    assert.deepStrictEqual(P.command(plat("pacman", "systemd"), "restartService"), {error: "bad service name"});
    assert.ok(/apk/.test(P.command(plat("apk", ""), "removeOrphans").error));
    assert.strictEqual(typeof P.command({}, "update").error, "string");
    assert.strictEqual(typeof P.command({pkg: "", init: ""}, "restartService", "sshd").error, "string");
    assert.ok(P.command(plat("pacman", ""), "explode").error.includes("explode"));

    const doas = [];
    PKGS.forEach((pkg) => Object.keys(P.PKG[pkg].actions).forEach((action) => doas.push(P.command(plat(pkg, "", {priv: "doas"}), action, "sshd").cmd)));
    INITS.forEach((init) => Object.keys(P.INIT[init].actions).forEach((action) => doas.push(P.command(plat("", init, {priv: "doas"}), action, "sshd").cmd)));
    doas.forEach((cmd) => assert.ok(!cmd.includes("sudo"), cmd));
    assert.ok(P.command(plat("pacman", "", {priv: "doas"}), "pacdiff").cmd.includes("doas pacdiff"));
    assert.strictEqual(P.withPriv("sudo -E pacdiff; sudo x", {priv: "doas"}), "doas pacdiff; doas x");
}

{
    assert.strictEqual(P.supports({pkg: "pacman", init: "systemd"}, "update"), true);
    assert.strictEqual(P.supports({pkg: "apk", init: "systemd"}, "removeOrphans"), false);
    assert.strictEqual(P.supports({pkg: "apk", init: "systemd"}, "restartService"), true);
    assert.strictEqual(P.supports({pkg: "apt", init: ""}, "removeOrphans"), true);
    assert.strictEqual(P.supports({pkg: "apt", init: ""}, "restartService"), false);
    assert.strictEqual(P.supports({pkg: "", init: "dinit"}, "reboot"), true);
    assert.strictEqual(P.supports({pkg: "", init: "dinit"}, "update"), false);
    assert.strictEqual(P.supports({pkg: "pacman", init: "systemd"}, "nope"), false);
    assert.strictEqual(P.supports({pkg: "", init: ""}, "update"), false);
    assert.strictEqual(P.supports({pkg: "zypper", init: "s6"}, "stopService"), true);
}

{
    const rp = plat("pacman", "runit", {usvdir: "/home/u/.runit/runsvdir"});
    const r = P.INIT.runit.parse("a\tdown\t1\t\ts\nb\trun\t1\t5\tu\nb\trun\t1\t5\ts\n", 0);
    assert.deepStrictEqual(r.services.map(x => x.name + ":" + x.scope), ["a:system", "b:user", "b:system"]);
    assert.strictEqual(P.command(rp, "restartService", "b", "user").cmd, "sv restart /home/u/.runit/runsvdir/b");
    assert.strictEqual(P.command(rp, "restartService", "b", "user").quiet, "sv restart /home/u/.runit/runsvdir/b");
    assert.strictEqual(P.command(rp, "restartService", "a", "system").cmd, "sudo sv restart /run/runit/service/a");
    assert.strictEqual(P.command(rp, "restartService", "a", "system").quiet, "pkexec sv restart /run/runit/service/a");
    assert.strictEqual(P.command(Object.assign({}, rp, {priv: "doas"}), "stopService", "a", "system").quiet, null);
    assert.ok(P.command(plat("pacman", "runit"), "restartService", "b", "user").error);
    assert.strictEqual(P.parseDetect("init runit\nsvdir /run/runit/service\nusvdir /home/u/.runit/runsvdir").usvdir, "/home/u/.runit/runsvdir");
}

fs.rmSync(tmp, {recursive: true, force: true});
console.log("platform tests passed");
