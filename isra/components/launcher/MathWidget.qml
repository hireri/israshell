import QtQuick
import QtQuick.Layouts
import qs.components
import qs.style
import "../../services/calc.js" as Calc

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

    readonly property var _codeToSymbol: ({
        "USD": "$", "EUR": "€", "GBP": "£", "JPY": "¥", "INR": "₹", "KRW": "₩", "ILS": "₪",
        "CAD": "C$", "AUD": "A$", "NZD": "NZ$", "CHF": "Fr", "CNY": "¥", "BRL": "R$", "MXN": "$",
        "SGD": "S$", "HKD": "HK$", "NOK": "kr", "SEK": "kr", "DKK": "kr", "ISK": "kr", "PLN": "zł",
        "CZK": "Kč", "HUF": "Ft", "TRY": "₺", "ZAR": "R", "THB": "฿", "PHP": "₱"
    })

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

        const c = Calc.classify(query);
        _cls    = c ? c.type : (query.trim() === "" ? "empty" : "unknown");
        _parsed = c ? c.parsed : null;
        if (!c) return;

        if (_cls === "currency") {
            _currFrom    = c.parsed.from;
            _currTo      = c.parsed.to;
            _currFromAmt = c.parsed.amt;
            const hit = Calc.cachedRate(c.parsed.from, c.parsed.to);
            if (hit) {
                _applyRate(c.parsed, hit.rate, hit.date);
                return;
            }
            _loading = true;
            debounce.restart();
            return;
        }

        if (_cls === "unit") {
            const p = c.parsed;
            _result     = Calc.format(p.value);
            _resultUnit = p.toLabel;
            _parsedExpr = Calc.format(p.amt) + " " + p.fromLabel + " → " + p.toLabel;
            return;
        }

        _result = Calc.format(c.value);
    }

    Timer {
        id: debounce
        interval: 380
        onTriggered: {
            if (root._cls === "currency" && root._parsed)
                root._fetchCurrency(root._parsed);
        }
    }

    function _applyRate(parsed, rate, date) {
        _currRate      = rate;
        _currDate      = date;
        _currRawResult = parsed.amt * rate;
        _result        = _formatCurrencyAmt(_currRawResult, parsed.to);
    }

    function _fetchCurrency(parsed) {
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
                const rate = data.rates[parsed.to];
                if (!(rate > 0)) { root._currError = true; return; }
                Calc.storeRate(parsed.from, parsed.to, rate, data.date ?? "");
                root._applyRate(parsed, rate, data.date ?? "");
            } catch (_) {
                root._currError = true;
            }
        };

        xhr.open("GET", Calc.rateUrl(parsed.from, parsed.to));
        xhr.send();
    }

    function _formatCurrencyAmt(amt, code) {
        return Calc.formatCurrency(amt, code);
    }

    function _symFor(code) {
        return _codeToSymbol[code] ?? "";
    }

    component Chip: Rectangle {
        property string label: ""
        property bool accent: false

        implicitWidth: chipLbl.implicitWidth + 16
        height: 22
        radius: 11
        color: accent ? Colors.md3.primary_container : Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)

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

            LoadingSpinner {
                visible: root._loading
                size: 14
            }

            Text {
                visible: root._loading || root._result === ""
                text: root._loading ? "calculating..." : "..."
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
                label: Localization.t("mathWidget.copy_result")
                primary: true
                visible: root._result !== ""
                onTapped: root.copyResult(root._result)
            }
            PillBtn {
                label: Localization.t("mathWidget.copy_expression")
                primary: false
                onTapped: root.copyResult(root.query.trim())
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
                color: Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)

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
                        LoadingSpinner {
                            size: 14
                            color: Colors.md3.on_primary_container
                        }
                        Text {
                            text: Localization.t("mathWidget.fetching")
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
            text: Localization.t("mathWidget.couldn_t_fetch_rates")
            color: Colors.md3.error
            font.pixelSize: 13
            font.family: Config.fontFamily
        }

        Flow {
            Layout.fillWidth: true
            spacing: 6

            PillBtn {
                label: Localization.t("mathWidget.copy_result")
                primary: true
                visible: root._result !== ""
                onTapped: root.copyResult(root._result)
            }
            PillBtn {
                label: Localization.t("mathWidget.swap")
                primary: false
                visible: root._result !== "" && root._currRate > 0
                onTapped: {
                    root.swapRequested(Calc.formatCurrency(root._currRawResult, root._currTo) + " " + root._currTo + " to " + root._currFrom);
                }
            }
        }
    }
}
