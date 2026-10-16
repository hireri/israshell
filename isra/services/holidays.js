.pragma library

function easter(y) {
    var a = y % 19, b = Math.floor(y / 100), c = y % 100;
    var d = Math.floor(b / 4), e = b % 4, f = Math.floor((b + 8) / 25);
    var g = Math.floor((b - f + 1) / 3);
    var h = (19 * a + b - d - g + 15) % 30;
    var i = Math.floor(c / 4), k = c % 4;
    var l = (32 + 2 * e + 2 * i - h - k) % 7;
    var m = Math.floor((a + 11 * h + 22 * l) / 451);
    var mo = Math.floor((h + l - 7 * m + 114) / 31);
    return new Date(y, mo - 1, ((h + l - 7 * m + 114) % 31) + 1);
}

function fixed(m, d, name) {
    return function (y) { return {name: name, date: new Date(y, m - 1, d)}; };
}

function nth(dow, n, m, name) {
    return function (y) {
        var first = new Date(y, m - 1, 1);
        return {name: name, date: new Date(y, m - 1, 1 + ((dow - first.getDay() + 7) % 7) + (n - 1) * 7)};
    };
}

function last(dow, m, name) {
    return function (y) {
        var end = new Date(y, m, 0);
        return {name: name, date: new Date(y, m - 1, end.getDate() - ((end.getDay() - dow + 7) % 7))};
    };
}

function easterOff(n, name) {
    return function (y) {
        var e = easter(y);
        return {name: name, date: new Date(y, e.getMonth(), e.getDate() + n)};
    };
}

function mondayBefore(m, d, name) {
    return function (y) {
        var n = (new Date(y, m - 1, d).getDay() + 6) % 7 || 7;
        return {name: name, date: new Date(y, m - 1, d - n)};
    };
}

var newYear = fixed(1, 1, "New Year's Day");
var goodFriday = easterOff(-2, "Good Friday");
var easterMonday = easterOff(1, "Easter Monday");
var christmas = fixed(12, 25, "Christmas Day");
var boxing = fixed(12, 26, "Boxing Day");
var labour = fixed(5, 1, "Labour Day");
var ascension = easterOff(39, "Ascension Day");
var whitMonday = easterOff(50, "Whit Monday");

var regions = {
    US: {name: "United States", rules: [newYear, nth(1, 3, 1, "Martin Luther King Jr. Day"), nth(1, 3, 2, "Presidents' Day"), last(1, 5, "Memorial Day"), fixed(6, 19, "Juneteenth"), fixed(7, 4, "Independence Day"), nth(1, 1, 9, "Labor Day"), nth(1, 2, 10, "Columbus Day"), fixed(11, 11, "Veterans Day"), nth(4, 4, 11, "Thanksgiving"), christmas]},
    GB: {name: "United Kingdom", rules: [newYear, goodFriday, easterMonday, nth(1, 1, 5, "Early May Bank Holiday"), last(1, 5, "Spring Bank Holiday"), last(1, 8, "Summer Bank Holiday"), christmas, boxing]},
    CA: {name: "Canada", rules: [newYear, goodFriday, mondayBefore(5, 25, "Victoria Day"), fixed(7, 1, "Canada Day"), nth(1, 1, 9, "Labour Day"), fixed(9, 30, "Truth and Reconciliation Day"), nth(1, 2, 10, "Thanksgiving"), fixed(11, 11, "Remembrance Day"), christmas, boxing]},
    AU: {name: "Australia", rules: [newYear, fixed(1, 26, "Australia Day"), goodFriday, easterMonday, fixed(4, 25, "Anzac Day"), christmas, boxing]},
    DE: {name: "Germany", rules: [newYear, goodFriday, easterMonday, labour, ascension, whitMonday, fixed(10, 3, "German Unity Day"), christmas, boxing]},
    FR: {name: "France", rules: [newYear, easterMonday, labour, fixed(5, 8, "Victory Day"), ascension, whitMonday, fixed(7, 14, "Bastille Day"), fixed(8, 15, "Assumption Day"), fixed(11, 1, "All Saints' Day"), fixed(11, 11, "Armistice Day"), christmas]}
};

function regionFor(language) {
    var cc = String(language || "").split("_")[1];
    return cc && regions[cc.toUpperCase()] ? cc.toUpperCase() : "";
}

function between(region, fromMs, toMs) {
    var r = regions[region];
    var out = [];
    if (!r) return out;
    for (var y = new Date(fromMs).getFullYear(); y <= new Date(toMs).getFullYear(); y++) {
        r.rules.forEach(function (rule) {
            var h = rule(y);
            var s = h.date.getTime();
            var e = new Date(h.date.getFullYear(), h.date.getMonth(), h.date.getDate() + 1).getTime();
            if (s < toMs && e > fromMs)
                out.push({uid: "holiday-" + region + "-" + y + "-" + h.name, calendar: "holidays", title: h.name, location: "", description: "", url: "", link: "", start: s, end: e, allDay: true, reminder: -1, urgent: false, recurring: false, seriesStart: s, readOnly: true});
        });
    }
    return out;
}
