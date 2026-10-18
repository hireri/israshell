.pragma library

const CONSTS = { pi: Math.PI, e: Math.E, tau: 2 * Math.PI, phi: (1 + Math.sqrt(5)) / 2 };
const RAD = Math.PI / 180;
const snap = x => Math.abs(x) < 1e-15 ? 0 : Math.round(x * 1e15) / 1e15;

const FNS = {
    sqrt: Math.sqrt, cbrt: Math.cbrt, abs: Math.abs, exp: Math.exp,
    floor: Math.floor, ceil: Math.ceil, round: Math.round, trunc: Math.trunc,
    sin: x => snap(Math.sin(x)), cos: x => snap(Math.cos(x)), tan: x => snap(Math.tan(x)),
    sind: x => snap(Math.sin(x * RAD)), cosd: x => snap(Math.cos(x * RAD)), tand: x => snap(Math.tan(x * RAD)),
    asin: Math.asin, acos: Math.acos, atan: Math.atan, atan2: Math.atan2,
    sinh: Math.sinh, cosh: Math.cosh, tanh: Math.tanh,
    asinh: Math.asinh, acosh: Math.acosh, atanh: Math.atanh,
    ln: Math.log, log2: Math.log2, log10: Math.log10,
    log: (x, b) => b === undefined ? Math.log10(x) : Math.log(x) / Math.log(b),
    pow: Math.pow, min: Math.min, max: Math.max
};

function factorial(n) {
    if (!Number.isInteger(n) || n < 0 || n > 170) return NaN;
    let r = 1;
    for (let i = 2; i <= n; i++) r *= i;
    return r;
}

const CHAR_MAP = { "×": "*", "·": "*", "÷": "/", "−": "-", "–": "-", "π": "pi", "²": "^2", "³": "^3", "√": "sqrt " };

function tokenize(src) {
    const s = src.toLowerCase().replace(/[×·÷−–π²³√]/g, c => CHAR_MAP[c]).replace(/\*\*/g, "^");
    const out = [];
    const parens = [];
    let i = 0;
    while (i < s.length) {
        const c = s[i];
        if (/\s/.test(c)) { i++; continue; }
        const rest = s.slice(i);
        let m = /^0x[0-9a-f]+|^0b[01]+|^0o[0-7]+/.exec(rest);
        if (m) {
            out.push({ t: "num", v: Number(m[0]) });
            i += m[0].length;
            continue;
        }
        if (/[\d.]/.test(c)) {
            m = /^(\d*)(\.\d+)?/.exec(rest);
            let int = m[1], frac = m[2] || "";
            let j = i + m[0].length;
            if (!int && !frac) return null;
            if (int && !frac && parens[parens.length - 1] !== "fn") {
                let g;
                while ((g = /^,(\d{3})(?!\d)/.exec(s.slice(j)))) { int += g[1]; j += 4; }
                if (int === m[1] && (g = /^,(\d+)/.exec(s.slice(j)))) { frac = "." + g[1]; j += g[0].length; }
                if (!frac && (g = /^\.\d+/.exec(s.slice(j)))) { frac = g[0]; j += g[0].length; }
            }
            const ex = /^e[+-]?\d+/.exec(s.slice(j));
            if (ex) j += ex[0].length;
            out.push({ t: "num", v: Number((int || "0") + frac + (ex ? ex[0] : "")) });
            i = j;
            continue;
        }
        m = /^[a-z_][a-z0-9_]*/.exec(rest);
        if (m) {
            out.push({ t: "id", v: m[0] });
            i += m[0].length;
            continue;
        }
        if (c === "(") parens.push(out.length && out[out.length - 1].t === "id" && FNS[out[out.length - 1].v] ? "fn" : "grp");
        if (c === ")") parens.pop();
        if ("+-*/^%!(),;°".includes(c)) {
            out.push({ t: c === ";" ? "," : c });
            i++;
            continue;
        }
        return null;
    }
    return out;
}

function parse(tokens) {
    let pos = 0;
    let ops = 0;
    const peek = () => tokens[pos];
    const is = (t, v) => pos < tokens.length && tokens[pos].t === t && (v === undefined || tokens[pos].v === v);
    const fail = () => { throw 0; };
    const startsOperand = tk => tk && (tk.t === "num" || tk.t === "(" || (tk.t === "id" && tk.v !== "of" && tk.v !== "mod" && tk.v !== "deg"));

    function expr() {
        let [v] = term();
        while (is("+") || is("-")) {
            const sub = tokens[pos++].t === "-";
            const [r, pct] = term();
            ops++;
            if (pct) v = v * (sub ? 1 - r : 1 + r);
            else v = sub ? v - r : v + r;
        }
        return v;
    }

    function term() {
        let [v, pct] = juxt();
        for (;;) {
            if (is("*") || is("/")) {
                const div = tokens[pos++].t === "/";
                const [r] = juxt();
                v = div ? v / r : v * r;
            } else if (is("%") || is("id", "mod")) {
                pos++;
                const [r] = juxt();
                v = v % r;
            } else if (is("id", "of") && pct) {
                pos++;
                const [r] = juxt();
                v = v * r;
            } else break;
            ops++;
            pct = false;
        }
        return [v, pct];
    }

    function juxt() {
        let [v, pct] = unary();
        while (startsOperand(peek()) && !(peek().t === "num" && tokens[pos - 1].t === "num")) {
            const [r] = unary();
            v *= r;
            ops++;
            pct = false;
        }
        return [v, pct];
    }

    function unary() {
        if (is("-") || is("+")) {
            const neg = tokens[pos++].t === "-";
            const [v, pct] = unary();
            return [neg ? -v : v, pct];
        }
        return power();
    }

    function power() {
        let [v, pct] = postfix();
        if (is("^")) {
            pos++;
            const [r] = unary();
            ops++;
            return [Math.pow(v, r), false];
        }
        return [v, pct];
    }

    function postfix() {
        let v = primary();
        let pct = false;
        for (;;) {
            if (is("!")) v = factorial(v);
            else if (is("°") || is("id", "deg")) v *= RAD;
            else if (is("%") && !startsOperand(tokens[pos + 1])) { v /= 100; pct = true; }
            else break;
            pos++;
            ops++;
        }
        return [v, pct];
    }

    function primary() {
        const tk = tokens[pos++];
        if (!tk) fail();
        if (tk.t === "num") return tk.v;
        if (tk.t === "(") {
            const v = expr();
            if (is(")")) pos++;
            else if (pos < tokens.length) fail();
            return v;
        }
        if (tk.t === "id") {
            if (CONSTS[tk.v] !== undefined) return CONSTS[tk.v];
            const fn = FNS[tk.v];
            if (!fn) fail();
            ops++;
            if (is("(")) {
                pos++;
                const args = [expr()];
                while (is(",")) { pos++; args.push(expr()); }
                if (is(")")) pos++;
                else if (pos < tokens.length) fail();
                return fn.apply(null, args);
            }
            return fn(unary()[0]);
        }
        fail();
    }

    try {
        const v = expr();
        if (pos !== tokens.length) return null;
        return { value: v, ops };
    } catch (_) {
        return null;
    }
}

function evaluate(src) {
    const toks = tokenize(src);
    if (!toks || !toks.length) return null;
    const r = parse(toks);
    if (!r || !isFinite(r.value)) return null;
    return r;
}

function evalAmount(src) {
    const r = evaluate(src);
    return r ? r.value : null;
}

function format(n) {
    if (Object.is(n, -0)) return "0";
    if (Number.isSafeInteger(n)) return String(n);
    return String(Number(n.toPrecision(12)));
}

// [display label, dimension, factor to base, ...lowercase aliases]
const UNITS = [
    ["kg", "mass", 1000, "kilogram", "kilograms", "kilo", "kilos", "kgs"],
    ["g", "mass", 1, "gram", "grams", "gr"],
    ["mg", "mass", 0.001, "milligram", "milligrams"],
    ["lb", "mass", 453.59237, "lbs", "pound", "pounds"],
    ["oz", "mass", 28.349523125, "ounce", "ounces"],
    ["t", "mass", 1e6, "tonne", "tonnes", "ton", "tons"],
    ["st", "mass", 6350.29318, "stone", "stones"],
    ["km", "length", 1000, "kilometer", "kilometers", "kilometre", "kilometres", "kms"],
    ["m", "length", 1, "meter", "meters", "metre", "metres"],
    ["cm", "length", 0.01, "centimeter", "centimeters", "centimetre", "centimetres"],
    ["mm", "length", 0.001, "millimeter", "millimeters", "millimetre", "millimetres"],
    ["µm", "length", 1e-6, "um", "μm", "micrometer", "micrometers", "micron", "microns"],
    ["nm", "length", 1e-9, "nanometer", "nanometers", "nanometre", "nanometres"],
    ["mi", "length", 1609.344, "mile", "miles"],
    ["yd", "length", 0.9144, "yard", "yards", "yds"],
    ["ft", "length", 0.3048, "foot", "feet"],
    ["in", "length", 0.0254, "inch", "inches"],
    ["nmi", "length", 1852, "nautical mile", "nautical miles"],
    ["L", "volume", 1000, "l", "liter", "liters", "litre", "litres"],
    ["mL", "volume", 1, "ml", "milliliter", "milliliters", "millilitre", "millilitres"],
    ["gal", "volume", 3785.411784, "gallon", "gallons"],
    ["qt", "volume", 946.352946, "quart", "quarts"],
    ["pt", "volume", 473.176473, "pint", "pints"],
    ["fl oz", "volume", 29.5735295625, "floz", "fluid ounce", "fluid ounces"],
    ["cup", "volume", 236.5882365, "cups"],
    ["tbsp", "volume", 14.78676478125, "tablespoon", "tablespoons"],
    ["tsp", "volume", 4.92892159375, "teaspoon", "teaspoons"],
    ["km/h", "speed", 1 / 3.6, "kph", "kmh", "kmph"],
    ["mph", "speed", 0.44704],
    ["m/s", "speed", 1, "mps"],
    ["kn", "speed", 0.514444444, "kt", "kts", "knot", "knots"],
    ["ft/s", "speed", 0.3048, "fps"],
    ["ms", "time", 0.001, "millisecond", "milliseconds"],
    ["s", "time", 1, "sec", "secs", "second", "seconds"],
    ["min", "time", 60, "mins", "minute", "minutes"],
    ["h", "time", 3600, "hr", "hrs", "hour", "hours"],
    ["d", "time", 86400, "day", "days"],
    ["wk", "time", 604800, "week", "weeks"],
    ["yr", "time", 31557600, "year", "years"],
    ["B", "data", 1, "b", "byte", "bytes"],
    ["KB", "data", 1e3, "kb", "kilobyte", "kilobytes"],
    ["MB", "data", 1e6, "mb", "megabyte", "megabytes"],
    ["GB", "data", 1e9, "gb", "gigabyte", "gigabytes"],
    ["TB", "data", 1e12, "tb", "terabyte", "terabytes"],
    ["KiB", "data", 1024, "kib"],
    ["MiB", "data", 1048576, "mib"],
    ["GiB", "data", 1073741824, "gib"],
    ["TiB", "data", 1099511627776, "tib"]
];

const TEMPS = {
    c: "C", "°c": "C", degc: "C", celsius: "C",
    f: "F", "°f": "F", degf: "F", fahrenheit: "F",
    k: "K", kelvin: "K", kelvins: "K"
};

const UNIT_INDEX = (() => {
    const idx = {};
    for (const [label, dim, factor, ...aliases] of UNITS) {
        const info = { label, dim, factor };
        idx[label.toLowerCase()] = info;
        for (const a of aliases) idx[a] = info;
    }
    return idx;
})();

function resolveUnit(raw) {
    const s = raw.trim().toLowerCase().replace(/\s+/g, " ").replace(/^(?:degrees?|deg)\s+/, "°");
    if (TEMPS[s]) return { temp: TEMPS[s], label: "°" + TEMPS[s] };
    return UNIT_INDEX[s] || UNIT_INDEX[s.replace(/ /g, "")] || null;
}

function toKelvin(v, u) { return u === "C" ? v + 273.15 : u === "F" ? (v - 32) * 5 / 9 + 273.15 : v; }
function fromKelvin(v, u) { return u === "C" ? v - 273.15 : u === "F" ? (v - 273.15) * 9 / 5 + 32 : v; }

const CONV_RE = /^(.*\S)\s+(?:to|in|as|into|=)\s+(.+)$/i;
const UNIT_TAIL_2 = /^(.*?)\s*((?:°\s*)?[a-zµμ°][a-zµμ\/]*(?:\s+[a-z][a-z\/]*)?)$/i;
const UNIT_TAIL_1 = /^(.*?)\s*((?:°\s*)?[a-zµμ°][a-zµμ\/]*)$/i;

function splitAmountUnit(lhs, resolve) {
    for (const re of [UNIT_TAIL_2, UNIT_TAIL_1]) {
        const m = re.exec(lhs.trim());
        if (!m || !m[1]) continue;
        const unit = resolve(m[2]);
        const amt = unit && evalAmount(m[1]);
        if (amt !== null && unit) return { amt, unit };
    }
    return null;
}

function parseUnit(q) {
    const m = CONV_RE.exec(q.trim());
    if (!m) return null;
    const to = resolveUnit(m[2]);
    if (!to) return null;
    const from = splitAmountUnit(m[1], resolveUnit);
    if (!from) return null;
    const f = from.unit;
    if (!!f.temp !== !!to.temp || (!f.temp && f.dim !== to.dim)) return null;
    const value = f.temp
        ? fromKelvin(toKelvin(from.amt, f.temp), to.temp)
        : from.amt * f.factor / to.factor;
    return { amt: from.amt, fromLabel: f.label, toLabel: to.label, value };
}

const CURRENCIES = ["AUD", "BRL", "CAD", "CHF", "CNY", "CZK", "DKK", "EUR", "GBP", "HKD", "HUF", "IDR", "ILS", "INR", "ISK",
    "JPY", "KRW", "MXN", "MYR", "NOK", "NZD", "PHP", "PLN", "RON", "SEK", "SGD", "THB", "TRY", "USD", "ZAR"];
const CURRENCY_SYMBOLS = { "€": "EUR", "$": "USD", "£": "GBP", "¥": "JPY", "₹": "INR", "₩": "KRW", "₪": "ILS", "₺": "TRY", "฿": "THB", "zł": "PLN" };
const CURRENCY_NAMES = { dollar: "USD", dollars: "USD", euro: "EUR", euros: "EUR", yen: "JPY", yuan: "CNY", rupee: "INR", rupees: "INR" };
const NO_DECIMALS = ["JPY", "KRW", "IDR", "HUF", "ISK"];

function resolveCurrency(raw) {
    const s = raw.trim();
    if (CURRENCY_SYMBOLS[s]) return CURRENCY_SYMBOLS[s];
    const l = s.toLowerCase();
    if (CURRENCY_NAMES[l]) return CURRENCY_NAMES[l];
    const u = s.toUpperCase();
    return CURRENCIES.includes(u) ? u : null;
}

function parseCurrency(q) {
    const m = CONV_RE.exec(q.trim());
    if (!m) return null;
    const to = resolveCurrency(m[2]);
    if (!to) return null;
    let lhs = m[1].trim();
    for (const sym of Object.keys(CURRENCY_SYMBOLS)) {
        let amtSrc = null;
        if (lhs.startsWith(sym)) amtSrc = lhs.slice(sym.length);
        else if (lhs.endsWith(sym)) amtSrc = lhs.slice(0, -sym.length);
        if (amtSrc === null) continue;
        const amt = evalAmount(amtSrc);
        return amt === null || amt < 0 ? null : { amt, from: CURRENCY_SYMBOLS[sym], to };
    }
    const m2 = /^(.*?)\s*([a-z]+)$/i.exec(lhs);
    if (!m2 || !m2[1]) return null;
    const from = resolveCurrency(m2[2]);
    const amt = from && evalAmount(m2[1]);
    return from && amt !== null && amt >= 0 ? { amt, from, to } : null;
}

function formatCurrency(amt, code) {
    if (NO_DECIMALS.includes(code)) return String(Math.round(amt));
    return (Math.round(amt * 100) / 100).toFixed(2);
}

const _rateCache = {};
const RATE_TTL_MS = 3600000;

function cachedRate(from, to) {
    if (from === to) return { rate: 1, date: "" };
    const c = _rateCache[from + ">" + to];
    return c && Date.now() - c.at < RATE_TTL_MS ? c : null;
}

function storeRate(from, to, rate, date) {
    _rateCache[from + ">" + to] = { rate, date, at: Date.now() };
}

function rateUrl(from, to) {
    return "https://api.frankfurter.dev/v1/latest?base=" + from + "&symbols=" + to;
}

const DATE_LIKE = /^\d{4}-\d{1,2}-\d{1,2}$|^\d{1,2}[\/.-]\d{1,2}[\/.-]\d{2,4}$/;

function classify(q) {
    const s = q.trim();
    if (s === "") return null;
    const curr = parseCurrency(s);
    if (curr) return { type: "currency", parsed: curr };
    const unit = parseUnit(s);
    if (unit) return { type: "unit", parsed: unit };
    if (DATE_LIKE.test(s)) return null;
    const r = evaluate(s);
    if (r && r.ops > 0) return { type: "math", value: r.value };
    return null;
}
