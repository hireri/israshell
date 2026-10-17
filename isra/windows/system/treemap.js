.pragma library

var cache = null;

function stored() {
    return cache;
}

function store(nodes) {
    cache = { nodes: nodes, at: Date.now() };
}
var MAX_DEPTH = 3;
var MAX_ITEMS = 36;

function _name(path) {
    var i = path.lastIndexOf("/");
    return i < 0 ? path : path.slice(i + 1);
}

function _depth(path, root) {
    return path === root ? 0 : path.slice(root.length).split("/").length - 1;
}

function merge(nodes, text, root) {
    var base = nodes[root];
    if (base)
        base.kids = [];
    var lines = text.split("\n");
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i];
        var t = line.indexOf("\t");
        if (t < 1)
            continue;
        var path = line.slice(t + 1);
        var node = nodes[path];
        if (!node) {
            node = { path: path, name: _name(path), size: 0, kids: [], scanned: false };
            nodes[path] = node;
        }
        node.size = Number(line.slice(0, t));
        node.scanned = _depth(path, root) < MAX_DEPTH;
        if (path === root)
            continue;
        var parentPath = path.slice(0, path.lastIndexOf("/"));
        var parent = nodes[parentPath];
        if (!parent) {
            parent = { path: parentPath, name: _name(parentPath), size: 0, kids: [], scanned: false };
            nodes[parentPath] = parent;
        }
        if (parent.kids.indexOf(path) < 0)
            parent.kids.push(path);
    }
    return nodes;
}

function items(nodes, path) {
    var node = nodes[path];
    if (!node)
        return [];
    var out = [];
    var sum = 0;
    for (var i = 0; i < node.kids.length; i++) {
        var k = nodes[node.kids[i]];
        if (k && k.size > 0) {
            out.push({ path: k.path, name: k.name, size: k.size });
            sum += k.size;
        }
    }
    out.sort(function (a, b) { return b.size - a.size; });
    var rest = node.size - sum;
    if (out.length > MAX_ITEMS) {
        var tail = out.slice(MAX_ITEMS);
        out = out.slice(0, MAX_ITEMS);
        rest += tail.reduce(function (a, x) { return a + x.size; }, 0);
        out.push({ path: null, name: "…", size: rest, other: true });
    } else if (rest > node.size * 0.01) {
        out.push({ path: null, name: "", size: rest, files: true });
    }
    return out;
}

function layout(list, w, h) {
    var total = list.reduce(function (a, i) { return a + i.size; }, 0);
    if (!(total > 0) || w <= 0 || h <= 0)
        return [];
    var scale = w * h / total;
    var rest = list.map(function (i) { return { item: i, a: i.size * scale }; });
    var out = [];
    var x = 0, y = 0, rw = w, rh = h;
    var row = [];
    var rowSum = 0;

    function worst(r, sum, side) {
        var mx = 0, mn = Infinity;
        for (var i = 0; i < r.length; i++) {
            mx = Math.max(mx, r[i].a);
            mn = Math.min(mn, r[i].a);
        }
        return Math.max(side * side * mx / (sum * sum), sum * sum / (side * side * mn));
    }

    function flush() {
        if (row.length === 0)
            return;
        if (rw >= rh) {
            var cw = rowSum / rh;
            var cy = y;
            for (var i = 0; i < row.length; i++) {
                var ch = row[i].a / cw;
                out.push({ item: row[i].item, x: x, y: cy, w: cw, h: ch });
                cy += ch;
            }
            x += cw;
            rw -= cw;
        } else {
            var rhh = rowSum / rw;
            var cx = x;
            for (var j = 0; j < row.length; j++) {
                var cww = row[j].a / rhh;
                out.push({ item: row[j].item, x: cx, y: y, w: cww, h: rhh });
                cx += cww;
            }
            y += rhh;
            rh -= rhh;
        }
        row = [];
        rowSum = 0;
    }

    for (var n = 0; n < rest.length; n++) {
        var r = rest[n];
        var side = Math.min(rw, rh);
        if (row.length === 0 || worst(row.concat([r]), rowSum + r.a, side) <= worst(row, rowSum, side)) {
            row.push(r);
            rowSum += r.a;
        } else {
            flush();
            row.push(r);
            rowSum = r.a;
        }
    }
    flush();
    return out;
}
