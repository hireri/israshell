pragma Singleton
import QtQuick
import Quickshell
import qs.style

Singleton {
    id: root

    readonly property string liveTime: _liveTime
    readonly property string liveSecs: _liveSecs
    readonly property string liveAmPm: _liveAmPm
    readonly property string liveDayName: _liveDayName
    readonly property string liveFullDate: _liveFullDate

    readonly property string barTimeText: _barTimeText
    readonly property string barDateText: _barDateText

    readonly property string weatherTemp: _weatherTemp
    readonly property string weatherHigh: _weatherHigh
    readonly property string weatherLow: _weatherLow
    readonly property string weatherDesc: _weatherDesc
    readonly property string weatherHumid: _weatherHumid
    readonly property string weatherUvi: _weatherUvi
    readonly property string weatherCode: _weatherCode

    readonly property bool weatherLoading: _weatherLoading
    readonly property string weatherError: _weatherError

    readonly property string weatherAqi: _weatherAqi

    readonly property bool aqiLoading: _aqiLoading
    readonly property string aqiError: _aqiError

    property string _liveTime: ""
    property string _liveSecs: ""
    property string _liveAmPm: ""
    property string _liveDayName: ""
    property string _liveFullDate: ""
    property string _barTimeText: ""
    property string _barDateText: ""

    property string _weatherTemp: "—"
    property string _weatherHigh: "—"
    property string _weatherLow: "—"
    property string _weatherDesc: "loading…"
    property string _weatherHumid: "—"
    property string _weatherUvi: "—"
    property string _weatherCode: "116"
    property bool _weatherLoading: true
    property string _weatherError: ""

    property string _weatherAqi: "—"
    property bool _aqiLoading: true
    property string _aqiError: ""

    property var _clockTimer: Timer {
        interval: 100
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root._updateClock()
    }

    function _updateClock() {
        const now = new Date();
        const fmt12 = Config.hourFormat !== 0;
        const h = now.getHours();
        const m = now.getMinutes();
        const s = now.getSeconds();
        const hDisp = fmt12 ? (h % 12 || 12) : h;

        _liveTime = String(hDisp).padStart(2, '0') + ":" + String(m).padStart(2, '0');
        _liveSecs = String(s).padStart(2, '0');
        _liveAmPm = Config.hourFormat === 1 ? " am" : Config.hourFormat === 2 ? " AM" : "";
        _liveDayName = Qt.formatDate(now, "dddd");
        _liveFullDate = Qt.formatDate(now, "dd MMMM yyyy");

        const secSuffix = Config.showSeconds ? ":" + _liveSecs : "";
        const amPmSuffix = _liveAmPm.trim() !== "" ? " " + _liveAmPm.trim() : "";
        _barTimeText = _liveTime + secSuffix + amPmSuffix;
        _barDateText = Qt.formatDate(now, ["ddd, dd/MM", "ddd, MM/dd"][Config.dateFormat]);
    }

    property var _weatherTimer: Timer {
        interval: 900000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root._fetchWeather()
    }

    function _fetchWeather() {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", "https://wttr.in/?format=j1");
        xhr.timeout = 15000;
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status === 200) {
                try {
                    const data = JSON.parse(xhr.responseText);
                    const cur = data.current_condition[0];
                    const today = data.weather[0];

                    root._weatherTemp = (Config.useFarenheit ? cur.temp_F : cur.temp_C) + "°";
                    root._weatherHigh = (Config.useFarenheit ? today.maxtempF : today.maxtempC) + "°";
                    root._weatherLow = (Config.useFarenheit ? today.mintempF : today.mintempC) + "°";
                    root._weatherDesc = cur.weatherDesc[0].value;
                    root._weatherHumid = cur.humidity + "%";
                    root._weatherUvi = String(cur.uvIndex || "0");
                    root._weatherCode = String(cur.weatherCode);
                    root._weatherError = "";
                } catch (e) {
                    root._weatherError = "parse error: " + e;
                    console.warn("[LocaleService] weather parse error:", e);
                }
            } else {
                root._weatherError = "HTTP " + xhr.status;
                console.warn("[LocaleService] weather fetch failed:", xhr.status);
            }
            root._weatherLoading = false;
        };
        xhr.send();
    }

    property real _lat: 0.0
    property real _lon: 0.0
    property bool _coordsKnown: false

    property var _aqiTimer: Timer {
        interval: 1800000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root._maybeFetchAqi()
    }

    function _maybeFetchAqi() {
        if (typeof Config.latitude !== "undefined" && typeof Config.longitude !== "undefined" && Config.latitude !== 0 && Config.longitude !== 0) {
            _lat = Config.latitude;
            _lon = Config.longitude;
            _coordsKnown = true;
        }

        if (_coordsKnown) {
            _fetchAqi(_lat, _lon);
        } else {
            _resolveCoords(function (lat, lon) {
                _lat = lat;
                _lon = lon;
                _coordsKnown = true;
                _fetchAqi(lat, lon);
            });
        }
    }

    function _resolveCoords(callback) {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", "https://wttr.in/?format=j1");
        xhr.timeout = 15000;
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status === 200) {
                try {
                    const data = JSON.parse(xhr.responseText);
                    const area = data.nearest_area[0];
                    const lat = parseFloat(area.latitude);
                    const lon = parseFloat(area.longitude);
                    callback(lat, lon);
                } catch (e) {
                    console.warn("[LocaleService] coord resolve error:", e);
                }
            }
        };
        xhr.send();
    }

    function _fetchAqi(lat, lon) {
        const url = "https://air-quality-api.open-meteo.com/v1/air-quality" + "?latitude=" + lat + "&longitude=" + lon + "&hourly=us_aqi" + "&timezone=auto" + "&forecast_days=1";

        const xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        xhr.timeout = 15000;
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status === 200) {
                try {
                    const data = JSON.parse(xhr.responseText);
                    const times = data.hourly.time;
                    const aqiArr = data.hourly.us_aqi;
                    const nowHour = new Date();
                    nowHour.setMinutes(0, 0, 0);
                    const nowStr = nowHour.toISOString().slice(0, 16);
                    let idx = times.indexOf(nowStr);
                    if (idx < 0)
                        idx = 0;
                    const aqi = aqiArr[idx];
                    root._weatherAqi = aqi !== null && aqi !== undefined ? String(Math.round(aqi)) : "—";
                    root._aqiError = "";
                } catch (e) {
                    root._aqiError = "parse error: " + e;
                    console.warn("[LocaleService] AQI parse error:", e);
                }
            } else {
                root._aqiError = "HTTP " + xhr.status;
                console.warn("[LocaleService] AQI fetch failed:", xhr.status);
            }
            root._aqiLoading = false;
        };
        xhr.send();
    }
}
