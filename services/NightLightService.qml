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
        interval: 5000
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
                const dayTemp = Config.dayLightTemp || 6500;

                if (!isNaN(currentTemp)) {
                    root.active = (currentTemp < dayTemp);
                }
            }
        }
    }

    Process {
        id: enableProc
        command: ["hyprctl", "hyprsunset", "temperature", String(Config.nightLightTemp || 4000)]
        onExited: tempProc.running = true
    }

    Process {
        id: disableProc
        command: ["hyprctl", "hyprsunset", "temperature", String(Config.dayLightTemp || 6500)]
        onExited: tempProc.running = true
    }

    function toggle() {
        if (root.active) {
            root.active = false;
            disableProc.running = true;
        } else {
            root.active = true;
            enableProc.running = true;
        }

        pollTimer.restart();
    }
}
