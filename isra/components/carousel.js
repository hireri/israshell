.pragma library

function lerp(a, b, t) {
    return a + (b - a) * t;
}

function slots(kind, inner, spacing, itemSize, small) {
    var S = small;
    var g = spacing;
    var W = Math.max(0, inner);
    var L, M;
    switch (kind) {
    case "uncontained":
        return Array(Math.ceil((W + g) / (itemSize + g)) + 1).fill(itemSize);
    case "hero":
        return [Math.max(S, W - S - g), S];
    case "centerHero":
        return [S, Math.max(S, W - 2 * S - 2 * g), S];
    default:
        L = Math.min(itemSize, W - 2.5 * S - 2 * g);
        M = W - L - S - 2 * g;
        if (M > L) {
            L = (W - S - 2 * g) / 2;
            M = L;
        }
        return [Math.max(L, S), Math.max(M, S), S];
    }
}

function widthAt(slotWidths, offWidth, s) {
    var n = slotWidths.length;
    if (s <= -1)
        return offWidth;
    if (s >= n - 1)
        return slotWidths[n - 1];
    if (s <= 0)
        return lerp(offWidth, slotWidths[0], s + 1);
    var i = Math.floor(s);
    return lerp(slotWidths[i], slotWidths[i + 1], s - i);
}

function frame(slotWidths, offWidth, spacing, leading, position, count) {
    var xs = [];
    var ws = [];
    var k = Math.floor(position);
    var f = position - k;
    var i;
    for (i = 0; i < count; i++) {
        ws.push(widthAt(slotWidths, offWidth, i - position));
        xs.push(0);
    }
    if (k >= 0 && k < count) {
        xs[k] = leading - f * (spacing + offWidth);
        for (i = k + 1; i < count; i++)
            xs[i] = xs[i - 1] + ws[i - 1] + spacing;
        for (i = k - 1; i >= 0; i--)
            xs[i] = xs[i + 1] - spacing - ws[i];
    }
    return { xs: xs, ws: ws };
}
