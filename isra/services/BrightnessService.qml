pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property real gamma: _gamma / 100.0
    readonly property int _gamma: {
        let v = parseInt(_gammaText.trim());
        return isNaN(v) ? 100 : v;
    }

    readonly property real value: gamma
    readonly property real from: 0.1
    readonly property real to: 1.0

    property string _gammaText: "100"

    function setBrightness(val) {
        let gammaVal = Math.round(Math.max(1, Math.min(100, val * 100)));
        setGammaProc.command = ["hyprctl", "hyprsunset", "gamma", String(gammaVal)];
        setGammaProc.running = false;
        setGammaProc.running = true;
        _gammaText = String(gammaVal);
    }

    function adjustBrightness(delta) {
        let newGamma = Math.round(Math.max(1, Math.min(100, _gamma + delta)));
        setBrightness(newGamma / 100.0);
    }

    Process {
        id: getGammaProc
        running: true
        command: ["hyprctl", "hyprsunset", "gamma"]
        stdout: StdioCollector {
            onStreamFinished: {
                root._gammaText = text;
            }
        }
    }

    Process {
        id: setGammaProc
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            getGammaProc.running = false;
            getGammaProc.running = true;
        }
    }
}
