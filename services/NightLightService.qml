pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.style

Singleton {
    id: root

    property bool active: false

    Timer {
        id: pollTimer
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: tempProc.running = true
    }

    Process {
        id: tempProc
        command: ["hyprctl", "hyprsunset", "temperature"]

        stdout: StdioCollector {
            id: tempOutput

            onStreamFinished: {
                const currentTemp = parseInt(tempOutput.text.trim(), 10);
                const dayTemp = Config.nightLight.dayTemp ?? 6500;
                if (!isNaN(currentTemp)) {
                    const shouldBeActive = currentTemp < dayTemp;

                    if (shouldBeActive !== root.active)
                        root.active = shouldBeActive;
                }
            }
        }
    }

    Process {
        id: enableProc
        command: ["hyprctl", "hyprsunset", "temperature", String(Config.nightLight.temp ?? 4000)]
        onExited: tempProc.running = true
    }

    Process {
        id: disableProc
        command: ["hyprctl", "hyprsunset", "temperature", String(Config.nightLight.dayTemp ?? 6500)]
        onExited: tempProc.running = true
    }

    function toggle() {
        root.active = !root.active;
        if (root.active) {
            enableProc.command = ["hyprctl", "hyprsunset", "temperature", String(Config.nightLight.temp ?? 4000)];
            enableProc.running = false;
            enableProc.running = true;
        } else {
            disableProc.command = ["hyprctl", "hyprsunset", "temperature", String(Config.nightLight.dayTemp ?? 6500)];
            disableProc.running = false;
            disableProc.running = true;
        }
        pollTimer.restart();
    }

    function setNightTemp(temp) {
        const nl = Object.assign({}, Config.nightLight, {
            temp: temp
        });
        Config.update({
            nightLight: nl
        });

        if (root.active) {
            enableProc.command = ["hyprctl", "hyprsunset", "temperature", String(temp)];
            enableProc.running = false;
            enableProc.running = true;
        }
    }

    function setDayTemp(temp) {
        const nl = Object.assign({}, Config.nightLight, {
            dayTemp: temp
        });
        Config.update({
            nightLight: nl
        });

        if (!root.active) {
            disableProc.command = ["hyprctl", "hyprsunset", "temperature", String(temp)];
            disableProc.running = false;
            disableProc.running = true;
        }
    }
}
