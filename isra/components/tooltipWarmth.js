.pragma library

var showing = 0;
var lastActive = 0;
var grace = 300;

function warm() {
    return showing > 0 || Date.now() - lastActive < grace;
}

function shownChanged(on) {
    showing += on ? 1 : -1;
    lastActive = Date.now();
}
