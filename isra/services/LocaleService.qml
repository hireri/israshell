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
    readonly property string weatherCode: _weatherCode
    
    readonly property string weatherIconName: _weatherIconName
    readonly property color weatherIconColor: {
        switch (_weatherIconColorRole) {
        case "tertiary": return Colors.md3.tertiary;
        case "on_surface_variant": return Colors.md3.on_surface_variant;
        case "outline": return Colors.md3.outline;
        case "error": return Colors.md3.error;
        default: return Colors.md3.primary;
        }
    }

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

    property string _rawSunrise: ""
    property string _rawSunset: ""
    property string _rawMoonrise: ""
    property string _rawMoonset: ""

    property string _weatherTemp: "—"
    property string _weatherFeelsLike: "—"
    property string _weatherRainChance: "—"
    property string _weatherHigh: "—"
    property string _weatherLow: "—"
    property string _weatherDesc: "loading…"
    property string _weatherHumid: "—"
    property string _weatherUvi: "—"
    property string _weatherSunrise: "—"
    property string _weatherSunset: "—"
    property string _weatherCode: "0"
    property bool _weatherLoading: true
    property string _weatherError: ""

    property string _weatherIconName: "partly-cloudy-day"
    property string _weatherIconColorRole: "primary"

    property string _weatherAqi: "—"
    property bool _aqiLoading: true
    property string _aqiError: ""

    property var _lastWeatherData: null

    Connections {
        target: Config

        function onUseFarenheitChanged() { root._fetchWeather(); }
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

        function onLatitudeChanged() {
            root._coordsKnown = false;
            root._maybeFetchAqi();
            root._fetchWeather();
        }
        function onLongitudeChanged() {
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
        _liveAmPm = Config.hourFormat === 0 ? "" : (isPm ? (Config.hourFormat === 2 ? " PM" : " pm") : (Config.hourFormat === 2 ? " AM" : " am"));
        _liveDayName = Qt.formatDate(now, "dddd");
        _liveFullDate = Qt.formatDate(now, "dd MMMM yyyy");

        const barTimeFmt = Config.timeFormat !== "" ? Config.timeFormat : root._dynamicTimeFormat();
        _barTimeText = Qt.formatDateTime(now, barTimeFmt);

        const barDateFmt = Config.dateFormat !== "" ? Config.dateFormat : root._dynamicDateFormat();
        _barDateText = Qt.formatDateTime(now, barDateFmt);
        _shortDateText = Qt.formatDateTime(now, Config.dateOrder === 1 ? "ddd, MMM dd" : "ddd, dd MMM");

        root._updateAstroEvent(now);
    }

    function _parseOpenMeteoDateTime(str) {
        if (!str) return null;
        const parts = str.split('T');
        if (parts.length !== 2) return null;
        const dateParts = parts[0].split('-');
        const timeParts = parts[1].split(':');
        if (dateParts.length !== 3 || timeParts.length < 2) return null;
        
        const year = parseInt(dateParts[0]);
        const month = parseInt(dateParts[1]) - 1;
        const day = parseInt(dateParts[2]);
        const hour = parseInt(timeParts[0]);
        const minute = parseInt(timeParts[1]);
        
        return new Date(year, month, day, hour, minute, 0, 0);
    }

    function _dateToAstroRaw(date) {
        if (!date || isNaN(date.getTime())) return "";
        let hours = date.getHours();
        const minutes = String(date.getMinutes()).padStart(2, '0');
        const ampm = hours >= 12 ? "pm" : "am";
        hours = hours % 12 || 12;
        return hours + ":" + minutes + " " + ampm;
    }

    function _parseAstroTime(timeStr, referenceDate) {
        if (!timeStr) return null;
        const cleanStr = timeStr.trim().toLowerCase();
        if (cleanStr.includes("no") || cleanStr === "" || cleanStr === "—") {
            return null;
        }

        const match = cleanStr.match(/^(\d{1,2}):(\d{2})\s*(am|pm)$/);
        if (!match) return null;

        let hours = parseInt(match[1], 10);
        const minutes = parseInt(match[2], 10);
        const ampm = match[3];

        if (ampm === "pm" && hours < 12) {
            hours += 12;
        } else if (ampm === "am" && hours === 12) {
            hours = 0;
        }

        const d = new Date(referenceDate);
        d.setHours(hours, minutes, 0, 0);
        return d;
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

    function _updateAstroEvent(now) {
        if (!root._rawSunrise && !root._rawSunset && !root._rawMoonrise && !root._rawMoonset) {
            root._activeAstroName = "—";
            root._activeAstroTime = "—";
            root._activeAstroMaterialIcon = "wb-twilight";
            root._activeAstroColorType = "sun";
            return;
        }

        const events = [
            { name: "Sunrise", materialIcon: "wb-twilight", colorType: "sun", raw: root._rawSunrise },
            { name: "Sunset", materialIcon: "wb-twilight", colorType: "sun", raw: root._rawSunset },
            { name: "Moonrise", materialIcon: "wb-twilight2", colorType: "moon", raw: root._rawMoonrise },
            { name: "Moonset", materialIcon: "wb-twilight2", colorType: "moon", raw: root._rawMoonset }
        ];

        let bestEvent = null;
        let bestDiff = Infinity;
        const oneDayMs = 24 * 60 * 60 * 1000;

        events.forEach(function(ev) {
            const todayTime = root._parseAstroTime(ev.raw, now);
            if (!todayTime) return;

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

    function _fetchWeather() {
        if (!NetworkService.isOnline) {
            root._weatherError = "Offline";
            root._weatherLoading = false;
            return;
        }

        if (!_coordsKnown) {
            root._maybeFetchAqi();
            return;
        }

        const tempUnit = Config.useFarenheit ? "fahrenheit" : "celsius";
        const url = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=" + _lat
            + "&longitude=" + _lon
            + "&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,is_day"
            + "&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max"
            + "&hourly=precipitation_probability"
            + "&temperature_unit=" + tempUnit
            + "&timezone=auto"
            + "&forecast_days=1";

        const xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        xhr.timeout = 15000;
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status === 200) {
                try {
                    const data = JSON.parse(xhr.responseText);
                    root._lastWeatherData = data;
                    root._applyWeatherData(data);
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

    function _getWmoDetails(wmoCode, isDay) {
        const c = parseInt(wmoCode);
        const day = parseInt(isDay) !== 0;
        let iconName = "partly-cloudy-day";
        let colorRole = "primary";
        let desc = "Unknown";

        if (c === 0) {
            if (day) {
                iconName = "wb-sunny";
                colorRole = "tertiary";
                desc = "Sunny";
            } else {
                iconName = "moon-stars"; 
                colorRole = "primary";
                desc = "Clear Night";
            }
        } else if (c === 1 || c === 2) {
            if (day) {
                iconName = "partly-cloudy-day";
                colorRole = "primary";
                desc = "Partly Cloudy";
            } else {
                iconName = "partly-cloudy-night"; 
                colorRole = "primary";
                desc = "Partly Cloudy";
            }
        } else if (c === 3) {
            iconName = "cloudy";
            colorRole = "on_surface_variant";
            desc = "Overcast";
        } else if (c === 45 || c === 48) {
            iconName = "foggy";
            colorRole = "on_surface_variant";
            desc = "Foggy";
        } else if ([51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82].includes(c)) {
            iconName = "rainy";
            colorRole = "primary";
            desc = c < 60 ? "Drizzle" : "Rain";
        } else if ([71, 73, 75, 77, 85, 86].includes(c)) {
            iconName = "snowy";
            colorRole = "outline";
            desc = "Snow";
        } else if ([95, 96, 99].includes(c)) {
            iconName = "thunderstorm";
            colorRole = "error";
            desc = "Thunderstorm";
        }
        
        return { iconName: iconName, colorRole: colorRole, desc: desc };
    }

    function _updateWeatherIcon(wmoCode, isDay) {
        const details = _getWmoDetails(wmoCode, isDay);
        _weatherIconName = details.iconName;
        _weatherIconColorRole = details.colorRole;
        _weatherDesc = details.desc;
    }

    function _applyWeatherData(data) {
        try {
            const cur = data.current;
            const daily = data.daily;
            const hourly = data.hourly;

            root._weatherTemp = Math.round(cur.temperature_2m) + "°";
            root._weatherFeelsLike = Math.round(cur.apparent_temperature) + "°";

            const precipProb = hourly.precipitation_probability || [];
            let maxChance = 0;
            for (let i = 0; i < Math.min(24, precipProb.length); i++) {
                let chance = parseInt(precipProb[i]);
                if (chance > maxChance) {
                    maxChance = chance;
                }
            }
            root._weatherRainChance = String(maxChance) + "%";

            root._weatherHigh = Math.round(daily.temperature_2m_max[0]) + "°";
            root._weatherLow = Math.round(daily.temperature_2m_min[0]) + "°";
            
            root._weatherHumid = Math.round(cur.relative_humidity_2m) + "%";
            root._weatherUvi = String(Math.round(daily.uv_index_max[0] || 0));

            const sunriseDate = _parseOpenMeteoDateTime(daily.sunrise[0]);
            const sunsetDate = _parseOpenMeteoDateTime(daily.sunset[0]);

            root._weatherSunrise = sunriseDate ? _formatAstroTime(sunriseDate) : "—";
            root._weatherSunset = sunsetDate ? _formatAstroTime(sunsetDate) : "—";
            
            root._weatherCode = String(cur.weather_code);
            root._updateWeatherIcon(cur.weather_code, cur.is_day);
            root._weatherError = "";

            root._rawSunrise = sunriseDate ? _dateToAstroRaw(sunriseDate) : "";
            root._rawSunset = sunsetDate ? _dateToAstroRaw(sunsetDate) : "";
            root._rawMoonrise = "";
            root._rawMoonset = "";

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
        const tempUnit = Config.useFarenheit ? "fahrenheit" : "celsius";
        const url = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=" + lat
            + "&longitude=" + lon
            + "&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,is_day"
            + "&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max"
            + "&hourly=precipitation_probability"
            + "&temperature_unit=" + tempUnit
            + "&timezone=auto"
            + "&forecast_days=1";

        const xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        xhr.timeout = 15000;
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status === 200) {
                try {
                    const data = JSON.parse(xhr.responseText);
                    const cur = data.current;
                    const daily = data.daily;
                    const hourly = data.hourly;

                    const temp = Math.round(cur.temperature_2m) + "°";
                    const feelsLike = Math.round(cur.apparent_temperature) + "°";
                    const high = Math.round(daily.temperature_2m_max[0]) + "°";
                    const low = Math.round(daily.temperature_2m_min[0]) + "°";
                    const humidity = Math.round(cur.relative_humidity_2m) + "%";
                    const uvi = String(Math.round(daily.uv_index_max[0] || 0));

                    const precipProb = hourly.precipitation_probability || [];
                    let maxChance = 0;
                    for (let i = 0; i < Math.min(24, precipProb.length); i++) {
                        let chance = parseInt(precipProb[i]);
                        if (chance > maxChance) {
                            maxChance = chance;
                        }
                    }
                    const rainChance = String(maxChance) + "%";

                    const sunriseDate = _parseOpenMeteoDateTime(daily.sunrise[0]);
                    const sunsetDate = _parseOpenMeteoDateTime(daily.sunset[0]);

                    let activeAstroTime = "—";
                    let activeAstroIcon = "wb-twilight";
                    let activeAstroColorType = "sun";

                    const now = new Date();
                    if (sunriseDate && sunsetDate) {
                        const oneDayMs = 24 * 60 * 60 * 1000;
                        const events = [
                            { name: "Sunrise", icon: "wb-twilight", colorType: "sun", time: sunriseDate },
                            { name: "Sunset", icon: "wb-twilight", colorType: "sun", time: sunsetDate }
                        ];

                        let bestEvent = null;
                        let bestDiff = Infinity;

                        events.forEach(function(ev) {
                            const times = [ev.time, new Date(ev.time.getTime() - oneDayMs)];
                            times.forEach(function(t) {
                                const diff = now.getTime() - t.getTime();
                                if (diff >= 0 && diff < bestDiff) {
                                    bestDiff = diff;
                                    bestEvent = {
                                        name: ev.name,
                                        icon: ev.icon,
                                        colorType: ev.colorType,
                                        time: t
                                    };
                                }
                            });
                        });

                        if (bestEvent) {
                            activeAstroTime = _formatAstroTime(bestEvent.time);
                            activeAstroIcon = bestEvent.icon;
                            activeAstroColorType = bestEvent.colorType;
                        }
                    } else if (sunriseDate) {
                        activeAstroTime = _formatAstroTime(sunriseDate);
                    }

                    const details = _getWmoDetails(cur.weather_code, cur.is_day);
                    
                    let mappedColor = Colors.md3.primary;
                    switch (details.colorRole) {
                    case "tertiary": mappedColor = Colors.md3.tertiary; break;
                    case "on_surface_variant": mappedColor = Colors.md3.on_surface_variant; break;
                    case "outline": mappedColor = Colors.md3.outline; break;
                    case "error": mappedColor = Colors.md3.error; break;
                    }

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
                            temp: temp,
                            feelsLike: feelsLike,
                            high: high,
                            low: low,
                            humidity: humidity,
                            uvi: uvi,
                            rainChance: rainChance,
                            astroTime: activeAstroTime,
                            astroIcon: activeAstroIcon,
                            astroColorType: activeAstroColorType,
                            location: prettyLocation,
                            desc: details.desc,
                            iconName: details.iconName,
                            iconColor: mappedColor,
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
            root._aqiError = "Offline";
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
            _resolveCoords(function (lat, lon) {
                _lat = lat;
                _lon = lon;
                _coordsKnown = true;
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
                        callback(lat, lon);
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