const assert = require("assert");
const fs = require("fs");
const path = require("path");

const src = fs.readFileSync(path.join(__dirname, "calc.js"), "utf8").replace(/^\.pragma library[^\n]*\n/, "");
const C = new Function(src + "; return {evaluate, format, parseUnit, parseCurrency, classify, cachedRate};")();

const ev = q => { const r = C.evaluate(q); return r ? C.format(r.value) : null; };
const cases = {
    "1+2": "3", "2^3^2": "512", "-2^2": "-4", "2^-1": "0.5", "0.1+0.2": "0.3",
    "1,5+2": "3.5", "1,000+1": "1001", "1,000.50*2": "2001",
    "2(3)": "6", "(1+2)(3)": "9", "(1+2)3": "9", "2pi": "6.28318530718", "1/2pi": "0.159154943092",
    "1e3+1": "1001", "2e": "5.43656365692", ".5*2": "1",
    "sqrt 16": "4", "sqrt(16": "4", "√16": "4", "3²": "9", "2 × 3": "6", "6 ÷ 2": "3", "2**10": "1024",
    "sin(pi)": "0", "cos(pi/2)": "0", "tan(pi/4)": "1", "sind(30)": "0.5", "sin(30°)": "0.5",
    "50% of 200": "100", "100+10%": "110", "100-10%": "90", "10%*3": "0.3", "10%3": "1", "10 mod 3": "1",
    "5!": "120", "2^3!": "64", "-(2)^2": "-4", "-sqrt(4)^2": "-4",
    "log(100)": "2", "log(8, 2)": "3", "log2(8)": "3", "ln(e)": "1", "atan2(1,1)": "0.785398163397",
    "max(1,2,3)": "3", "0x1f+1": "32", "tau/2": "3.14159265359", "1/3": "0.333333333333",
    "2^52": "4503599627370496", "1/0": null, "2 3": null, "foo+1": null, "1.2.3": null, "": null,
};
for (const [q, want] of Object.entries(cases)) assert.strictEqual(ev(q), want, q);

const unit = q => { const u = C.parseUnit(q); return u && C.format(u.value) + " " + u.toLabel; };
assert.strictEqual(unit("5 nm to m"), "5e-9 m");
assert.strictEqual(unit("1 kb to b"), "1000 B");
assert.strictEqual(unit("1 gib to mib"), "1024 MiB");
assert.strictEqual(unit("1/2 cup to ml"), "118.29411825 mL");
assert.strictEqual(unit("2*3 km to m"), "6000 m");
assert.strictEqual(unit("-40 c to f"), "-40 °F");
assert.strictEqual(unit("30°c to f"), "86 °F");
assert.strictEqual(unit("100 degrees f in c"), "37.7777777778 °C");
assert.strictEqual(unit("5 fl oz to ml"), "147.867647812 mL");
assert.strictEqual(unit("5 in to cm"), "12.7 cm");
assert.strictEqual(unit("3 in in cm"), "7.62 cm");
assert.strictEqual(unit("5km in mi"), "3.10685596119 mi");
assert.strictEqual(unit("90 min to h"), "1.5 h");
assert.strictEqual(unit("100 km/h to mph"), "62.1371192237 mph");
assert.strictEqual(unit("5 kg to m"), null);
assert.strictEqual(unit("5 kg to c"), null);

const cur = q => { const c = C.parseCurrency(q); return c && `${c.amt} ${c.from}>${c.to}`; };
assert.strictEqual(cur("€5 to usd"), "5 EUR>USD");
assert.strictEqual(cur("5€ to usd"), "5 EUR>USD");
assert.strictEqual(cur("$1,000.50 in eur"), "1000.5 USD>EUR");
assert.strictEqual(cur("1,000.50 usd to eur"), "1000.5 USD>EUR");
assert.strictEqual(cur("10 dollars to yen"), "10 USD>JPY");
assert.strictEqual(cur("2*50 gbp to usd"), "100 GBP>USD");
assert.strictEqual(cur("5 usd to rub"), null);
assert.strictEqual(C.cachedRate("USD", "USD").rate, 1);

const kind = q => { const c = C.classify(q); return c && c.type; };
assert.strictEqual(kind("2024-10-18"), null);
assert.strictEqual(kind("18/10/2024"), null);
assert.strictEqual(kind("hello-world 2"), null);
assert.strictEqual(kind("pi"), null);
assert.strictEqual(kind("42"), null);
assert.strictEqual(kind("-5"), null);
assert.strictEqual(kind("firefox"), null);
assert.strictEqual(kind("2+2"), "math");
assert.strictEqual(kind("5 m to ft"), "unit");
assert.strictEqual(kind("5 usd to eur"), "currency");

console.log("calc ok");
