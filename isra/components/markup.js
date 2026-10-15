.pragma library

function normRect(s) {
    return {
        x: Math.min(s.x1, s.x2),
        y: Math.min(s.y1, s.y2),
        w: Math.abs(s.x2 - s.x1),
        h: Math.abs(s.y2 - s.y1)
    };
}

function addPoint(points, x, y) {
    const last = points.length ? points[points.length - 1] : null;
    if (last && Math.hypot(x - last.x, y - last.y) < 2)
        return points;
    return points.concat([{ x: x, y: y }]);
}

function isBoxed(type) {
    return type === "rect" || type === "ellipse" || type === "blur" || type === "pixelate";
}

function isEffect(t) {
    return t === "blur" || t === "pixelate";
}

function constrain(type, x1, y1, x2, y2) {
    const dx = x2 - x1, dy = y2 - y1;
    if (isBoxed(type)) {
        const size = Math.max(Math.abs(dx), Math.abs(dy));
        return { x: x1 + (dx < 0 ? -size : size), y: y1 + (dy < 0 ? -size : size) };
    }
    if (type === "line" || type === "arrow") {
        const len = Math.hypot(dx, dy);
        const a = Math.round(Math.atan2(dy, dx) / (Math.PI / 4)) * (Math.PI / 4);
        return { x: x1 + len * Math.cos(a), y: y1 + len * Math.sin(a) };
    }
    return { x: x2, y: y2 };
}

function arrowPolygon(x1, y1, x2, y2, w) {
    const dx = x2 - x1, dy = y2 - y1;
    const L = Math.hypot(dx, dy);
    if (L < 1)
        return [];
    const ux = dx / L, uy = dy / L, nx = -uy, ny = ux;
    const at = (a, b) => ({ x: x1 + ux * a + nx * b, y: y1 + uy * a + ny * b });
    const head = Math.min(Math.max(16, w * 5), L * 0.7);
    const half = head * 0.55, notch = head * 0.25;
    const s = Math.max(1, w * 0.6), t = Math.max(0.75, w * 0.2);
    return [
        at(0, -t), at(L - head + notch, -s), at(L - head, -half), at(L, 0),
        at(L - head, half), at(L - head + notch, s), at(0, t), at(0, -t)
    ];
}

function fontSize(width) {
    return width >= 8 ? 32 : width >= 4 ? 22 : 16;
}

function stepDiameter(width) {
    return 24 + width * 2;
}

function textSize(s) {
    if (typeof s.tw === "number" && typeof s.th === "number")
        return { w: s.tw, h: s.th };
    const fs = fontSize(s.width);
    return { w: (s.text || "").length * fs * 0.6, h: fs * 1.3 };
}

function _grow(r, g) {
    return { x: r.x - g, y: r.y - g, w: r.w + 2 * g, h: r.h + 2 * g };
}

function _bbox(points) {
    if (!points || !points.length)
        return { x: 0, y: 0, w: 0, h: 0 };
    let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
    for (const p of points) {
        minX = Math.min(minX, p.x);
        minY = Math.min(minY, p.y);
        maxX = Math.max(maxX, p.x);
        maxY = Math.max(maxY, p.y);
    }
    return { x: minX, y: minY, w: maxX - minX, h: maxY - minY };
}

function bounds(s) {
    switch (s.type) {
    case "line":
        return _grow(normRect(s), s.width / 2);
    case "arrow": {
        const poly = arrowPolygon(s.x1, s.y1, s.x2, s.y2, s.width);
        return poly.length ? _bbox(poly) : { x: s.x1, y: s.y1, w: 0, h: 0 };
    }
    case "pen":
        return _grow(_bbox(s.points), s.width / 2);
    case "highlighter":
        return _grow(_bbox(s.points), s.width * 2);
    case "text": {
        const ts = textSize(s);
        return { x: s.x1, y: s.y1, w: ts.w, h: ts.h };
    }
    case "step": {
        const d = stepDiameter(s.width);
        return { x: s.x1 - d / 2, y: s.y1 - d / 2, w: d, h: d };
    }
    default:
        return normRect(s);
    }
}

function _inRect(x, y, r) {
    return x >= r.x && x <= r.x + r.w && y >= r.y && y <= r.y + r.h;
}

function _segDist(px, py, ax, ay, bx, by) {
    const dx = bx - ax, dy = by - ay;
    const len2 = dx * dx + dy * dy;
    const t = len2 ? Math.max(0, Math.min(1, ((px - ax) * dx + (py - ay) * dy) / len2)) : 0;
    return Math.hypot(px - (ax + t * dx), py - (ay + t * dy));
}

function _polyDist(points, x, y) {
    if (points.length === 1)
        return Math.hypot(x - points[0].x, y - points[0].y);
    let best = Infinity;
    for (let i = 1; i < points.length; i++)
        best = Math.min(best, _segDist(x, y, points[i - 1].x, points[i - 1].y, points[i].x, points[i].y));
    return best;
}

function _hit(s, x, y, tol) {
    const g = tol + s.width / 2;
    switch (s.type) {
    case "step":
        return Math.hypot(x - s.x1, y - s.y1) <= stepDiameter(s.width) / 2 + tol;
    case "text": {
        const ts = textSize(s);
        return _inRect(x, y, _grow({ x: s.x1, y: s.y1, w: ts.w, h: ts.h }, tol));
    }
    case "blur":
    case "pixelate":
        return _inRect(x, y, _grow(normRect(s), tol));
    case "rect":
        return _inRect(x, y, _grow(normRect(s), g));
    case "ellipse": {
        const r = normRect(s);
        const rx = r.w / 2, ry = r.h / 2, cx = r.x + rx, cy = r.y + ry;
        if (rx < 1 || ry < 1)
            return _inRect(x, y, _grow(r, g));
        return Math.hypot((x - cx) / rx, (y - cy) / ry) <= 1 + g / Math.min(rx, ry);
    }
    case "line":
        return _segDist(x, y, s.x1, s.y1, s.x2, s.y2) <= g;
    case "arrow":
        return _segDist(x, y, s.x1, s.y1, s.x2, s.y2) <= tol + Math.max(s.width, 6);
    case "pen":
        return _polyDist(s.points || [], x, y) <= g;
    case "highlighter":
        return _polyDist(s.points || [], x, y) <= tol + s.width * 2;
    default:
        return false;
    }
}

function hits(s, x, y, tol) {
    return !!s && _hit(s, x, y, tol);
}

function hitTest(shapes, x, y, tol) {
    for (const fx of [false, true])
        for (let i = shapes.length - 1; i >= 0; i--)
            if (isEffect(shapes[i].type) === fx && _hit(shapes[i], x, y, tol))
                return i;
    return -1;
}

function handlesFor(s) {
    if (!s)
        return [];
    if (isBoxed(s.type)) {
        const r = normRect(s);
        return [
            { id: "tl", x: r.x, y: r.y },
            { id: "tr", x: r.x + r.w, y: r.y },
            { id: "br", x: r.x + r.w, y: r.y + r.h },
            { id: "bl", x: r.x, y: r.y + r.h }
        ];
    }
    if (s.type === "line" || s.type === "arrow")
        return [{ id: "p1", x: s.x1, y: s.y1 }, { id: "p2", x: s.x2, y: s.y2 }];
    return [];
}

function handleAt(s, x, y, r) {
    const hs = handlesFor(s);
    for (const h of hs)
        if (Math.abs(x - h.x) <= r && Math.abs(y - h.y) <= r)
            return h.id;
    return "";
}

function dragHandle(s, id, x, y) {
    if (isBoxed(s.type)) {
        const r = normRect(s);
        let x1 = r.x, y1 = r.y, x2 = r.x + r.w, y2 = r.y + r.h;
        switch (id) {
        case "tl": x1 = x; y1 = y; break;
        case "tr": x2 = x; y1 = y; break;
        case "br": x2 = x; y2 = y; break;
        case "bl": x1 = x; y2 = y; break;
        default: return s;
        }
        return Object.assign({}, s, { x1: x1, y1: y1, x2: x2, y2: y2 });
    }
    if (s.type === "line" || s.type === "arrow") {
        if (id === "p1")
            return Object.assign({}, s, { x1: x, y1: y });
        if (id === "p2")
            return Object.assign({}, s, { x2: x, y2: y });
    }
    return s;
}

function translate(s, dx, dy) {
    const c = Object.assign({}, s);
    if (typeof s.x1 === "number") c.x1 = s.x1 + dx;
    if (typeof s.y1 === "number") c.y1 = s.y1 + dy;
    if (typeof s.x2 === "number") c.x2 = s.x2 + dx;
    if (typeof s.y2 === "number") c.y2 = s.y2 + dy;
    if (s.points) c.points = s.points.map(p => ({ x: p.x + dx, y: p.y + dy }));
    return c;
}

function withStyle(s, color, width) {
    const c = Object.assign({}, s, { color: color, width: width });
    if (s.type === "text" && typeof s.tw === "number" && typeof s.th === "number") {
        const k = fontSize(width) / fontSize(s.width);
        c.tw = s.tw * k;
        c.th = s.th * k;
    }
    return c;
}

function replaceAt(shapes, i, s) {
    return shapes.map((o, j) => j === i ? s : o);
}

function removeAt(shapes, i) {
    return shapes.filter((o, j) => j !== i);
}

function newDoc() {
    return { shapes: [], past: [], future: [] };
}

function commit(doc, shapes) {
    if (shapes === doc.shapes)
        return doc;
    return { shapes: shapes, past: doc.past.concat([doc.shapes]), future: [] };
}

function amend(doc, shapes) {
    if (shapes === doc.shapes)
        return doc;
    return { shapes: shapes, past: doc.past, future: [] };
}

function undo(doc) {
    if (!doc.past.length)
        return doc;
    return {
        shapes: doc.past[doc.past.length - 1],
        past: doc.past.slice(0, -1),
        future: doc.future.concat([doc.shapes])
    };
}

function redo(doc) {
    if (!doc.future.length)
        return doc;
    return {
        shapes: doc.future[doc.future.length - 1],
        past: doc.past.concat([doc.shapes]),
        future: doc.future.slice(0, -1)
    };
}

function push(shapes, shape) {
    return shapes.concat([shape]);
}

function nextStep(shapes) {
    let n = 0;
    for (let i = 0; i < shapes.length; i++)
        if (shapes[i].type === "step" && shapes[i].n > n)
            n = shapes[i].n;
    return n + 1;
}

function isEmpty(s) {
    switch (s.type) {
    case "rect":
    case "ellipse":
    case "blur":
    case "pixelate":
        return Math.abs(s.x2 - s.x1) < 3 || Math.abs(s.y2 - s.y1) < 3;
    case "line":
    case "arrow":
        return Math.abs(s.x2 - s.x1) < 3 && Math.abs(s.y2 - s.y1) < 3;
    case "pen":
    case "highlighter":
        return !s.points || s.points.length < 2;
    case "text":
        return !s.text || !s.text.trim();
    default:
        return false;
    }
}

function _lin(c) {
    c /= 255;
    return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
}

function contrastColor(hex) {
    const n = parseInt(hex.replace("#", ""), 16);
    const L = 0.2126 * _lin((n >> 16) & 255) + 0.7152 * _lin((n >> 8) & 255) + 0.0722 * _lin(n & 255);
    return L > 0.179 ? "#000000" : "#ffffff";
}
