pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.style

Singleton {
    id: service

    property var targetValues: []
    property bool cavaEnabled: Config.cava.enabled
    property bool commandReady: true

    function rearrange(arr, layout) {
        if (!arr || arr.length < 2) return arr;

        var m = Math.floor(arr.length / 2);
        var left = arr.slice(0, m);
        var right = arr.slice(m);

        if (layout === "edges") {
            var leftMirrored = left.slice().reverse();
            var rightMirrored = right.slice().reverse();
            return leftMirrored.concat(rightMirrored);
        }
        if (layout === "mono") {
            var leftAligned = left.slice().reverse();
            var combined = [];
            for (var i = 0; i < right.length; i++) {
                combined.push((leftAligned[i] + right[i]) / 2);
            }
            return combined;
        }
        return arr;
    }

    readonly property var cavaCommand: [
        "bash", "-c",
        "printf '" +
        "[general]\\n" +
        "framerate = 60\\n" +
        "bars = " + Config.cava.bars + "\\n" +
        "[output]\\n" +
        "method = raw\\n" +
        "raw_target = /dev/stdout\\n" +
        "data_format = ascii\\n" +
        "ascii_max_range = 100\\n" +
        "bar_delimiter = 59\\n" +
        "frame_delimiter = 10\\n" +
        "[smoothing]\\n" +
        "monstercat = 1\\n" +
        "noise_reduction = 0.77\\n" +
        "' > /tmp/cava_quickshell.conf && exec cava -p /tmp/cava_quickshell.conf"
    ]

    property int _lastBars: Config.cava.bars

    Connections {
        target: Config
        function onCavaChanged() {
            if (Config.cava.bars !== service._lastBars) {
                service._lastBars = Config.cava.bars;
                if (service.commandReady) {
                    service.commandReady = false;
                    restartTimer.restart();
                }
            }
        }
    }

    onCavaEnabledChanged: {
        if (cavaEnabled) {
            retryTimer.stop();
        } else {
            targetValues = [];
        }
    }

    Timer {
        id: restartTimer
        interval: 100
        repeat: false
        onTriggered: {
            service.commandReady = true;
        }
    }

    Timer {
        id: retryTimer
        interval: 5000
        repeat: false
    }

    Process {
        id: cavaProcess
        command: service.cavaCommand
        
        running: service.cavaEnabled && !retryTimer.running && service.commandReady

        stdout: SplitParser {
            onRead: data => {
                var clean = data.trim();
                if (!clean) return;

                var parts = clean.split(';');
                if (parts.length > 0 && parts[parts.length - 1] === "") {
                    parts.pop();
                }

                var rawValues = parts.map(v => parseInt(v) || 0);
                service.targetValues = service.rearrange(rawValues, Config.cava.layout);
            }
        }

        onExited: {
            if (service.cavaEnabled && service.commandReady) {
                retryTimer.restart();
            }
        }
    }
}