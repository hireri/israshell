const fs = require("fs");
const src = fs.readFileSync(__dirname + "/treemap.js", "utf8").replace(".pragma library", "");
const TM = new Function(src + "; return { merge, items, layout, store, stored };")();
const assert = require("assert");

const du = ["10\t/h/a/x", "30\t/h/a", "5\t/h/b", "60\t/h/c/y/z", "70\t/h/c/y", "80\t/h/c", "130\t/h"].join("\n");
const nodes = TM.merge({}, du, "/h");
assert.deepStrictEqual(nodes["/h"].kids.sort(), ["/h/a", "/h/b", "/h/c"]);
assert.strictEqual(nodes["/h"].scanned, true);
assert.strictEqual(nodes["/h/c/y/z"].scanned, false);

const list = TM.items(nodes, "/h");
assert.deepStrictEqual(list.map(i => i.name), ["c", "a", "b", ""]);
assert.strictEqual(list[3].size, 130 - 115);

const rects = TM.layout(list, 400, 200);
const area = rects.reduce((a, r) => a + r.w * r.h, 0);
assert(Math.abs(area - 400 * 200) < 1e-6);
for (const r of rects) assert(r.x >= -1e-9 && r.y >= -1e-9 && r.x + r.w <= 400 + 1e-6 && r.y + r.h <= 200 + 1e-6);

const again = TM.merge(nodes, "20\t/h/c/y/z/q\n60\t/h/c/y/z", "/h/c/y/z");
assert.strictEqual(again["/h/c/y/z"].scanned, true);
assert.deepStrictEqual(again["/h/c/y/z"].kids, ["/h/c/y/z/q"]);
TM.store(again);
assert.strictEqual(TM.stored().nodes, again);
console.log("treemap ok");
