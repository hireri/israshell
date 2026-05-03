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
            "€": "EUR",
            "$": "USD",
            "£": "GBP",
            "¥": "JPY",
            "₹": "INR",
            "₽": "RUB",
            "₩": "KRW",
            "₪": "ILS"
        })

    readonly property var _codeToSymbol: ({
            "USD": "$",
            "EUR": "€",
            "GBP": "£",
            "JPY": "¥",
            "INR": "₹",
            "RUB": "₽",
            "KRW": "₩",
            "ILS": "₪",
            "CAD": "C$",
            "AUD": "A$",
            "CHF": "Fr",
            "CNY": "¥",
            "BRL": "R$",
            "MXN": "$",
            "SGD": "S$",
            "HKD": "HK$",
            "NOK": "kr",
            "SEK": "kr",
            "DKK": "kr",
            "PLN": "zł",
            "CZK": "Kč",
            "TRY": "₺",
            "ZAR": "R",
            "AED": "د.إ",
            "THB": "฿"
        })

    readonly property var _noDecimalCodes: ["JPY", "KRW", "VND", "CLP", "IDR"]

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
            if (code)
                s = post[1] + " " + code + post[3];
        }

        return s;
    }

    function _parseCurrency(q) {
        const norm = _normalizeCurrencySymbols(q.trim());

        const m = /^([\d.,]+)\s+([a-z]{3})\s+(?:to|in)\s+([a-z]{3})$/i.exec(norm);
        if (!m)
            return null;

        const amt = parseFloat(m[1].replace(",", "."));
        if (isNaN(amt) || amt < 0)
            return null;

        const from = m[2].toUpperCase();
        const to = m[3].toUpperCase();

        if (!_currencyCodes.includes(from.toLowerCase()))
            return null;
        if (!_currencyCodes.includes(to.toLowerCase()))
            return null;

        return {
            amt,
            from,
            to
        };
    }

    function _looksLikeMath(q) {
        if (!/^[\d(]|^(?:sqrt|sin|cos|tan|asin|acos|atan|log|ln|abs|floor|ceil|round|pi\b)/i.test(q))
            return false;

        if (/[+\-*\/^%]/.test(q))
            return true;
        if (/\bto\b/i.test(q))
            return true;

        if (/\d\s*(?:km|mi|miles?\b|kg|lbs?\b|oz|mg|inches?|feet|foot|ft|yards?\b|m\b|cm|mm|ml|liters?\b|gallons?\b|mph|kph|kmh|celsius|fahrenheit|kelvin)\b/i.test(q))
            return true;

        if (/\b(?:sqrt|sin|cos|tan|asin|acos|atan|log|ln|abs|floor|ceil|round)\s*\(/.test(q))
            return true;

        return false;
    }

    function _classify(q) {
        if (q === "")
            return {
                type: "empty",
                parsed: null
            };
        const p = _parseCurrency(q);
        if (p)
            return {
                type: "currency",
                parsed: p
            };
        if (_looksLikeMath(q))
            return {
                type: "math",
                parsed: null
            };
        return {
            type: "unknown",
            parsed: null
        };
    }

    onQueryChanged: {
        debounce.stop();
        mathProc.running = false;
        if (_activeXhr) {
            _activeXhr.abort();
            _activeXhr = null;
        }

        _result = "";
        _resultUnit = "";
        _parsedExpr = "";
        _currFrom = "";
        _currTo = "";
        _currFromAmt = 0;
        _currRate = 0;
        _currRawResult = 0;
        _currDate = "";
        _currError = false;
        _loading = false;

        const c = _classify(query.trim());
        _cls = c.type;
        _parsed = c.parsed;

        if (_cls === "empty" || _cls === "unknown")
            return;

        if (_cls === "currency") {
            _currFrom = c.parsed.from;
            _currTo = c.parsed.to;
            _currFromAmt = c.parsed.amt;
        }

        _loading = true;
        debounce.restart();
    }

    Timer {
        id: debounce
        interval: 380
        onTriggered: {
            const q = root.query.trim();

            const c = root._classify(q);
            if (c.type !== root._cls || (c.parsed && JSON.stringify(c.parsed) !== JSON.stringify(root._parsed))) {
                root._cls = c.type;
                root._parsed = c.parsed;
                root._currFrom = c.parsed ? c.parsed.from : "";
                root._currTo = c.parsed ? c.parsed.to : "";
                root._currFromAmt = c.parsed ? c.parsed.amt : 0;
            }

            if (root._cls === "empty" || root._cls === "unknown") {
                root._loading = false;
                return;
            }

            if (root._cls === "currency") {
                root._fetchCurrency(root._parsed);
            } else {
                mathProc.running = false;
                mathProc.command = ["qalc", q];
                mathProc.running = true;
            }
        }
    }

    Process {
        id: mathProc
        stdout: StdioCollector {
            onStreamFinished: {
                root._loading = false;
                const out = this.text.trim();
                if (!out)
                    return;

                const eqIdx = out.lastIndexOf(" = ");
                const exprPart = eqIdx !== -1 ? out.slice(0, eqIdx).trim() : "";
                const resPart = eqIdx !== -1 ? out.slice(eqIdx + 3).trim() : out;

                if (resPart.toLowerCase() === root.query.trim().toLowerCase())
                    return;

                if (/\b(?:inf(?:inity)?|nan|undefined)\b/i.test(resPart))
                    return;

                const inputFlat = root.query.trim().replace(/\s+/g, " ").toLowerCase();
                const exprFlat = exprPart.replace(/\s+/g, " ").toLowerCase();
                root._parsedExpr = (exprPart !== "" && exprFlat !== inputFlat) ? exprPart : "";

                const m = /^([\d.,\-+e]+)\s+(.+)$/.exec(resPart);
                if (m) {
                    root._result = m[1];
                    root._resultUnit = m[2];
                } else {
                    root._result = resPart;
                    root._resultUnit = "";
                }
            }
        }
    }

    function _fetchCurrency(parsed) {
        if (!parsed) {
            _loading = false;
            return;
        }

        const url = "https://api.frankfurter.app/latest?from=" + parsed.from + "&to=" + parsed.to;
        const xhr = new XMLHttpRequest();
        _activeXhr = xhr;

        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (root._activeXhr !== xhr)
                return;
            root._activeXhr = null;
            root._loading = false;

            if (xhr.status !== 200) {
                root._currError = true;
                return;
            }
            try {
                const data = JSON.parse(xhr.responseText);
                root._currRate = data.rates[parsed.to] ?? 0;
                root._currDate = data.date ?? "";
                root._currRawResult = parsed.amt * root._currRate;
                root._result = root._formatCurrencyAmt(root._currRawResult, parsed.to);
            } catch (_) {
                root._currError = true;
            }
        };

        xhr.open("GET", url);
        xhr.send();
    }

    function _formatCurrencyAmt(amt, code) {
        if (_noDecimalCodes.includes(code))
            return amt.toLocaleString(undefined, {
                maximumFractionDigits: 0
            });
        return amt.toLocaleString(undefined, {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        });
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
                text: root._loading ? "calculating…" : "—"
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
            PillBtn {
                label: "󰪚  open qalculate"
                primary: false
                onClicked: {
                    openProc.command = ["sh", "-c", "qalculate-gtk 2>/dev/null || kitty qalc 2>/dev/null &"];
                    openProc.running = true;
                }
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
                            text: "fetching…"
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
