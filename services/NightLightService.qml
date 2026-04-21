pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.style

Singleton {
    id: root

    property bool active: false
    property int currentTemp: 6300

    Component.onCompleted: _poll()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: _poll()
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            const nl = Config.nightLight;
            const now = new Date();
            const minutes = now.getHours() * 60 + now.getMinutes();
            const shouldBeNight = minutes >= root._timeToMinutes(nl.sunset) || minutes < root._timeToMinutes(nl.sunrise);
            if (shouldBeNight !== root.active) {
                root.active = shouldBeNight;
                _applyTemp(shouldBeNight ? nl.nightTemp : nl.dayTemp);
            }
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
    }

    function _poll() {
        pollProc.running = false;
        pollProc.running = true;
    }

    Process {
        id: checkProc
        command: ["pgrep", "-x", "hyprsunset"]
        stdout: SplitParser {
            onRead: data => {}
        }
        onExited: code => {
            if (code !== 0) {
                const nl = Config.nightLight;
                _applyTemp(root.active ? nl.nightTemp : nl.dayTemp);
            }
        }
    }

    function _applyTemp(temp) {
        Quickshell.execDetached(["hyprctl", "hyprsunset", "temperature", String(temp)]);
    }

    function _timeToMinutes(timeStr) {
        const parts = timeStr.split(":");
        return parseInt(parts[0], 10) * 60 + parseInt(parts[1], 10);
    }

    function toggle() {
        const nl = Config.nightLight;
        root.active = !root.active;
        _applyTemp(root.active ? nl.nightTemp : nl.dayTemp);
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
