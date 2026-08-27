.pragma library

function shQuote(str) {
    return "'" + String(str).replace(/'/g, "'\\''") + "'";
}
