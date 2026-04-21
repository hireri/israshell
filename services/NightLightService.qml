pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.style

Singleton {
    id: root

    property bool active: false
    property int currentTemp: Config.nightLight.dayTemp

    property bool _manualOverride: false
    property bool _lastIsNight: false
    property bool _initialCheckDone: false

    Component.onCompleted: pollProc.running = true

    property var _watchedConfig: Config.nightLight
    on_WatchedConfigChanged: _reapplySchedule()

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            if (!pollProc.running)
                pollProc.running = true;
        }
    }

    Process {
        id: pollProc
        command: ["hyprctl", "hyprsunset", "temperature"]
        stdout: SplitParser {
            onRead: data => {
                const temp = parseInt(data.trim(), 10);
                if (!isNaN(temp)) {
                    root.currentTemp = temp;

                    if (!root._initialCheckDone) {
                        root._initialCheckDone = true;
                        const nl = Config.nightLight;
                        const isNight = _isNight(nl);
                        root._lastIsNight = isNight;

                        if (nl.scheduleEnabled) {
                            root.active = isNight;
                            const expected = isNight ? nl.nightTemp : nl.dayTemp;
                            if (temp !== expected)
                                _applyTemp(expected);
                        }

                        if (nl.autoDarkMode) {
                            if (WallpaperService.isDark !== isNight) {
                                WallpaperService.isDark = isNight;
                            } else {
                                WallpaperService.applyTheme();
                            }
                        }
                    }
                }
            }
        }
        onExited: {
            if (!checkProc.running)
                checkProc.running = true;
        }
    }

    Process {
        id: checkProc
        command: ["pgrep", "-x", "hyprsunset"]
        running: false
        stdout: SplitParser {
            onRead: data => {}
        }
        onExited: code => {
            if (code !== 0) {
                Quickshell.execDetached(["hyprsunset"]);
                restartApplyTimer.start();
            }
        }
    }

    Timer {
        id: restartApplyTimer
        interval: 400
        repeat: false
        onTriggered: _applyTemp(root.active ? Config.nightLight.nightTemp : Config.nightLight.dayTemp)
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            const nl = Config.nightLight;
            const isNight = _isNight(nl);

            if (isNight === root._lastIsNight)
                return;

            root._lastIsNight = isNight;
            root._manualOverride = false;

            if (nl.scheduleEnabled) {
                root.active = isNight;
                _applyTemp(isNight ? nl.nightTemp : nl.dayTemp);
            }

            if (nl.autoDarkMode) {
                WallpaperService.isDark = isNight;
                WallpaperService.applyTheme();
            }
        }
    }

    function _reapplySchedule() {
        const nl = Config.nightLight;
        const isNight = _isNight(nl);
        root._lastIsNight = isNight;
        root._manualOverride = false;

        if (nl.scheduleEnabled) {
            root.active = isNight;
            const expected = isNight ? nl.nightTemp : nl.dayTemp;
            if (root.currentTemp !== expected)
                _applyTemp(expected);
        }

        if (nl.autoDarkMode)
            WallpaperService.isDark = isNight;
    }

    function _isNight(nl) {
        const now = new Date();
        const minutes = now.getHours() * 60 + now.getMinutes();
        const sunset = _timeToMinutes(nl.sunset);
        const sunrise = _timeToMinutes(nl.sunrise);

        if (sunset === sunrise)
            return false;

        if (sunset < sunrise)
            return minutes >= sunset && minutes < sunrise;

        return minutes >= sunset || minutes < sunrise;
    }

    function _applyTemp(temp) {
        Quickshell.execDetached(["hyprctl", "hyprsunset", "temperature", String(temp)]);
    }

    function _timeToMinutes(timeStr) {
        const parts = timeStr.split(":");
        return parseInt(parts[0], 10) * 60 + parseInt(parts[1], 10);
    }

    function toggle() {
        root._manualOverride = true;
        root.active = !root.active;
        _applyTemp(root.active ? Config.nightLight.nightTemp : Config.nightLight.dayTemp);
    }

    function setNightTemp(temp) {
        Config.update({
            nightLight: Object.assign({}, Config.nightLight, {
                nightTemp: temp
            })
        });
        if (!Config.nightLight.scheduleEnabled && root.active)
            _applyTemp(temp);
    }

    function setDayTemp(temp) {
        Config.update({
            nightLight: Object.assign({}, Config.nightLight, {
                dayTemp: temp
            })
        });
        if (!Config.nightLight.scheduleEnabled && !root.active)
            _applyTemp(temp);
    }

    function setSunrise(time) {
        Config.update({
            nightLight: Object.assign({}, Config.nightLight, {
                sunrise: time
            })
        });
    }

    function setSunset(time) {
        Config.update({
            nightLight: Object.assign({}, Config.nightLight, {
                sunset: time
            })
        });
    }
}
