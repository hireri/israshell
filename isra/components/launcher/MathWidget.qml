import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.style

Item {
    id: root

    property string query: ""
    signal copyResult(string result)
    signal swapRequested(string newQuery)

    readonly property bool hasResult: _cls !== "empty" && _cls !== "unknown"

    property string _cls: "empty"
    property var _parsed: null

    property bool _loading: false
    property string _result: ""
    property string _resultUnit: ""
    property string _parsedExpr: ""

    property string _currFrom: ""
    property string _currTo: ""
    property real _currFromAmt: 0
    property real _currRate: 0
    property real _currRawResult: 0
    property string _currDate: ""
    property bool _currError: false
    property var _activeXhr: null

    implicitHeight: _cls === "currency" ? currencyLayout.implicitHeight : mathLayout.implicitHeight

    readonly property var _currencyCodes: ["usd", "eur", "gbp", "jpy", "cad", "aud", "chf", "cny", "inr", "rub", "krw", "brl", "mxn", "sgd", "hkd", "nok", "sek", "dkk", "pln", "czk", "ils", "try", "zar", "aed", "thb", "idr", "myr", "php", "vnd", "clp"]

    readonly property var _symbolToCode: ({
        "€": "EUR", "$": "USD", "£": "GBP", "¥": "JPY",
        "₹": "INR", "₽": "RUB", "₩": "KRW", "₪": "ILS"
    })

    readonly property var _codeToSymbol: ({
        "USD": "$",  "EUR": "€",    "GBP": "£",  "JPY": "¥",
        "INR": "₹",  "RUB": "₽",   "KRW": "₩",  "ILS": "₪",
        "CAD": "C$", "AUD": "A$",  "CHF": "Fr", "CNY": "¥",
        "BRL": "R$", "MXN": "$",   "SGD": "S$", "HKD": "HK$",
        "NOK": "kr", "SEK": "kr",  "DKK": "kr", "PLN": "zł",
        "CZK": "Kč", "TRY": "₺",  "ZAR": "R",  "AED": "د.إ",
        "THB": "฿"
    })

    readonly property var _noDecimalCodes: ["JPY", "KRW", "VND", "CLP", "IDR"]

    readonly property var _unitAliases: ({
        "kg": { base: "mass", factor: 1000 },
        "kilo": { base: "mass", factor: 1000 },
        "kilos": { base: "mass", factor: 1000 },
        "kilograms": { base: "mass", factor: 1000 },
        "kilogram": { base: "mass", factor: 1000 },
        "g": { base: "mass", factor: 1 },
        "gram": { base: "mass", factor: 1 },
        "grams": { base: "mass", factor: 1 },
        "mg": { base: "mass", factor: 0.001 },
        "milligram": { base: "mass", factor: 0.001 },
        "milligrams": { base: "mass", factor: 0.001 },
        "lb": { base: "mass", factor: 453.592 },
        "lbs": { base: "mass", factor: 453.592 },
        "pound": { base: "mass", factor: 453.592 },
        "pounds": { base: "mass", factor: 453.592 },
        "oz": { base: "mass", factor: 28.3495 },
        "ounce": { base: "mass", factor: 28.3495 },
        "ounces": { base: "mass", factor: 28.3495 },
        "t": { base: "mass", factor: 1000000 },
        "tonne": { base: "mass", factor: 1000000 },
        "tonnes": { base: "mass", factor: 1000000 },
        "ton": { base: "mass", factor: 1000000 },
        "tons": { base: "mass", factor: 1000000 },
        "stone": { base: "mass", factor: 6350.29 },
        "stones": { base: "mass", factor: 6350.29 },
        "st": { base: "mass", factor: 6350.29 },

        "km": { base: "length", factor: 1000 },
        "kilometer": { base: "length", factor: 1000 },
        "kilometers": { base: "length", factor: 1000 },
        "kilometre": { base: "length", factor: 1000 },
        "kilometres": { base: "length", factor: 1000 },
        "m": { base: "length", factor: 1 },
        "meter": { base: "length", factor: 1 },
        "meters": { base: "length", factor: 1 },
        "metre": { base: "length", factor: 1 },
        "metres": { base: "length", factor: 1 },
        "cm": { base: "length", factor: 0.01 },
        "centimeter": { base: "length", factor: 0.01 },
        "centimeters": { base: "length", factor: 0.01 },
        "centimetre": { base: "length", factor: 0.01 },
        "centimetres": { base: "length", factor: 0.01 },
        "mm": { base: "length", factor: 0.001 },
        "millimeter": { base: "length", factor: 0.001 },
        "millimeters": { base: "length", factor: 0.001 },
        "millimetre": { base: "length", factor: 0.001 },
        "millimetres": { base: "length", factor: 0.001 },
        "mi": { base: "length", factor: 1609.344 },
        "mile": { base: "length", factor: 1609.344 },
        "miles": { base: "length", factor: 1609.344 },
        "ft": { base: "length", factor: 0.3048 },
        "foot": { base: "length", factor: 0.3048 },
        "feet": { base: "length", factor: 0.3048 },
        "in": { base: "length", factor: 0.0254 },
        "inch": { base: "length", factor: 0.0254 },
        "inches": { base: "length", factor: 0.0254 },
        "yd": { base: "length", factor: 0.9144 },
        "yard": { base: "length", factor: 0.9144 },
        "yards": { base: "length", factor: 0.9144 },
        "nm": { base: "length", factor: 1852 },
        "nauticalmile": { base: "length", factor: 1852 },
        "nauticalmiles": { base: "length", factor: 1852 },

        "l": { base: "volume", factor: 1000 },
        "liter": { base: "volume", factor: 1000 },
        "liters": { base: "volume", factor: 1000 },
        "litre": { base: "volume", factor: 1000 },
        "litres": { base: "volume", factor: 1000 },
        "ml": { base: "volume", factor: 1 },
        "milliliter": { base: "volume", factor: 1 },
        "milliliters": { base: "volume", factor: 1 },
        "millilitre": { base: "volume", factor: 1 },
        "millilitres": { base: "volume", factor: 1 },
        "gal": { base: "volume", factor: 3785.41 },
        "gallon": { base: "volume", factor: 3785.41 },
        "gallons": { base: "volume", factor: 3785.41 },
        "floz": { base: "volume", factor: 29.5735 },
        "fl oz": { base: "volume", factor: 29.5735 },
        "fluidounce": { base: "volume", factor: 29.5735 },
        "fluidounces": { base: "volume", factor: 29.5735 },
        "cup": { base: "volume", factor: 236.588 },
        "cups": { base: "volume", factor: 236.588 },
        "tbsp": { base: "volume", factor: 14.7868 },
        "tablespoon": { base: "volume", factor: 14.7868 },
        "tablespoons": { base: "volume", factor: 14.7868 },
        "tsp": { base: "volume", factor: 4.92892 },
        "teaspoon": { base: "volume", factor: 4.92892 },
        "teaspoons": { base: "volume", factor: 4.92892 },

        "mph": { base: "speed", factor: 0.44704 },
        "kph": { base: "speed", factor: 0.277778 },
        "kmh": { base: "speed", factor: 0.277778 },
        "km/h": { base: "speed", factor: 0.277778 },
        "m/s": { base: "speed", factor: 1 },
        "mps": { base: "speed", factor: 1 },
        "knot": { base: "speed", factor: 0.514444 },
        "knots": { base: "speed", factor: 0.514444 },
        "kt": { base: "speed", factor: 0.514444 },
        "fps": { base: "speed", factor: 0.3048 },

        "b": { base: "data", factor: 1 },
        "byte": { base: "data", factor: 1 },
        "bytes": { base: "data", factor: 1 },
        "kb": { base: "data", factor: 1024 },
        "kilobyte": { base: "data", factor: 1024 },
        "kilobytes": { base: "data", factor: 1024 },
        "mb": { base: "data", factor: 1048576 },
        "megabyte": { base: "data", factor: 1048576 },
        "megabytes": { base: "data", factor: 1048576 },
        "gb": { base: "data", factor: 1073741824 },
        "gigabyte": { base: "data", factor: 1073741824 },
        "gigabytes": { base: "data", factor: 1073741824 },
        "tb": { base: "data", factor: 1099511627776 },
        "terabyte": { base: "data", factor: 1099511627776 },
        "terabytes": { base: "data", factor: 1099511627776 }
    })

    readonly property var _tempAliases: ({
        "c": "C", "°c": "C", "celsius": "C", "degc": "C",
        "f": "F", "°f": "F", "fahrenheit": "F", "degf": "F",
        "k": "K", "kelvin": "K", "kelvins": "K"
    })

    readonly property var _unitLabels: ({
        "mass":   { "kg": "kg", "g": "g", "mg": "mg", "lb": "lb", "lbs": "lb",
                    "oz": "oz", "t": "t", "tonne": "t", "stone": "st", "st": "st" },
        "length": { "km": "km", "m": "m", "cm": "cm", "mm": "mm",
                    "mi": "mi", "ft": "ft", "in": "in", "yd": "yd", "nm": "nmi" },
        "volume": { "l": "L", "ml": "mL", "gal": "gal", "floz": "fl oz",
                    "fl oz": "fl oz", "cup": "cup", "tbsp": "tbsp", "tsp": "tsp" },
        "speed":  { "mph": "mph", "kph": "km/h", "kmh": "km/h", "km/h": "km/h",
                    "m/s": "m/s", "mps": "m/s", "knot": "kn", "knots": "kn",
                    "kt": "kn", "fps": "fps" },
        "data":   { "b": "B", "kb": "KB", "mb": "MB", "gb": "GB", "tb": "TB" }
    })

    function _normalizeCurrencySymbols(q) {
        let s = q;
        for (const [sym, code] of Object.entries(_symbolToCode)) {
            if (s.startsWith(sym)) {
                s = s.slice(1).trim();
                if (!new RegExp("\\b" + code + "\\b", "i").test(s))
                    s = s.replace(/^([\d.,]+)/, "$1 " + code);
                break;
            }
        }
        const post = /^([\d.,]+)([€\$£¥₹₽₩₪])(\s+(?:to|in)\s+.+)$/i.exec(s);
        if (post) {
            const code = _symbolToCode[post[2]];
            if (code) s = post[1] + " " + code + post[3];
        }
        return s;
    }

    function _parseCurrency(q) {
        const norm = _normalizeCurrencySymbols(q.trim());
        const m = /^([\d.,]+)\s+([a-z]{3})\s+(?:to|in)\s+([a-z]{3})$/i.exec(norm);
        if (!m) return null;
        const amt = parseFloat(m[1].replace(",", "."));
        if (isNaN(amt) || amt < 0) return null;
        const from = m[2].toUpperCase();
        const to   = m[3].toUpperCase();
        if (!_currencyCodes.includes(from.toLowerCase())) return null;
        if (!_currencyCodes.includes(to.toLowerCase())) return null;
        return { amt, from, to };
    }

    function _resolveUnit(raw) {
        const s = raw.trim().toLowerCase();
        const nosp = s.replace(/\s+/g, "");

        if (_tempAliases[s]   !== undefined) return { kind: "temp", unit: _tempAliases[s] };
        if (_tempAliases[nosp] !== undefined) return { kind: "temp", unit: _tempAliases[nosp] };

        if (_unitAliases[s]    !== undefined) return { kind: "unit", unit: s,    info: _unitAliases[s] };
        if (_unitAliases[nosp] !== undefined) return { kind: "unit", unit: nosp, info: _unitAliases[nosp] };

        return null;
    }

    function _parseUnitConversion(q) {
        const m = /^([+-]?[\d.,]+)\s*°?\s*([a-zA-Z][a-zA-Z\/]*(?:\s+[a-zA-Z][a-zA-Z\/]*)?)\s+(?:to|in)\s+°?\s*([a-zA-Z][a-zA-Z\/]*(?:\s+[a-zA-Z][a-zA-Z\/]*)?)$/i.exec(q.trim());
        if (!m) return null;

        const amt  = parseFloat(m[1].replace(",", "."));
        if (isNaN(amt)) return null;

        const fromResolved = _resolveUnit(m[2]);
        const toResolved   = _resolveUnit(m[3]);
        if (!fromResolved || !toResolved) return null;

        if (fromResolved.kind === "temp" && toResolved.kind === "temp")
            return { amt, fromRaw: m[2].trim(), toRaw: m[3].trim(), fromResolved, toResolved };

        if (fromResolved.kind === "unit" && toResolved.kind === "unit"
            && fromResolved.info.base === toResolved.info.base)
            return { amt, fromRaw: m[2].trim(), toRaw: m[3].trim(), fromResolved, toResolved };

        return null;
    }

    function _computeUnitConversion(parsed) {
        const { amt, fromResolved, toResolved } = parsed;

        if (fromResolved.kind === "temp") {
            const f = fromResolved.unit;
            const t = toResolved.unit;
            let result;
            if      (f === "C" && t === "F") result = amt * 9/5 + 32;
            else if (f === "F" && t === "C") result = (amt - 32) * 5/9;
            else if (f === "C" && t === "K") result = amt + 273.15;
            else if (f === "K" && t === "C") result = amt - 273.15;
            else if (f === "F" && t === "K") result = (amt - 32) * 5/9 + 273.15;
            else if (f === "K" && t === "F") result = (amt - 273.15) * 9/5 + 32;
            else result = amt;
            return result;
        }

        return amt * fromResolved.info.factor / toResolved.info.factor;
    }

    function _labelFor(raw, resolved) {
        if (resolved.kind === "temp") return "°" + resolved.unit;
        const base = resolved.info.base;
        const s = raw.trim().toLowerCase().replace(/\s+/g, "");
        const table = _unitLabels[base];
        return (table && table[s]) ? table[s] : raw.trim();
    }

    function _looksLikeMath(q) {
        const s = q.trim();
        if (s === "") return false;

        const fn = "(?:" + _mathFuncNames + "|pi|e)";
        if (!new RegExp("^(?:[\\d.(+\\-]|" + fn + "\\b)", "i").test(s))
            return false;

        if (/[+\-*\/^%]/.test(s)) return true;
        if (new RegExp("\\b" + fn + "\\s*\\(", "i").test(s)) return true;
        if (new RegExp("\\d\\s*" + fn + "\\b", "i").test(s)) return true;
        if (new RegExp("\\)\\s*" + fn + "\\b", "i").test(s)) return true;
        if (/\d\s*\(|\)\s*\(/.test(s)) return true;
        return false;
    }

    function _classify(q) {
        if (q === "") return { type: "empty", parsed: null };

        const curr = _parseCurrency(q);
        if (curr) return { type: "currency", parsed: curr };

        const unit = _parseUnitConversion(q);
        if (unit) return { type: "unit", parsed: unit };

        if (_looksLikeMath(q)) return { type: "math", parsed: null };

        return { type: "unknown", parsed: null };
    }


    readonly property string _mathFuncNames: "sqrt|cbrt|sin|cos|tan|asin|acos|atan2|atan|sinh|cosh|tanh|asinh|acosh|atanh|log|ln|exp|pow|abs|floor|ceil|round|trunc|min|max|sind|cosd|tand"

    function _evalMath(expr) {
        try {
            let p = expr.replace(/\s+/g, "").toLowerCase();

            p = p.replace(/(\d),(?=\d{3}(?:\D|$))/g, "$1");
            p = p.replace(/(?<![a-z])(\d)\(/g, "$1*(");
            p = p.replace(/\)(\d)/g, ")*$1");
            p = p.replace(/\)\(/g, ")*(");
            p = p.replace(new RegExp("(\\d|\\))(" + _mathFuncNames + "|pi|e)\\(", "g"), "$1*$2(");
            p = p.replace(/(\d|\))(pi|e)\b/g, "$1*$2");

            if (!/^[\d()+\-*\/^%.]+$/.test(
                    p.replace(new RegExp("\\b(?:" + _mathFuncNames + "|pi|e)\\b", "g"), "").replace(/,/g, "")))
                return null;

            p = p.replace(/\bpi\b/g, String(Math.PI)).replace(/\be\b/g, String(Math.E));

            p = p
                .replace(/\bsqrt\(/g,  "Math.sqrt(")
                .replace(/\bcbrt\(/g,  "Math.cbrt(")
                .replace(/\basin\(/g,  "Math.asin(")
                .replace(/\bacos\(/g,  "Math.acos(")
                .replace(/\batan2\(/g, "Math.atan2(")
                .replace(/\batan\(/g,  "Math.atan(")
                .replace(/\basinh\(/g, "Math.asinh(")
                .replace(/\bacosh\(/g, "Math.acosh(")
                .replace(/\batanh\(/g, "Math.atanh(")
                .replace(/\bsinh\(/g,  "Math.sinh(")
                .replace(/\bcosh\(/g,  "Math.cosh(")
                .replace(/\btanh\(/g,  "Math.tanh(")
                .replace(/\bsin\(/g,   "Math.sin(")
                .replace(/\bcos\(/g,   "Math.cos(")
                .replace(/\btan\(/g,   "Math.tan(")
                .replace(/\blog\(/g,   "Math.log10(")
                .replace(/\bln\(/g,    "Math.log(")
                .replace(/\bexp\(/g,   "Math.exp(")
                .replace(/\bpow\(/g,   "Math.pow(")
                .replace(/\babs\(/g,   "Math.abs(")
                .replace(/\bfloor\(/g, "Math.floor(")
                .replace(/\bceil\(/g,  "Math.ceil(")
                .replace(/\bround\(/g, "Math.round(")
                .replace(/\btrunc\(/g, "Math.trunc(")
                .replace(/\bmin\(/g,   "Math.min(")
                .replace(/\bmax\(/g,   "Math.max(")
                .replace(/\bsind\(/g,  "(function(x){return Math.sin(x*" + (Math.PI/180) + ");})(")
                .replace(/\bcosd\(/g,  "(function(x){return Math.cos(x*" + (Math.PI/180) + ");})(")
                .replace(/\btand\(/g,  "(function(x){return Math.tan(x*" + (Math.PI/180) + ");})(");

            p = p.replace(/\^/g, "**");
            p = p.replace(/(^|[+\-(,])-([\d.]+)\*\*/g, "$10-$2**");

            const result = new Function("return " + p)();
            if (!isFinite(result) || isNaN(result)) return null;
            return result;
        } catch (_) {
            return null;
        }
    }

    function _formatNumber(n) {
        if (Number.isInteger(n)) return n.toString();
        if (Math.abs(n) >= 1e15 || (Math.abs(n) < 1e-6 && n !== 0))
            return n.toExponential(6);
        return parseFloat(n.toFixed(10)).toString();
    }

    onQueryChanged: {
        debounce.stop();

        if (_activeXhr) {
            _activeXhr.abort();
            _activeXhr = null;
        }

        _result      = "";
        _resultUnit  = "";
        _parsedExpr  = "";
        _currFrom    = "";
        _currTo      = "";
        _currFromAmt = 0;
        _currRate    = 0;
        _currRawResult = 0;
        _currDate    = "";
        _currError   = false;
        _loading     = false;

        const q = query.trim();
        const c = _classify(q);
        _cls    = c.type;
        _parsed = c.parsed;

        if (_cls === "empty" || _cls === "unknown") return;

        if (_cls === "currency") {
            _currFrom    = c.parsed.from;
            _currTo      = c.parsed.to;
            _currFromAmt = c.parsed.amt;
            _loading = true;
            debounce.restart();
            return;
        }

        if (_cls === "unit") {
            const p = c.parsed;
            const raw = _computeUnitConversion(p);
            _result      = _formatNumber(raw);
            _resultUnit  = _labelFor(p.toRaw, p.toResolved);
            _parsedExpr  = _formatNumber(p.amt) + " " + _labelFor(p.fromRaw, p.fromResolved) + " → " + _labelFor(p.toRaw, p.toResolved);
            return;
        }

        if (_cls === "math") {
            const val = _evalMath(q);
            if (val === null) {
                _cls = "unknown";
                return;
            }
            _result     = _formatNumber(val);
            _resultUnit = "";
            _parsedExpr = "";
            return;
        }
    }

    Timer {
        id: debounce
        interval: 380
        onTriggered: {
            if (root._cls === "currency" && root._parsed)
                root._fetchCurrency(root._parsed);
        }
    }

    function _fetchCurrency(parsed) {
        if (!parsed) { _loading = false; return; }

        const url = "https://api.frankfurter.app/latest?from=" + parsed.from + "&to=" + parsed.to;
        const xhr = new XMLHttpRequest();
        _activeXhr = xhr;

        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (root._activeXhr !== xhr) return;
            root._activeXhr = null;
            root._loading = false;

            if (xhr.status !== 200) { root._currError = true; return; }
            try {
                const data = JSON.parse(xhr.responseText);
                root._currRate     = data.rates[parsed.to] ?? 0;
                root._currDate     = data.date ?? "";
                root._currRawResult = parsed.amt * root._currRate;
                root._result       = root._formatCurrencyAmt(root._currRawResult, parsed.to);
            } catch (_) {
                root._currError = true;
            }
        };

        xhr.open("GET", url);
        xhr.send();
    }

    function _formatCurrencyAmt(amt, code) {
        if (_noDecimalCodes.includes(code))
            return Math.round(amt).toString();
        return (Math.round(amt * 100) / 100).toFixed(2);
    }

    function _symFor(code) {
        return _codeToSymbol[code] ?? "";
    }

    component PillBtn: Rectangle {
        id: pb
        property string label: ""
        property bool primary: true
        signal clicked

        implicitWidth: pbLbl.implicitWidth + 22
        implicitHeight: 30
        radius: height / 2
        color: pbMa.containsMouse ? (primary ? Colors.md3.primary : Colors.md3.secondary_container) : (primary ? Colors.md3.primary_container : Colors.md3.surface_container_high)
        Behavior on color {
            ColorAnimation {
                duration: 90
            }
        }

        Text {
            id: pbLbl
            anchors.centerIn: parent
            text: pb.label
            color: pbMa.containsMouse ? (pb.primary ? Colors.md3.on_primary : Colors.md3.on_secondary_container) : (pb.primary ? Colors.md3.on_primary_container : Colors.md3.on_surface_variant)
            font.pixelSize: 12
            font.family: Config.fontFamily
        }
        MouseArea {
            id: pbMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pb.clicked()
        }
    }

    component Chip: Rectangle {
        property string label: ""
        property bool accent: false

        implicitWidth: chipLbl.implicitWidth + 16
        height: 22
        radius: 11
        color: accent ? Colors.md3.primary_container : Colors.md3.surface_container_high

        Text {
            id: chipLbl
            anchors.centerIn: parent
            text: parent.label
            color: parent.accent ? Colors.md3.on_primary_container : Colors.md3.on_surface_variant
            font.pixelSize: 11
            font.family: Config.fontFamily
            font.letterSpacing: 0.5
        }
    }

    ColumnLayout {
        id: mathLayout
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        visible: root._cls !== "currency"
        spacing: 8

        Chip {
            visible: root._parsedExpr !== ""
            label: root._parsedExpr
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Rectangle {
                width: 6
                height: 6
                radius: 3
                color: Colors.md3.primary
                visible: root._loading
                SequentialAnimation on opacity {
                    running: root._loading
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: 0.2
                        duration: 450
                    }
                    NumberAnimation {
                        to: 0.9
                        duration: 450
                    }
                }
            }

            Text {
                visible: root._loading || root._result === ""
                text: root._loading ? "calculating..." : "—"
                color: Colors.md3.on_surface_variant
                font.pixelSize: root._loading ? 14 : 32
                font.weight: Font.Light
                font.family: Config.fontFamily
                opacity: 0.35
            }

            Text {
                visible: !root._loading && root._result !== ""
                text: root._result
                color: Colors.md3.on_surface
                font.pixelSize: 36
                font.weight: Font.Light
                font.family: Config.fontFamily
                elide: Text.ElideRight
                minimumPixelSize: 18
                fontSizeMode: Text.HorizontalFit
                lineHeight: 0.95
                Layout.fillWidth: true
            }

            Text {
                visible: !root._loading && root._resultUnit !== ""
                text: root._resultUnit
                color: Colors.md3.on_surface_variant
                font.pixelSize: 16
                font.family: Config.fontFamily
                opacity: 0.55
                Layout.alignment: Qt.AlignBottom
                bottomPadding: 4
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 6

            PillBtn {
                label: "󰆏  copy result"
                primary: true
                visible: root._result !== ""
                onClicked: root.copyResult(root._result)
            }
            PillBtn {
                label: "󰆏  copy expression"
                primary: false
                onClicked: root.copyResult(root.query.trim())
            }
        }
    }

    ColumnLayout {
        id: currencyLayout
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        visible: root._cls === "currency"
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Chip {
                label: root._currFrom
            }
            Text {
                text: "→"
                color: Colors.md3.on_surface_variant
                font.pixelSize: 12
                opacity: 0.4
            }
            Chip {
                label: root._currTo
                accent: true
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                height: 80
                radius: 14
                color: Colors.md3.surface_container_high

                ColumnLayout {
                    anchors {
                        fill: parent
                        margins: 14
                    }
                    spacing: 2

                    Text {
                        text: root._currFrom
                        color: Colors.md3.on_surface_variant
                        font.pixelSize: 11
                        font.family: Config.fontFamily
                        font.letterSpacing: 1
                        opacity: 0.5
                        Layout.fillWidth: true
                    }
                    Text {
                        text: root._symFor(root._currFrom) + root._formatCurrencyAmt(root._currFromAmt, root._currFrom)
                        color: Colors.md3.on_surface
                        font.pixelSize: 20
                        font.weight: Font.Medium
                        font.family: Config.fontFamily
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        visible: root._currDate !== ""
                        text: "rate · " + root._currDate
                        color: Colors.md3.on_surface_variant
                        font.pixelSize: 10
                        font.family: Config.fontFamily
                        opacity: 0.4
                        Layout.fillWidth: true
                    }
                }
            }

            Text {
                text: "→"
                color: Colors.md3.on_surface_variant
                font.pixelSize: 16
                opacity: 0.35
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle {
                Layout.fillWidth: true
                height: 80
                radius: 14
                color: Colors.md3.primary_container

                ColumnLayout {
                    anchors {
                        fill: parent
                        margins: 14
                    }
                    spacing: 2

                    Text {
                        text: root._currTo
                        color: Colors.md3.on_primary_container
                        font.pixelSize: 11
                        font.family: Config.fontFamily
                        font.letterSpacing: 1
                        opacity: 0.6
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        visible: root._loading
                        spacing: 5
                        Rectangle {
                            width: 5
                            height: 5
                            radius: 3
                            color: Colors.md3.on_primary_container
                            SequentialAnimation on opacity {
                                running: root._loading
                                loops: Animation.Infinite
                                NumberAnimation {
                                    to: 0.2
                                    duration: 450
                                }
                                NumberAnimation {
                                    to: 0.9
                                    duration: 450
                                }
                            }
                        }
                        Text {
                            text: "fetching..."
                            color: Colors.md3.on_primary_container
                            font.pixelSize: 13
                            font.family: Config.fontFamily
                            opacity: 0.5
                        }
                    }

                    Text {
                        visible: !root._loading && !root._currError && root._result !== ""
                        text: root._symFor(root._currTo) + root._result
                        color: Colors.md3.on_primary_container
                        font.pixelSize: 20
                        font.weight: Font.Medium
                        font.family: Config.fontFamily
                        elide: Text.ElideRight
                        minimumPixelSize: 13
                        fontSizeMode: Text.HorizontalFit
                        Layout.fillWidth: true
                    }

                    Text {
                        visible: !root._loading && root._currRate > 0
                        text: "1 " + root._currFrom + " = " + root._currRate.toLocaleString(undefined, {
                            minimumFractionDigits: 4,
                            maximumFractionDigits: 4
                        }) + " " + root._currTo
                        color: Colors.md3.on_primary_container
                        font.pixelSize: 10
                        font.family: Config.fontFamily
                        opacity: 0.5
                        Layout.fillWidth: true
                    }
                }
            }
        }

        Text {
            visible: root._currError
            Layout.fillWidth: true
            text: "couldn't fetch rates"
            color: Colors.md3.error
            font.pixelSize: 13
            font.family: Config.fontFamily
        }

        Flow {
            Layout.fillWidth: true
            spacing: 6

            PillBtn {
                label: "󰆏  copy result"
                primary: true
                visible: root._result !== ""
                onClicked: root.copyResult(root._result)
            }
            PillBtn {
                label: "󰓡  swap"
                primary: false
                visible: root._result !== "" && root._currRate > 0
                onClicked: {
                    const decimals = root._noDecimalCodes.includes(root._currTo) ? 0 : 2;
                    const newAmt = root._currRawResult.toFixed(decimals);
                    root.swapRequested(newAmt + " " + root._currTo + " to " + root._currFrom);
                }
            }
        }
    }

    Process {
        id: openProc
        running: false
    }
}
