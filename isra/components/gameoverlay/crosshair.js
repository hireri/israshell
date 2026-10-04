.pragma library

var presets = ["FFFFFF", "00FF00", "7FFF00", "DFFF00", "FFFF00", "00FFFF", "FF00FF", "FF0000"];

function defaults() {
    return {
        colorIndex: 0,
        custom: "FFFFFF",
        outline: { on: true, opacity: 0.5, thickness: 1 },
        dot: { on: false, opacity: 1, size: 2 },
        inner: { on: true, opacity: 0.8, length: 6, vlength: -1, unbind: false, thickness: 2, offset: 3 },
        outer: { on: true, opacity: 0.35, length: 2, vlength: -1, unbind: false, thickness: 2, offset: 10 }
    };
}

function _num(v, min, max) {
    var n = parseFloat(v);
    return isNaN(n) ? undefined : Math.max(min, Math.min(max, n));
}

function _int(v, min, max) {
    var n = _num(v, min, max);
    return n === undefined ? undefined : Math.round(n);
}

function _bool(v) {
    return v === "1";
}

var setters = {
    "c": function (s, v) { var n = _num(v, 0, 8); if (n !== undefined) s.colorIndex = Math.round(n); },
    "u": function (s, v) { if (/^[0-9a-fA-F]{6}/.test(v)) s.custom = v.slice(0, 6); },
    "h": function (s, v) { s.outline.on = _bool(v); },
    "o": function (s, v) { var n = _num(v, 0, 1); if (n !== undefined) s.outline.opacity = n; },
    "t": function (s, v) { var n = _int(v, 0, 16); if (n !== undefined) s.outline.thickness = n; },
    "d": function (s, v) { s.dot.on = _bool(v); },
    "a": function (s, v) { var n = _num(v, 0, 1); if (n !== undefined) s.dot.opacity = n; },
    "z": function (s, v) { var n = _int(v, 0, 32); if (n !== undefined) s.dot.size = n; }
};

["0", "1"].forEach(function (prefix) {
    var layer = prefix === "0" ? "inner" : "outer";
    setters[prefix + "b"] = function (s, v) { s[layer].on = _bool(v); };
    setters[prefix + "a"] = function (s, v) { var n = _num(v, 0, 1); if (n !== undefined) s[layer].opacity = n; };
    setters[prefix + "l"] = function (s, v) { var n = _int(v, 0, 64); if (n !== undefined) s[layer].length = n; };
    setters[prefix + "v"] = function (s, v) { var n = _int(v, 0, 64); if (n !== undefined) s[layer].vlength = n; };
    setters[prefix + "g"] = function (s, v) { s[layer].unbind = _bool(v); };
    setters[prefix + "t"] = function (s, v) { var n = _int(v, 0, 32); if (n !== undefined) s[layer].thickness = n; };
    setters[prefix + "o"] = function (s, v) { var n = _int(v, 0, 64); if (n !== undefined) s[layer].offset = n; };
});

function parse(code) {
    var s = defaults();
    var t = String(code || "").split(";");
    for (var i = 0; i < t.length; i++) {
        var set = setters.hasOwnProperty(t[i]) ? setters[t[i]] : null;
        if (set && i + 1 < t.length) {
            set(s, t[i + 1]);
            i++;
        }
    }
    s.color = "#" + (s.colorIndex === 8 ? s.custom : (presets[s.colorIndex] || presets[0]));
    ["inner", "outer"].forEach(function (k) {
        if (!s[k].unbind || s[k].vlength < 0)
            s[k].vlength = s[k].length;
    });
    return s;
}

function reach(s) {
    var b = s.outline.on ? s.outline.thickness : 0;
    var r = 0;
    if (s.dot.on)
        r = Math.max(r, s.dot.size / 2 + b);
    ["inner", "outer"].forEach(function (k) {
        var l = s[k];
        if (l.on && l.thickness > 0)
            r = Math.max(r, l.offset + Math.max(l.length, l.vlength) + b);
    });
    return Math.ceil(r) + 2;
}

function serialize(s) {
    function num(v) { return String(Math.round(v * 100) / 100); }
    function bool(v) { return v ? "1" : "0"; }
    var t = ["0", "P", "c", String(s.colorIndex)];
    if (s.colorIndex === 8)
        t.push("u", s.custom);
    t.push("h", bool(s.outline.on), "o", num(s.outline.opacity), "t", num(s.outline.thickness));
    t.push("d", bool(s.dot.on), "a", num(s.dot.opacity), "z", num(s.dot.size));
    ["inner", "outer"].forEach(function (k, i) {
        var l = s[k];
        t.push(i + "b", bool(l.on), i + "a", num(l.opacity), i + "l", num(l.length), i + "v", num(l.vlength));
        t.push(i + "g", bool(l.unbind), i + "t", num(l.thickness), i + "o", num(l.offset));
    });
    return t.join(";");
}
