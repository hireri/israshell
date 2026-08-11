pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.style
import qs.services

Singleton {
    id: root

    readonly property bool _isHyprland: CompositorService.backendName === "hyprland"
    readonly property string _binary: root._isHyprland ? "hyprsunset" : "wlsunset"

    property bool active: false
    property int currentTemp: Config.nightLight.dayTemp

    property bool _lastIsNight: false
    property bool _initialCheckDone: false
    property int _pendingWlsunsetTemp: Config.nightLight.dayTemp

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
        command: root._isHyprland ? ["hyprctl", "hyprsunset", "temperature"] : ["pgrep", "-a", "-x", "wlsunset"]
        stdout: SplitParser {
            onRead: data => {
                const temp = root._isHyprland ? parseInt(data.trim(), 10) : root._parseWlsunsetTemp(data);
                if (!isNaN(temp)) {
                    root.currentTemp = temp;

                    if (!root._initialCheckDone) {
                        root._initialCheckDone = true;
                        const nl = Config.nightLight;
                        const isNight = _isNight(nl);
                        root._lastIsNight = isNight;
                        root.active = (temp === nl.nightTemp);
                        root._syncToSchedule(nl, isNight);
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
        command: ["pgrep", "-x", root._binary]
        running: false
        stdout: SplitParser {
            onRead: data => {}
        }
        onExited: code => {
            if (code !== 0) {
                if (root._isHyprland) {
                    Quickshell.execDetached(["hyprsunset"]);
                    restartApplyTimer.start();
                } else {
                    _applyTemp(root.active ? Config.nightLight.nightTemp : Config.nightLight.dayTemp);
                }
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
        id: wlsunsetRestartTimer
        interval: 200
        repeat: false
        onTriggered: Quickshell.execDetached(["wlsunset", "-t", String(root._pendingWlsunsetTemp), "-T", String(root._pendingWlsunsetTemp)])
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
            root._syncToSchedule(nl, isNight);
        }
    }

    function _reapplySchedule() {
        const nl = Config.nightLight;
        const isNight = _isNight(nl);
        root._lastIsNight = isNight;
        root._syncToSchedule(nl, isNight);
    }

    function _expectedTemp(nl, isNight) {
        return isNight ? nl.nightTemp : nl.dayTemp;
    }

    function _syncToSchedule(nl, isNight) {
        if (nl.scheduleEnabled) {
            root.active = isNight;
            const expected = _expectedTemp(nl, isNight);
            if (root.currentTemp !== expected)
                _applyTemp(expected);
        }

        if (nl.autoDarkMode) {
            WallpaperService.isDark = isNight;
            WallpaperService.applyTheme();
        }
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
        if (root._isHyprland) {
            Quickshell.execDetached(["hyprctl", "hyprsunset", "temperature", String(temp)]);
        } else {
            root._pendingWlsunsetTemp = temp;
            Quickshell.execDetached(["pkill", "-x", "wlsunset"]);
            wlsunsetRestartTimer.restart();
        }
    }

    function _parseWlsunsetTemp(line) {
        const match = line.match(/-t\s+(\d+)/);
        return match ? parseInt(match[1], 10) : NaN;
    }

    function _timeToMinutes(timeStr) {
        const parts = timeStr.split(":");
        return parseInt(parts[0], 10) * 60 + parseInt(parts[1], 10);
    }

    function toggle() {
        root.active = !root.active;
        _applyTemp(root.active ? Config.nightLight.nightTemp : Config.nightLight.dayTemp);
    }

    function _patchNightLight(patch) {
        Config.update({
            nightLight: Object.assign({}, Config.nightLight, patch)
        });
    }

    function setNightTemp(temp) {
        _patchNightLight({ nightTemp: temp });
        if (!Config.nightLight.scheduleEnabled && root.active)
            _applyTemp(temp);
    }

    function setDayTemp(temp) {
        _patchNightLight({ dayTemp: temp });
        if (!Config.nightLight.scheduleEnabled && !root.active)
            _applyTemp(temp);
    }

    function setSunrise(time) {
        _patchNightLight({ sunrise: time });
    }

    function setSunset(time) {
        _patchNightLight({ sunset: time });
    }
}
