pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.style

Singleton {
    id: root

    property bool active: false
    property int currentTemp: Config.nightLight.dayTemp

    Component.onCompleted: {
        if (!pollProc.running)
            pollProc.running = true;
    }

    Timer {
        interval: 1000
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
                    const nl = Config.nightLight;
                    const mid = (nl.nightTemp + nl.dayTemp) / 2;
                    root.active = temp <= mid;
                }
            }
        }
        onExited: {
            if (!checkProc.running)
                checkProc.running = true;
        }
    }

    property bool _lastIsNight: false
    property bool _scheduleInitialized: false

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            if (!pollProc.running)
                pollProc.running = true;

            const nl = Config.nightLight;
            const now = new Date();
            const minutes = now.getHours() * 60 + now.getMinutes();
            const isNight = minutes >= root._timeToMinutes(nl.sunset) || minutes < root._timeToMinutes(nl.sunrise);

            if (!root._scheduleInitialized) {
                root._lastIsNight = isNight;
                root._scheduleInitialized = true;
                return;
            }

            if (isNight === root._lastIsNight)
                return;

            root._lastIsNight = isNight;

            if (nl.scheduleEnabled)
                _applyTemp(isNight ? nl.nightTemp : nl.dayTemp);

            if (nl.autoDarkMode)
                WallpaperService.isDark = isNight;
        }
    }

    Process {
        id: checkProc
        command: ["pgrep", "-x", "hyprsunset"]
        stdout: SplitParser {
            onRead: data => {}
        }
        onExited: code => {
            if (code !== 0) {
                Quickshell.execDetached(["hyprsunset"]);
                applyTimer.targetTemp = _targetTemp();
                applyTimer.start();
            }
        }
    }

    Timer {
        id: applyTimer
        interval: 400
        repeat: false
        property int targetTemp: Config.nightLight.dayTemp
        onTriggered: _applyTemp(targetTemp)
    }

    function _targetTemp() {
        const nl = Config.nightLight;
        const now = new Date();
        const minutes = now.getHours() * 60 + now.getMinutes();
        const isNight = minutes >= _timeToMinutes(nl.sunset) || minutes < _timeToMinutes(nl.sunrise);
        root.active = isNight;
        return isNight ? nl.nightTemp : nl.dayTemp;
    }

    function _applyTemp(temp) {
        Quickshell.execDetached(["hyprctl", "hyprsunset", "temperature", String(temp)]);
    }

    function _timeToMinutes(timeStr) {
        const parts = timeStr.split(":");
        return parseInt(parts[0], 10) * 60 + parseInt(parts[1], 10);
    }

    function toggle() {
        root.active = !root.active;
        _applyTemp(root.active ? Config.nightLight.nightTemp : Config.nightLight.dayTemp);
    }

    function setNightTemp(temp) {
        Config.update({
            nightLight: Object.assign({}, Config.nightLight, {
                nightTemp: temp
            })
        });
        if (root.active)
            _applyTemp(temp);
    }

    function setDayTemp(temp) {
        Config.update({
            nightLight: Object.assign({}, Config.nightLight, {
                dayTemp: temp
            })
        });
        if (!root.active)
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
