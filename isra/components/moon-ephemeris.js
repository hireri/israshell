.pragma library

var PI = Math.PI;
var sin = Math.sin, cos = Math.cos, tan = Math.tan, asin = Math.asin, atan = Math.atan2;
var rad = PI / 180;

var dayMs = 1000 * 60 * 60 * 24;
var J1970 = 2440588;
var J2000 = 2451545;

function toJulian(date) {
    return date.valueOf() / dayMs - 0.5 + J1970;
}

function toDays(date) {
    return toJulian(date) - J2000;
}

var e = rad * 23.4397;

function rightAscension(l, b) {
    return atan(sin(l) * cos(e) - tan(b) * sin(e), cos(l));
}

function declination(l, b) {
    return asin(sin(b) * cos(e) + cos(b) * sin(e) * sin(l));
}

function altitude(H, phi, dec) {
    return asin(sin(phi) * sin(dec) + cos(phi) * cos(dec) * cos(H));
}

function siderealTime(d, lw) {
    return rad * (280.16 + 360.9856235 * d) - lw;
}

function astroRefraction(h) {
    if (h < 0)
        h = 0;
    return 0.0002967 / Math.tan(h + 0.00312536 / (h + 0.08901179));
}

function moonCoords(d) {
    var L = rad * (218.316 + 13.176396 * d);
    var M = rad * (134.963 + 13.064993 * d);
    var F = rad * (93.272 + 13.229350 * d);

    var l = L + rad * 6.289 * sin(M);
    var b = rad * 5.128 * sin(F);

    return {
        ra: rightAscension(l, b),
        dec: declination(l, b)
    };
}

function moonAltitude(date, lat, lng) {
    var lw = rad * -lng;
    var phi = rad * lat;
    var d = toDays(date);
    var c = moonCoords(d);
    var H = siderealTime(d, lw) - c.ra;
    var h = altitude(H, phi, c.dec);
    return h + astroRefraction(h);
}

function hoursLater(date, h) {
    return new Date(date.valueOf() + h * dayMs / 24);
}

function getMoonTimes(date, lat, lng) {
    var t = new Date(date);
    t.setHours(0, 0, 0, 0);

    var hc = 0.133 * rad;
    var h0 = moonAltitude(t, lat, lng) - hc;
    var h1, h2, rise, set, a, b, xe, ye, d, roots, x1, x2, dx;

    for (var i = 1; i <= 24; i += 2) {
        h1 = moonAltitude(hoursLater(t, i), lat, lng) - hc;
        h2 = moonAltitude(hoursLater(t, i + 1), lat, lng) - hc;

        a = (h0 + h2) / 2 - h1;
        b = (h2 - h0) / 2;
        xe = -b / (2 * a);
        ye = (a * xe + b) * xe + h1;
        d = b * b - 4 * a * h1;
        roots = 0;

        if (d >= 0) {
            dx = Math.sqrt(d) / (Math.abs(a) * 2);
            x1 = xe - dx;
            x2 = xe + dx;
            if (Math.abs(x1) <= 1)
                roots++;
            if (Math.abs(x2) <= 1)
                roots++;
            if (x1 < -1)
                x1 = x2;
        }

        if (roots === 1) {
            if (h0 < 0)
                rise = i + x1;
            else
                set = i + x1;
        } else if (roots === 2) {
            rise = i + (ye < 0 ? x2 : x1);
            set = i + (ye < 0 ? x1 : x2);
        }

        if (rise && set)
            break;

        h0 = h2;
    }

    var result = {};
    if (rise)
        result.rise = hoursLater(t, rise);
    if (set)
        result.set = hoursLater(t, set);
    if (!rise && !set)
        result[ye > 0 ? "alwaysUp" : "alwaysDown"] = true;

    return result;
}
