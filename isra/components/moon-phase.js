.pragma library

var SYNODIC = 29.530588853;
var EPOCH_MS = Date.UTC(2000, 0, 6, 18, 14, 0);

function moonAge(date) {
    var age = ((date.getTime() - EPOCH_MS) / 86400000) % SYNODIC;
    return age < 0 ? age + SYNODIC : age;
}

function phaseFraction(date) {
    return moonAge(date) / SYNODIC;
}

function illumination(date) {
    return (1 - Math.cos(2 * Math.PI * phaseFraction(date))) / 2;
}

function waxing(date) {
    return phaseFraction(date) < 0.5;
}

function phaseKey(date) {
    var i = Math.floor(phaseFraction(date) * 8 + 0.5) % 8;
    switch (i) {
        case 0:
            return "new_moon";
        case 1:
            return "waxing_crescent";
        case 2:
            return "first_quarter";
        case 3:
            return "waxing_gibbous";
        case 4:
            return "full_moon";
        case 5:
            return "waning_gibbous";
        case 6:
            return "last_quarter";
        default:
            return "waning_crescent";
    }
}