pragma Singleton
import QtQuick
import Quickshell
import qs.style

Singleton {
    id: root

    readonly property var _qtLocale: Qt.locale(Config.language.split("_").slice(0, 2).join("_"))

    readonly property string liveTime: _liveTime
    readonly property string liveSecs: _liveSecs
    readonly property string liveAmPm: _liveAmPm
    readonly property string liveDayName: _liveDayName
    readonly property string liveFullDate: _liveFullDate

    readonly property string barTimeText: _barTimeText
    readonly property string barDateText: _barDateText
    readonly property string shortDateText: _shortDateText

    readonly property string activeAstroName: _activeAstroName
    readonly property string activeAstroTime: _activeAstroTime
    readonly property string activeAstroMaterialIcon: _activeAstroMaterialIcon
    readonly property string activeAstroColorType: _activeAstroColorType

    readonly property string weatherTemp: _weatherTemp
    readonly property string weatherFeelsLike: _weatherFeelsLike
    readonly property string weatherRainChance: _weatherRainChance
    readonly property string weatherHigh: _weatherHigh
    readonly property string weatherLow: _weatherLow
    readonly property string weatherDesc: _weatherDesc
    readonly property string weatherHumid: _weatherHumid
    readonly property string weatherUvi: _weatherUvi
    readonly property string weatherSunrise: _weatherSunrise
    readonly property string weatherSunset: _weatherSunset

    readonly property string weatherIconName: _weatherIconName
    readonly property color weatherIconColor: _colorForRole(_weatherIconColorRole)

    readonly property int weatherTempValue: _weatherTempValue
    readonly property int weatherHighValue: _weatherHighValue
    readonly property int weatherLowValue: _weatherLowValue
    readonly property int weatherCode: _weatherCode
    readonly property bool weatherIsDay: _weatherIsDay
    readonly property string weatherLocation: _weatherLocation
    readonly property var weatherHourly: _weatherHourly
    readonly property var weatherDaily: _weatherDaily

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
    property string _shortDateText: ""

    property string _activeAstroName: "—"
    property string _activeAstroTime: "—"
    property string _activeAstroMaterialIcon: "wb-twilight"
    property string _activeAstroColorType: "sun"

    property int _sunriseHour: -1
    property int _sunriseMinute: 0
    property int _sunsetHour: -1
    property int _sunsetMinute: 0

    property string _weatherTemp: "—"
    property string _weatherFeelsLike: "—"
    property string _weatherRainChance: "—"
    property string _weatherHigh: "—"
    property string _weatherLow: "—"
    property string _weatherDesc: "loading..."
    property string _weatherHumid: "—"
    property string _weatherUvi: "—"
    property string _weatherSunrise: "—"
    property string _weatherSunset: "—"
    property bool _weatherLoading: true
    property string _weatherError: ""

    property string _weatherIconName: "partly-cloudy-day"
    property string _weatherIconColorRole: "primary"

    property int _weatherTempValue: 0
    property int _weatherHighValue: 0
    property int _weatherLowValue: 0
    property int _weatherCode: 0
    property bool _weatherIsDay: true
    property string _weatherLocation: ""
    property var _weatherHourly: []
    property var _weatherDaily: []

    property string _weatherAqi: "—"
    property bool _aqiLoading: true
    property string _aqiError: ""

    Connections {
        target: Config

        function onUseFahrenheitChanged() { root._fetchWeather(); }
        function onHourFormatChanged() { root._updateClock(); }
        function onShowSecondsChanged() { root._updateClock(); }
        function onDateFormatChanged() { root._updateClock(); }
        function onDateOrderChanged() { root._updateClock(); }
        function onTimeFormatChanged() { root._updateClock(); }

        function onCityNameChanged() {
            root._coordsKnown = false;
            root._maybeFetchAqi();
            root._fetchWeather();
        }
    }

    Connections {
        target: NetworkService
        function onIsOnlineChanged() {
            if (NetworkService.isOnline) {
                console.log("[LocaleService] Connection back online. Re-fetching data.");
                root._maybeFetchAqi();
                root._fetchWeather();
            }
        }
    }

    property var _clockTimer: Timer {
        interval: 100
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root._updateClock()
    }

    function _resolveCityCoords(cityName, callback) {
        if (!NetworkService.isOnline) return;

        const url = "https://geocoding-api.open-meteo.com/v1/search"
            + "?name=" + encodeURIComponent(cityName)
            + "&count=1"
            + "&language=en"
            + "&format=json";

        const xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        xhr.timeout = 10000;
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status === 200) {
                try {
                    const data = JSON.parse(xhr.responseText);
                    if (data.results && data.results.length > 0) {
                        const result = data.results[0];
                        const lat = parseFloat(result.latitude);
                        const lon = parseFloat(result.longitude);
                        if (!isNaN(lat) && !isNaN(lon)) {
                            callback(lat, lon);
                        } else {
                            console.warn("[LocaleService] Geocoder returned invalid coordinates for city:", cityName);
                        }
                    } else {
                        console.warn("[LocaleService] No geocoding results found for city:", cityName);
                    }
                } catch (e) {
                    console.warn("[LocaleService] Geocoding parse error:", e);
                }
            } else {
                console.warn("[LocaleService] Geocoding API call failed with status:", xhr.status);
            }
        };
        xhr.send();
    }

    function _dynamicTimeFormat() {
        let fmt = Config.hourFormat === 0 ? "HH:mm" : "h:mm";
        if (Config.showSeconds) {
            fmt += ":ss";
        }
        if (Config.hourFormat === 1) {
            fmt += " ap";
        } else if (Config.hourFormat === 2) {
            fmt += " AP";
        }
        return fmt;
    }

    function _dynamicDateFormat() {
        return Config.dateOrder === 1 ? "MM/dd" : "dd/MM";
    }

    function formatHour(when) {
        if (!when)
            return "";
        const fmt = Config.hourFormat === 0 ? "HH" : (Config.hourFormat === 2 ? "hAP" : "hap");
        return when.toLocaleString(root._qtLocale, fmt);
    }

    function formatWeekday(when) {
        if (!when)
            return "";
        return when.toLocaleDateString(root._qtLocale, "dddd");
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
        const isPm = h >= 12;
        const amPmWord = isPm ? Localization.t("clock.pm") : Localization.t("clock.am");
        _liveAmPm = Config.hourFormat === 0 ? "" : (" " + (Config.hourFormat === 2 ? amPmWord : amPmWord.toLowerCase()));
        _liveDayName = now.toLocaleDateString(root._qtLocale, "dddd");
        _liveFullDate = now.toLocaleDateString(root._qtLocale, "dd MMMM yyyy");

        const barTimeFmt = Config.timeFormat !== "" ? Config.timeFormat : root._dynamicTimeFormat();
        _barTimeText = now.toLocaleString(root._qtLocale, barTimeFmt);

        const barDateFmt = Config.dateFormat !== "" ? Config.dateFormat : root._dynamicDateFormat();
        _barDateText = now.toLocaleString(root._qtLocale, barDateFmt);
        _shortDateText = now.toLocaleString(root._qtLocale, Config.dateOrder === 1 ? "ddd, MMM dd" : "ddd, dd MMM");

        root._updateAstroEvent(now);
    }

    function _parseOpenMeteoDateTime(str) {
        if (!str) return null;
        const parts = str.split('T');
        const dateParts = parts[0].split('-');
        const timeParts = (parts[1] ?? "00:00").split(':');
        if (dateParts.length !== 3 || timeParts.length < 2) return null;

        const year = parseInt(dateParts[0]);
        const month = parseInt(dateParts[1]) - 1;
        const day = parseInt(dateParts[2]);
        const hour = parseInt(timeParts[0]);
        const minute = parseInt(timeParts[1]);

        return new Date(year, month, day, hour, minute, 0, 0);
    }

    function _formatAstroTime(date) {
        if (!date) return "—";
        const fmt12 = Config.hourFormat !== 0;
        const h = date.getHours();
        const m = date.getMinutes();
        const hDisp = fmt12 ? (h % 12 || 12) : h;
        const mDisp = String(m).padStart(2, '0');
        const isPm = h >= 12;
        const ampm = Config.hourFormat === 0 ? "" : (isPm ? (Config.hourFormat === 2 ? " PM" : " pm") : (Config.hourFormat === 2 ? " AM" : " am"));
        return String(hDisp).padStart(2, '0') + ":" + mDisp + ampm;
    }

    function _colorForRole(role) {
        switch (role) {
        case "tertiary": return Colors.md3.tertiary;
        case "on_surface_variant": return Colors.md3.on_surface_variant;
        case "outline": return Colors.md3.outline;
        case "error": return Colors.md3.error;
        default: return Colors.md3.primary;
        }
    }

    function _bestAstroEvent(sunriseHour, sunriseMinute, sunsetHour, sunsetMinute, now) {
        const events = [];
        if (sunriseHour >= 0)
            events.push({ name: "Sunrise", materialIcon: "wb-twilight", colorType: "sun", hour: sunriseHour, minute: sunriseMinute });
        if (sunsetHour >= 0)
            events.push({ name: "Sunset", materialIcon: "wb-twilight", colorType: "sun", hour: sunsetHour, minute: sunsetMinute });

        let bestEvent = null;
        let bestDiff = Infinity;
        const oneDayMs = 24 * 60 * 60 * 1000;

        events.forEach(function(ev) {
            const todayTime = new Date(now);
            todayTime.setHours(ev.hour, ev.minute, 0, 0);
            const times = [todayTime, new Date(todayTime.getTime() - oneDayMs)];

            times.forEach(function(t) {
                const diff = now.getTime() - t.getTime();
                if (diff >= 0 && diff < bestDiff) {
                    bestDiff = diff;
                    bestEvent = {
                        name: ev.name,
                        materialIcon: ev.materialIcon,
                        colorType: ev.colorType,
                        time: t
                    };
                }
            });
        });

        return bestEvent;
    }

    function _updateAstroEvent(now) {
        const bestEvent = root._bestAstroEvent(root._sunriseHour, root._sunriseMinute, root._sunsetHour, root._sunsetMinute, now);

        if (bestEvent) {
            root._activeAstroName = bestEvent.name;
            root._activeAstroTime = root._formatAstroTime(bestEvent.time);
            root._activeAstroMaterialIcon = bestEvent.materialIcon;
            root._activeAstroColorType = bestEvent.colorType;
        } else {
            root._activeAstroName = "—";
            root._activeAstroTime = "—";
            root._activeAstroMaterialIcon = "wb-twilight";
            root._activeAstroColorType = "sun";
        }
    }

    property var _weatherTimer: Timer {
        interval: 900000
        running: NetworkService.isOnline
        repeat: true
        triggeredOnStart: true
        onTriggered: root._fetchWeather()
    }

    function _weatherUrl(lat, lon) {
        const tempUnit = Config.useFahrenheit ? "fahrenheit" : "celsius";
        return "https://api.open-meteo.com/v1/forecast"
            + "?latitude=" + lat
            + "&longitude=" + lon
            + "&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,is_day"
            + "&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,weather_code"
            + "&hourly=precipitation_probability,temperature_2m,weather_code,is_day"
            + "&temperature_unit=" + tempUnit
            + "&timezone=auto"
            + "&forecast_days=7";
    }

    function _parseWeatherResponse(data) {
        const cur = data.current;
        const daily = data.daily;
        const hourly = data.hourly;

        const precipProb = hourly.precipitation_probability || [];
        let maxChance = 0;
        for (let i = 0; i < Math.min(24, precipProb.length); i++) {
            const chance = parseInt(precipProb[i]);
            if (chance > maxChance)
                maxChance = chance;
        }

        const sunriseDate = _parseOpenMeteoDateTime(daily.sunrise[0]);
        const sunsetDate = _parseOpenMeteoDateTime(daily.sunset[0]);
        const details = _getWmoDetails(cur.weather_code, cur.is_day);

        const hourlyOut = [];
        const times = hourly.time || [];
        const now = new Date();
        for (let i = 0; i < times.length; i++) {
            const when = _parseOpenMeteoDateTime(times[i]);
            if (!when || when < now)
                continue;
            hourlyOut.push({
                time: when,
                temp: Math.round(hourly.temperature_2m?.[i] ?? 0),
                code: parseInt(hourly.weather_code?.[i] ?? 0),
                isDay: parseInt(hourly.is_day?.[i] ?? 1) !== 0
            });
            if (hourlyOut.length >= 24)
                break;
        }

        const dailyOut = [];
        const days = daily.time || [];
        for (let i = 0; i < days.length; i++) {
            dailyOut.push({
                date: _parseOpenMeteoDateTime(days[i]),
                high: Math.round(daily.temperature_2m_max?.[i] ?? 0),
                low: Math.round(daily.temperature_2m_min?.[i] ?? 0),
                code: parseInt(daily.weather_code?.[i] ?? 0)
            });
        }

        return {
            temp: Math.round(cur.temperature_2m) + "°",
            feelsLike: Math.round(cur.apparent_temperature) + "°",
            high: Math.round(daily.temperature_2m_max[0]) + "°",
            low: Math.round(daily.temperature_2m_min[0]) + "°",
            humidity: Math.round(cur.relative_humidity_2m) + "%",
            uvi: String(Math.round(daily.uv_index_max[0] || 0)),
            rainChance: String(maxChance) + "%",
            sunriseDate: sunriseDate,
            sunsetDate: sunsetDate,
            desc: details.desc,
            iconName: details.iconName,
            iconColorRole: details.colorRole,
            tempValue: Math.round(cur.temperature_2m),
            highValue: Math.round(daily.temperature_2m_max[0]),
            lowValue: Math.round(daily.temperature_2m_min[0]),
            code: parseInt(cur.weather_code),
            isDay: parseInt(cur.is_day) !== 0,
            hourly: hourlyOut,
            daily: dailyOut
        };
    }

    function _getWmoDetails(wmoCode, isDay) {
        const c = parseInt(wmoCode);
        const day = parseInt(isDay) !== 0;
        let iconName = "partly-cloudy-day";
        let colorRole = "primary";
        let desc = Localization.t("weather.unknown");

        if (c === 0) {
            if (day) {
                iconName = "wb-sunny";
                colorRole = "tertiary";
                desc = Localization.t("weather.sunny");
            } else {
                iconName = "moon-stars";
                colorRole = "primary";
                desc = Localization.t("weather.clear_night");
            }
        } else if (c === 1 || c === 2) {
            if (day) {
                iconName = "partly-cloudy-day";
                colorRole = "primary";
                desc = Localization.t("weather.partly_cloudy");
            } else {
                iconName = "partly-cloudy-night";
                colorRole = "primary";
                desc = Localization.t("weather.partly_cloudy");
            }
        } else if (c === 3) {
            iconName = "cloudy";
            colorRole = "on_surface_variant";
            desc = Localization.t("weather.overcast");
        } else if (c === 45 || c === 48) {
            iconName = "foggy";
            colorRole = "on_surface_variant";
            desc = Localization.t("weather.foggy");
        } else if ([51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82].includes(c)) {
            iconName = "rainy";
            colorRole = "primary";
            desc = c < 60 ? Localization.t("weather.drizzle") : Localization.t("weather.rain");
        } else if ([71, 73, 75, 77, 85, 86].includes(c)) {
            iconName = "snowy";
            colorRole = "outline";
            desc = Localization.t("weather.snow");
        } else if ([95, 96, 99].includes(c)) {
            iconName = "thunderstorm";
            colorRole = "error";
            desc = Localization.t("weather.thunderstorm");
        }

        return { iconName: iconName, colorRole: colorRole, desc: desc };
    }

    function _fetchWeather() {
        if (!NetworkService.isOnline) {
            root._weatherError = Localization.t("weather.offline");
            root._weatherLoading = false;
            return;
        }

        if (!_coordsKnown) {
            root._maybeFetchAqi();
            return;
        }

        const xhr = new XMLHttpRequest();
        xhr.open("GET", root._weatherUrl(_lat, _lon));
        xhr.timeout = 15000;
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status === 200) {
                try {
                    const parsed = root._parseWeatherResponse(JSON.parse(xhr.responseText));
                    root._applyWeatherData(parsed);
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

    function _applyWeatherData(parsed) {
        try {
            root._weatherTemp = parsed.temp;
            root._weatherFeelsLike = parsed.feelsLike;
            root._weatherRainChance = parsed.rainChance;
            root._weatherHigh = parsed.high;
            root._weatherLow = parsed.low;
            root._weatherHumid = parsed.humidity;
            root._weatherUvi = parsed.uvi;

            root._weatherSunrise = parsed.sunriseDate ? _formatAstroTime(parsed.sunriseDate) : "—";
            root._weatherSunset = parsed.sunsetDate ? _formatAstroTime(parsed.sunsetDate) : "—";

            root._weatherIconName = parsed.iconName;
            root._weatherIconColorRole = parsed.iconColorRole;
            root._weatherDesc = parsed.desc;
            root._weatherError = "";

            root._weatherTempValue = parsed.tempValue ?? 0;
            root._weatherHighValue = parsed.highValue ?? 0;
            root._weatherLowValue = parsed.lowValue ?? 0;
            root._weatherCode = parsed.code ?? 0;
            root._weatherIsDay = parsed.isDay ?? true;
            root._weatherHourly = parsed.hourly ?? [];
            root._weatherDaily = parsed.daily ?? [];
            if (Config.cityName)
                root._weatherLocation = Config.cityName;

            root._sunriseHour = parsed.sunriseDate ? parsed.sunriseDate.getHours() : -1;
            root._sunriseMinute = parsed.sunriseDate ? parsed.sunriseDate.getMinutes() : 0;
            root._sunsetHour = parsed.sunsetDate ? parsed.sunsetDate.getHours() : -1;
            root._sunsetMinute = parsed.sunsetDate ? parsed.sunsetDate.getMinutes() : 0;

            root._updateAstroEvent(new Date());
        } catch (e) {
            root._weatherError = "format error: " + e;
            console.warn("[LocaleService] weather format error:", e);
        }
    }

    function fetchWeatherForQuery(cityName, callback) {
        if (!NetworkService.isOnline) {
            callback("Offline", null);
            return;
        }

        const geoUrl = "https://geocoding-api.open-meteo.com/v1/search"
            + "?name=" + encodeURIComponent(cityName)
            + "&count=1"
            + "&language=en"
            + "&format=json";

        const geoXhr = new XMLHttpRequest();
        geoXhr.open("GET", geoUrl);
        geoXhr.timeout = 10000;
        geoXhr.onreadystatechange = function () {
            if (geoXhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (geoXhr.status === 200) {
                try {
                    const geoData = JSON.parse(geoXhr.responseText);
                    if (geoData.results && geoData.results.length > 0) {
                        const result = geoData.results[0];
                        const lat = parseFloat(result.latitude);
                        const lon = parseFloat(result.longitude);
                        const name = result.name;
                        const country = result.country || "";
                        const prettyLocation = country ? (name + ", " + country) : name;

                        if (!isNaN(lat) && !isNaN(lon)) {
                            root._fetchWeatherForCoords(lat, lon, prettyLocation, callback);
                        } else {
                            callback("Invalid coordinates", null);
                        }
                    } else {
                        callback("Location not found", null);
                    }
                } catch (e) {
                    callback("Geocoder parse error", null);
                }
            } else {
                callback("Geocoder HTTP error " + geoXhr.status, null);
            }
        };
        geoXhr.send();
    }

    function _fetchWeatherForCoords(lat, lon, prettyLocation, callback) {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", root._weatherUrl(lat, lon));
        xhr.timeout = 15000;
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status === 200) {
                try {
                    const parsed = root._parseWeatherResponse(JSON.parse(xhr.responseText));
                    const now = new Date();
                    const sunriseHour = parsed.sunriseDate ? parsed.sunriseDate.getHours() : -1;
                    const sunriseMinute = parsed.sunriseDate ? parsed.sunriseDate.getMinutes() : 0;
                    const sunsetHour = parsed.sunsetDate ? parsed.sunsetDate.getHours() : -1;
                    const sunsetMinute = parsed.sunsetDate ? parsed.sunsetDate.getMinutes() : 0;
                    const bestEvent = root._bestAstroEvent(sunriseHour, sunriseMinute, sunsetHour, sunsetMinute, now);

                    const aqiUrl = "https://air-quality-api.open-meteo.com/v1/air-quality"
                        + "?latitude=" + lat
                        + "&longitude=" + lon
                        + "&hourly=us_aqi"
                        + "&timezone=auto"
                        + "&forecast_days=1";

                    const aqiXhr = new XMLHttpRequest();
                    aqiXhr.open("GET", aqiUrl);
                    aqiXhr.timeout = 10000;
                    aqiXhr.onreadystatechange = function () {
                        if (aqiXhr.readyState !== XMLHttpRequest.DONE)
                            return;
                        let aqiVal = "—";
                        if (aqiXhr.status === 200) {
                            try {
                                const aqiData = JSON.parse(aqiXhr.responseText);
                                const times = aqiData.hourly.time;
                                const aqiArr = aqiData.hourly.us_aqi;
                                const nowHour = new Date();
                                nowHour.setMinutes(0, 0, 0);
                                const nowStr = nowHour.toISOString().slice(0, 16);
                                let idx = times.indexOf(nowStr);
                                if (idx < 0) idx = 0;
                                const aqiParsed = aqiArr[idx];
                                if (aqiParsed !== null && aqiParsed !== undefined) {
                                    aqiVal = String(Math.round(aqiParsed));
                                }
                            } catch (e) {
                                console.warn("[LocaleService] Query AQI parse error:", e);
                            }
                        }

                        callback(null, {
                            temp: parsed.temp,
                            feelsLike: parsed.feelsLike,
                            high: parsed.high,
                            low: parsed.low,
                            humidity: parsed.humidity,
                            uvi: parsed.uvi,
                            rainChance: parsed.rainChance,
                            astroTime: bestEvent ? root._formatAstroTime(bestEvent.time) : "—",
                            astroIcon: bestEvent ? bestEvent.materialIcon : "wb-twilight",
                            astroColorType: bestEvent ? bestEvent.colorType : "sun",
                            location: prettyLocation,
                            desc: parsed.desc,
                            iconName: parsed.iconName,
                            iconColor: root._colorForRole(parsed.iconColorRole),
                            aqi: aqiVal
                        });
                    };
                    aqiXhr.send();

                } catch (e) {
                    callback("Parse error", null);
                }
            } else {
                callback("HTTP error " + xhr.status, null);
            }
        };
        xhr.send();
    }

    property real _lat: 0.0
    property real _lon: 0.0
    property bool _coordsKnown: false

    property var _aqiTimer: Timer {
        interval: 1800000
        running: NetworkService.isOnline
        repeat: true
        triggeredOnStart: true
        onTriggered: root._maybeFetchAqi()
    }

    function _maybeFetchAqi() {
        if (!NetworkService.isOnline) {
            root._aqiError = Localization.t("weather.offline");
            root._aqiLoading = false;
            return;
        }

        if (typeof Config.latitude !== "undefined" && typeof Config.longitude !== "undefined" && Config.latitude !== 0 && Config.longitude !== 0) {
            _lat = Config.latitude;
            _lon = Config.longitude;
            _coordsKnown = true;
        }

        if (_coordsKnown) {
            _fetchAqi(_lat, _lon);
        } else if (Config.cityName && Config.cityName !== "") {
            _resolveCityCoords(Config.cityName, function (lat, lon) {
                _lat = lat;
                _lon = lon;
                _coordsKnown = true;
                _fetchAqi(lat, lon);
                _fetchWeather();
            });
        } else {
            _resolveCoords(function (lat, lon, cityName) {
                _lat = lat;
                _lon = lon;
                _coordsKnown = true;
                if (cityName)
                    root._weatherLocation = cityName;
                _fetchAqi(lat, lon);
                _fetchWeather();
            });
        }
    }

    function _resolveCoords(callback) {
        if (!NetworkService.isOnline) return;

        const xhr = new XMLHttpRequest();
        xhr.open("GET", "https://freeipapi.com/api/json");
        xhr.timeout = 10000;
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status === 200) {
                try {
                    const data = JSON.parse(xhr.responseText);
                    const lat = parseFloat(data.latitude);
                    const lon = parseFloat(data.longitude);
                    if (!isNaN(lat) && !isNaN(lon)) {
                        callback(lat, lon, data.cityName || "");
                    } else {
                        console.warn("[LocaleService] Invalid coords resolved:", data.latitude, data.longitude);
                    }
                } catch (e) {
                    console.warn("[LocaleService] Geolocation parse error:", e);
                }
            } else {
                console.warn("[LocaleService] Geolocation failed with status:", xhr.status);
            }
        };
        xhr.send();
    }

    function _fetchAqi(lat, lon) {
        if (!NetworkService.isOnline) return;

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
