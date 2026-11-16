pragma ComponentBehavior: Bound
import QtQuick
import qs.icons
import qs.services
import qs.style

Item {
    id: root

    property int mode: 2
    property bool showClock: true
    property bool monochrome: false
    property real speed: 0.4
    property real shuffleSec: 300

    readonly property real kick: 2400
    readonly property real ka: 6
    readonly property real kl: 25
    readonly property real damp: 5
    readonly property real grav: 1.3
    readonly property real jitter: 1.4
    readonly property real ballFrac: 0.5
    readonly property real snapMs: 260
    readonly property real minRad: 100

    readonly property var shapePool: ["circle", "square", "cookie4", "cookie6", "cookie7", "cookie9", "cookie12", "sunny", "flower", "puffy", "clover4", "clover8", "softBurst", "pentagon", "oval", "ghostish", "bun", "heart", "gem", "slanted", "arch", "fan"]
    readonly property var ballPool: ["cookie6", "circle", "triangle", "heart", "gem", "cookie4", "flower", "pill", "sunny", "clover4", "puffy", "pentagon", "cookie9", "softBurst"]
    readonly property var shapeScale: ({ square: 0.8, slanted: 0.8, oval: 0.9, bun: 0.9, heart: 0.9, arch: 0.85, fan: 0.85, gem: 0.9, pentagon: 0.92 })
    readonly property var tones: [Colors.md3.surface_container_high, Colors.md3.secondary_container, Colors.md3.tertiary_container, Colors.md3.surface_container_highest]

    function mix(a, b, t) { return Qt.tint(Qt.color(a), Qt.alpha(b, t)); }
    readonly property var monoTones: [
        Colors.md3.secondary_container,
        mix(Colors.md3.secondary_container, Colors.md3.surface, 0.28),
        mix(Colors.md3.secondary_container, Colors.md3.primary, 0.12),
        mix(Colors.md3.secondary_container, Colors.md3.surface, 0.43)
    ]
    readonly property color monoArena: mix(Colors.md3.primary_container, Colors.md3.primary, 0.35)

    property var blobs: []
    property var nodes: []
    property var links: []
    property var arc: null
    property var recent: []
    property real genW: 0
    property real genH: 0
    property bool awake: false
    property real arenaR: 250
    property real arenaX: 0
    property real arenaY: 0
    property real arenaDn: 0
    property real phase: 0
    property bool leaving: false
    property real px: 0
    property real py: 0
    property real vx: 0
    property real vy: 0
    property real aox: 0
    property real aoy: 0
    property real gt: 0
    property string ballName: "cookie6"

    readonly property var loc: Qt.locale(Config.language.split("_").slice(0, 2).join("_"))
    readonly property string hourStr: {
        LocaleService.liveTime;
        return new Date().toLocaleString(loc, Config.hourFormat === 0 ? "HH" : "h");
    }
    readonly property string minStr: {
        LocaleService.liveTime;
        return new Date().toLocaleString(loc, "mm");
    }
    readonly property string periodStr: {
        LocaleService.liveTime;
        return Config.hourFormat === 0 ? "" : new Date().toLocaleString(loc, Config.hourFormat === 2 ? "AP" : "ap");
    }

    readonly property real s: Math.max(0.2, Math.min(width, height) / 1440)
    readonly property real simRate: 0.7
    readonly property real simStep: 1 / 200
    property real simAcc: 0
    readonly property real bz: arenaR * ballFrac
    readonly property real rz: arenaR * 0.86 - bz / 2

    function rnd(a, b) { return a + Math.random() * (b - a); }
    function pick(a) { return a[Math.floor(Math.random() * a.length)]; }
    function angDiff(a, b) {
        const d = Math.abs(a - b) % (2 * Math.PI);
        return d > Math.PI ? 2 * Math.PI - d : d;
    }

    function local(dn) { return Math.max(0, Math.min(1, phase * 1.6 - 0.6 * (leaving ? 1 - dn : dn))); }
    function aScale(dn) {
        const l = local(dn);
        if (leaving)
            return 1 - Math.pow(1 - l, 3);
        const c1 = 1.1, c3 = c1 + 1, x = l - 1;
        return 1 + c3 * x * x * x + c1 * x * x;
    }
    function aOpacity(dn) {
        const l = local(dn);
        return Math.min(1, l * (leaving ? 1.8 : 2.2));
    }

    function generate() {
        if (width < 300 || height < 300)
            return;
        if (blobs.length > 0 && width === genW && height === genH)
            return;
        const first = blobs.length === 0;
        genW = width;
        genH = height;
        const W = width, H = height, m = 170 * s;
        arenaR = Math.min(W, H) * rnd(0.28, 0.38);
        const mx = Math.max(0, Math.min(0.22 * W, W / 2 - arenaR - 30));
        const my = Math.max(0, Math.min(0.2 * H, H / 2 - arenaR - 30));
        arenaX = rnd(-mx, mx);
        arenaY = rnd(-my, my);
        const out = [{ x: arenaX, y: arenaY, r: arenaR, shape: "cookie9", tilt: 0, arena: true, ci: 0, sc: 1 }];
        for (let rad = 320 * s; rad >= minRad * s; rad -= 22 * s) {
            for (let n = 0; n < 400; n++) {
                const x = rnd(-W / 2 - m, W / 2 + m), y = rnd(-H / 2 - m, H / 2 + m);
                const r = rad * rnd(0.75, 1.0);
                const g = rnd(8, 34) * s;
                let ok = true;
                for (const o of out) {
                    if (Math.hypot(o.x - x, o.y - y) < o.r + r + (o.arena ? 18 * s : g)) {
                        ok = false;
                        break;
                    }
                }
                if (ok) {
                    const sh = pick(shapePool);
                    out.push({ x, y, r, shape: sh, tilt: rnd(0, 360), arena: false, ci: Math.floor(Math.random() * 4), sc: shapeScale[sh] ?? 1 });
                }
            }
        }
        let bi = -1, bj = -1, bs = 0;
        const inside = o => Math.abs(o.x) < W / 2 - o.r * 0.2 && Math.abs(o.y) < H / 2 - o.r * 0.2;
        for (let i = 1; i < out.length; i++) {
            for (let j = i + 1; j < out.length; j++) {
                const p = out[i], q = out[j];
                if (!inside(p) || !inside(q))
                    continue;
                if (Math.hypot(p.x - q.x, p.y - q.y) > p.r + q.r + 70 * s)
                    continue;
                const L = p.x < q.x ? p : q, R = L === p ? q : p;
                if (L.y > R.y)
                    continue;
                const sz = Math.min(p.r, q.r);
                if (sz > bs) {
                    bs = sz;
                    bi = i;
                    bj = j;
                }
            }
        }
        if (bi > 0) {
            const l = out[bi].x < out[bj].x ? out[bi] : out[bj];
            const r = l === out[bi] ? out[bj] : out[bi];
            l.clk = "h";
            r.clk = "m";
        }
        for (const o of out) {
            o.clk = o.clk ?? "";
            o.dn = Math.max(0, Math.min(1, ((o.x + W / 2) / W + (o.y + H / 2) / H) / 2));
        }
        arenaDn = out[0].dn;
        blobs = out;
        nodes = out.map(o => ({ ox: 0, oy: 0, vx: 0, vy: 0, fx: 0, fy: 0, m: (o.r / (200 * s)) * (o.r / (200 * s)) }));
        const ls = [];
        for (let i = 0; i < out.length; i++) {
            for (let j = i + 1; j < out.length; j++) {
                if (Math.hypot(out[i].x - out[j].x, out[i].y - out[j].y) < out[i].r + out[j].r + 80 * s)
                    ls.push([i, j]);
            }
        }
        links = ls;
        awake = false;
        if (first) {
            resetBall();
            phase = 0;
            introAnim.restart();
        }
    }

    function makeArc(sx, sy) {
        const from = (sx === 0 && sy === 0) ? null : Math.atan2(sy, sx);
        let base = rnd(0, 6.28);
        for (let i = 0; i < 30; i++) {
            const c = rnd(0, 6.28);
            if ((from === null || angDiff(c, from) > 1.0) && recent.every(r => angDiff(c, r) > 0.7)) {
                base = c;
                break;
            }
        }
        recent = recent.concat([base]).slice(-3);
        const tx = Math.cos(base) * rz, ty = Math.sin(base) * rz;
        const wa = rnd(0, 6.28), wr = rnd(0, 0.65) * rz;
        const cx = 2 * wr * Math.cos(wa) - (sx + tx) / 2, cy = 2 * wr * Math.sin(wa) - (sy + ty) / 2;
        const len = (Math.hypot(cx - sx, cy - sy) + Math.hypot(tx - cx, ty - cy) + Math.hypot(tx - sx, ty - sy)) / 2;
        arc = { sx, sy, cx, cy, tx, ty, t: 0, T: len / (Math.min(width, height) * 0.5 * rnd(0.75, 1.3)) };
    }

    function resetBall() {
        px = 0;
        py = 0;
        recent = [];
        if (mode === 2) {
            makeArc(0, 0);
            return;
        }
        const a = mode === 0 ? rnd(-0.6, 0.6) : rnd(0, 6.28);
        const sp = Math.min(width, height) * (mode === 0 ? 0.3 : 0.24);
        vx = Math.cos(a) * sp;
        vy = mode === 0 ? 0 : Math.sin(a) * sp;
    }

    function hit(nx, ny, f) {
        const a = nodes[0];
        a.vx += kick * f / a.m * nx * s;
        a.vy += kick * f / a.m * ny * s;
        awake = true;
        const arena = tiles.itemAt(0);
        if (arena)
            arena.flashTo("circle", snapMs);
        ballName = pick(ballPool.filter(n => n !== ballName));
    }

    function stepSim(dt) {
        const h = simStep;
        const N = nodes;
        simAcc = Math.min(simAcc + dt * simRate, 0.1);
        while (simAcc >= h) {
            simAcc -= h;
            for (const n of N) {
                n.fx = -ka * n.ox;
                n.fy = -ka * n.oy;
            }
            for (const l of links) {
                const a = N[l[0]], b = N[l[1]];
                const fx = kl * (a.ox - b.ox), fy = kl * (a.oy - b.oy);
                a.fx -= fx;
                a.fy -= fy;
                b.fx += fx;
                b.fy += fy;
            }
            for (const n of N) {
                n.vx += (n.fx / n.m - damp * n.vx) * h;
                n.vy += (n.fy / n.m - damp * n.vy) * h;
                n.ox += n.vx * h;
                n.oy += n.vy * h;
            }
        }
        let e = 0;
        for (let k = 0; k < N.length; k++) {
            const n = N[k], t = tiles.itemAt(k);
            if (t) {
                t.kx = n.ox;
                t.ky = n.oy;
            }
            e = Math.max(e, Math.abs(n.ox) + Math.abs(n.oy) + Math.abs(n.vx) * 0.1 + Math.abs(n.vy) * 0.1);
        }
        aox = N[0].ox;
        aoy = N[0].oy;
        if (e < 0.05 * s)
            awake = false;
    }

    function stepBall(dt) {
        if (!isFinite(px) || !isFinite(py) || !isFinite(vx) || !isFinite(vy)) {
            resetBall();
            return;
        }
        const ref = Math.min(width, height);
        if (mode === 2) {
            const A = arc;
            if (!A)
                return;
            A.t += dt;
            const u = Math.min(1, A.t / A.T), w = 1 - u;
            let x = w * w * A.sx + 2 * w * u * A.cx + u * u * A.tx;
            let y = w * w * A.sy + 2 * w * u * A.cy + u * u * A.ty;
            const dd = Math.hypot(x, y);
            if (dd > rz) {
                x *= rz / dd;
                y *= rz / dd;
            }
            px = x;
            py = y;
            if (u >= 1) {
                hit(A.tx / rz, A.ty / rz, 1);
                makeArc(A.tx, A.ty);
            }
            return;
        }
        if (mode === 0) {
            const ga = 1.1 * Math.sin(gt * 0.35) + 0.7 * Math.sin(gt * 0.13 + 1);
            vx += Math.sin(ga) * ref * grav * dt;
            vy += Math.cos(ga) * ref * grav * dt;
        }
        px += vx * dt;
        py += vy * dt;
        const d = Math.hypot(px, py);
        if (d <= rz)
            return;
        const nx = px / d, ny = py / d;
        const dot = vx * nx + vy * ny;
        const f = Math.min(1.8, Math.max(0.4, dot / (ref * 0.4)));
        if (mode === 0) {
            const a = (Math.random() - 0.5) * jitter, c = Math.cos(a), s = Math.sin(a), e = 0.9 + Math.random() * 0.15;
            const rx = (vx - 2 * dot * nx) * e, ry = (vy - 2 * dot * ny) * e;
            const ux = rx * c - ry * s, uy = rx * s + ry * c;
            const sp = Math.hypot(ux, uy) || 1, k = Math.min(ref * 1.1, Math.max(ref * 0.4, sp)) / sp;
            vx = ux * k;
            vy = uy * k;
        } else {
            const sp = Math.hypot(vx, vy);
            const a = Math.atan2(-ny, -nx) + (Math.random() - 0.5) * jitter * 1.4;
            vx = Math.cos(a) * sp;
            vy = Math.sin(a) * sp;
        }
        px = nx * rz;
        py = ny * rz;
        if (dot > ref * 0.12)
            hit(nx, ny, f);
    }

    signal cleared()
    property bool chain: false
    property bool emptied: false
    function clear() { introAnim.stop(); emptied = true; clearAnim.restart(); }
    function spawn() { emptied = false; spawnAnim.restart(); }
    function shuffle() { chain = true; clear(); }
    onCleared: if (chain) { chain = false; spawn(); }
    function replay() {
        blobs = [];
        genW = 0;
        generate();
    }

    onModeChanged: if (blobs.length > 0) resetBall()
    onWidthChanged: blobs.length > 0 ? regen.restart() : generate()
    onHeightChanged: blobs.length > 0 ? regen.restart() : generate()

    Timer {
        id: regen
        interval: root.blobs.length > 0 ? 300 : 30
        onTriggered: root.generate()
    }

    Timer {
        running: root.shuffleSec > 0 && !root.emptied
        repeat: true
        interval: Math.max(1000, root.shuffleSec * 1000)
        onTriggered: root.shuffle()
    }

    NumberAnimation {
        id: introAnim
        target: root
        property: "phase"
        to: 1
        duration: 900
        easing.type: Easing.Linear
    }

    SequentialAnimation {
        id: clearAnim
        ScriptAction { script: root.leaving = true }
        NumberAnimation { target: root; property: "phase"; to: 0; duration: 550; easing.type: Easing.Linear }
        ScriptAction { script: root.cleared() }
    }

    SequentialAnimation {
        id: spawnAnim
        ScriptAction {
            script: {
                root.leaving = false;
                root.genW = 0;
                root.generate();
            }
        }
        NumberAnimation { target: root; property: "phase"; to: 1; duration: 900; easing.type: Easing.Linear }
    }

    FrameAnimation {
        running: root.blobs.length > 0
        onTriggered: {
            const dt = Math.min(frameTime, 0.05) * root.speed;
            root.gt += dt;
            root.stepBall(dt);
            if (root.awake)
                root.stepSim(Math.min(frameTime, 0.05));
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Colors.md3.surface
    }

    Item {
        anchors.fill: parent
        clip: true

        Repeater {
            id: tiles
            model: root.blobs

            SaverBlob {
                id: blob
                required property var modelData
                readonly property bool isHour: modelData.clk === "h"
                readonly property bool isMin: modelData.clk === "m"
                readonly property bool onClock: root.showClock && (isHour || isMin)

                rad: modelData.r
                x: root.width / 2 + modelData.x - modelData.r
                y: root.height / 2 + modelData.y - modelData.r
                shapeName: modelData.shape
                tilt: modelData.tilt
                sc: modelData.sc
                fill: modelData.arena ? (root.monochrome ? root.monoArena : Colors.md3.primary_container) : onClock ? (isHour ? Colors.md3.primary : root.monochrome ? Colors.md3.primary_fixed_dim : Colors.md3.secondary) : root.monochrome ? root.monoTones[modelData.ci] : root.tones[modelData.ci]
                textColor: isHour ? Colors.md3.on_primary : root.monochrome ? Colors.md3.on_primary_fixed : Colors.md3.on_secondary
                label: !onClock ? "" : isHour ? root.hourStr : root.minStr
                subLabel: onClock && isHour ? root.periodStr : ""
                appearScale: root.aScale(modelData.dn)
                appearOpacity: root.aOpacity(modelData.dn)
            }
        }

        Item {
            x: root.width / 2 + root.arenaX
            y: root.height / 2 + root.arenaY
            opacity: root.aOpacity(root.arenaDn)
            scale: root.aScale(root.arenaDn)

            MaterialShape {
                name: root.ballName
                immediate: true
                shapeSize: root.bz
                color: Colors.md3.tertiary
                x: root.px + root.aox - root.bz / 2
                y: root.py + root.aoy - root.bz / 2
                rotationAnimates: false

                NumberAnimation on rotation {
                    from: 0
                    to: 360
                    duration: 7000
                    loops: Animation.Infinite
                }
            }
        }
    }
}
