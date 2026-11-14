.pragma library

function holePath(o) {
    const i = o.inset || 0, F = o.f, C = o.c;
    const L = o.x1, T = o.y1, R = o.x2, B = o.y2;
    const n = v => Math.round(v * 100) / 100;

    const edges = [
        { len: R - L, org: L, rev: false, depth: B - T, r0: o.rt, r1: o.rt, panels: o.top, snap: true, pt: (u, v) => [L + u, T + v] },
        { len: B - T, org: T, rev: false, depth: R - L, r0: o.rt, r1: o.rb, panels: o.right, snap: false, pt: (u, v) => [R - v, T + u] },
        { len: R - L, org: L, rev: true, depth: B - T, r0: o.rb, r1: o.rb, panels: o.bottom, snap: true, pt: (u, v) => [R - u, B - v] },
        { len: B - T, org: T, rev: true, depth: R - L, r0: o.rb, r1: o.rt, panels: o.left, snap: false, pt: (u, v) => [L + v, B - u] }
    ];

    for (const e of edges) {
        const X2 = e.len;

        const ps = (e.panels || []).map(p => {
            const a = p.p - e.org, b = a + p.w;
            return { l: Math.max(e.rev ? X2 - b : a, 0), r: Math.min(e.rev ? X2 - a : b, X2), h: Math.min(p.h, e.depth) };
        }).filter(p => p.r - p.l > 0.5 && p.h > 0.5);
        for (const p of ps) {
            if (e.snap) {
                if (p.l < F + e.r0) p.l = 0;
                if (X2 - p.r < F + e.r1) p.r = X2;
            } else {
                p.l = Math.max(p.l, e.r0 + F);
                p.r = Math.min(p.r, X2 - e.r1 - F);
            }
        }
        const xs = [0, X2];
        for (const p of ps) if (p.r - p.l > 0.5) xs.push(p.l, p.r);
        xs.sort((a, b) => a - b);
        let segs = [];
        for (let j = 0; j + 1 < xs.length; j++) {
            const l = xs[j], r = xs[j + 1];
            if (r - l < 0.5) continue;
            const m = (l + r) / 2;
            let h = 0;
            for (const p of ps) if (p.r - p.l > 0.5 && p.l <= m && m < p.r) h = Math.max(h, p.h);
            const last = segs[segs.length - 1];
            if (last && Math.abs(last.h - h) < 0.5) last.r = r;
            else segs.push({ l: l, r: r, h: h });
        }

        for (let j = 1; j + 1 < segs.length; j++) {
            if (segs[j].h === 0 && segs[j].r - segs[j].l < 2 * F)
                segs[j].h = Math.min(segs[j - 1].h, segs[j + 1].h);
        }
        const merged = [];
        for (const s of segs) {
            const last = merged[merged.length - 1];
            if (last && Math.abs(last.h - s.h) < 0.5) last.r = s.r;
            else merged.push(s);
        }
        segs = merged;
        for (const s of segs)
            s.k = s.h > 0 ? Math.min(1, (s.r - s.l) / (2 * (F + C)), s.h / (F + C)) : 0;
        e.segs = segs;
        e.rS = Math.max(0, e.r0 - i);
        e.rE = Math.max(0, e.r1 - i);
        e.fil = s => Math.max(0, F * s.k - i);   // hole convex fillet where a panel meets the edge
        e.fS = s => Math.max(e.fil(s), e.rS);    // corner flush panels keep at least the frame corner so closing never flattens it
        e.fE = s => Math.max(e.fil(s), e.rE);
        e.pc = s => C * s.k + i;                 // hole reflex corner at the bottom of a panel next to the edge
        e.Bd = s => i + s.h;
        e.sFlush = segs[0].h > 0;
        e.eFlush = segs[segs.length - 1].h > 0;
    }

    const d = [];
    for (let k = 0; k < 4; k++) {
        const e = edges[k], nx = edges[(k + 1) % 4], pv = edges[(k + 3) % 4];
        const P = (u, v) => { const q = e.pt(u, v); return n(q[0]) + " " + n(q[1]); };
        const L_ = (u, v) => d.push("L" + P(u, v));
        const A = (r, u, v, s) => r < 0.01 ? L_(u, v) : d.push("A" + n(r) + " " + n(r) + " 0 0 " + s + " " + P(u, v));
        const segs = e.segs, len = e.len, x2 = len - i;

        if (k === 0) {
            if (e.sFlush) {
                const s = segs[0], q = pv.pt(pv.len - (i + s.h + e.fS(s)), i);
                d.push("M" + n(q[0]) + " " + n(q[1]));
            } else {
                d.push("M" + P(i + e.rS, i));
            }
        }
        if (e.sFlush) {
            const s = segs[0];
            A(e.fS(s), i + e.fS(s), e.Bd(s), 1);
        }

        for (let j = 0; j < segs.length; j++) {
            const s = segs[j], nxs = segs[j + 1];
            if (!nxs) {
                if (s.h > 0) {
                    L_(x2 - e.fE(s), e.Bd(s));
                    A(e.fE(s), x2, e.Bd(s) + e.fE(s), 1);
                } else if (nx.sFlush) {
                    L_(len - (i + nx.segs[0].h + nx.fS(nx.segs[0])), i);
                } else {
                    L_(x2 - e.rE, i);
                    A(e.rE, x2, i + e.rE, 1);
                }
                break;
            }
            const a = s.h, b = nxs.h, xb = s.r;
            if (a === 0) {                       // edge -> panel: fillet, down the panel's side, round its far corner
                const xv = xb - i, cb = e.pc(nxs);
                const fb = nxs.r >= len - 0.5 && e.snap ? Math.min(Math.max(e.fil(nxs), e.rE), Math.max(0, nxs.h - cb)) : e.fil(nxs);
                L_(xv - fb, i); A(fb, xv, i + fb, 1);
                L_(xv, e.Bd(nxs) - cb); A(cb, xv + cb, e.Bd(nxs), 0);
            } else if (b === 0) {                // panel -> edge
                const xv = xb + i, ca = e.pc(s);
                const fb = j === 0 && e.snap ? Math.min(Math.max(e.fil(s), e.rS), Math.max(0, s.h - ca)) : e.fil(s);
                L_(xv - ca, e.Bd(s)); A(ca, xv, e.Bd(s) - ca, 0);
                L_(xv, i + fb); A(fb, xv + fb, i, 1);
            } else if (a > b) {                  // step up towards the edge
                const cs = Math.max(0, Math.min(C * Math.min(s.k, nxs.k), (a - b) / 2, (nxs.r - nxs.l) / 2));
                const xv = xb + i;
                L_(xv - cs - i, e.Bd(s)); A(cs + i, xv, e.Bd(s) - cs - i, 0);
                L_(xv, e.Bd(nxs) + Math.max(0, cs - i)); A(Math.max(0, cs - i), xv + Math.max(0, cs - i), e.Bd(nxs), 1);
            } else {                             // step down away from the edge
                const cs = Math.max(0, Math.min(C * Math.min(s.k, nxs.k), (b - a) / 2, (s.r - s.l) / 2));
                const xv = xb - i;
                L_(xv - Math.max(0, cs - i), e.Bd(s)); A(Math.max(0, cs - i), xv, e.Bd(s) + Math.max(0, cs - i), 1);
                L_(xv, e.Bd(nxs) - cs - i); A(cs + i, xv + cs + i, e.Bd(nxs), 0);
            }
        }
    }
    d.push("Z");
    return d.join(" ");
}
