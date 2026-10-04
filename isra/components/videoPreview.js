.pragma library

var maxActive = 2;
var active = 0;
var pending = [];

function request(start) {
    if (active < maxActive) {
        active++;
        start();
    } else {
        pending.push(start);
    }
}

function release() {
    active--;
    if (pending.length > 0) {
        active++;
        pending.shift()();
    }
}

function formatDuration(seconds) {
    const s = Math.round(seconds ?? 0);
    if (!s || s <= 0)
        return "";
    const h = Math.floor(s / 3600);
    const m = Math.floor((s % 3600) / 60);
    const sec = s % 60;
    const mm = h > 0 ? String(m).padStart(2, "0") : String(m);
    const ss = String(sec).padStart(2, "0");
    return h > 0 ? h + ":" + mm + ":" + ss : mm + ":" + ss;
}
