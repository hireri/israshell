pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.style

Singleton {
    id: service

    property var targetValues: []
    property bool cavaEnabled: Config.cava.enabled
    
    property int activeBars: Config.cava.bars + (Config.cava.bars % 2)
    
    property bool restarting: false

    function updateProcessState() {
        var shouldBeRunning = service.cavaEnabled && !retryTimer.running;
        if (cavaProcess.running !== shouldBeRunning) {
            cavaProcess.running = shouldBeRunning;
        }
    }

    function rearrange(arr, layout) {
        if (!arr || arr.length < 2) return arr;

        var m = Math.floor(arr.length / 2);

        if (layout === "edges") {
            var left = arr.slice(0, m);
            var right = arr.slice(m);
            return left.reverse().concat(right.reverse());
        }
        
        if (layout === "mono") {
            var leftAligned = arr.slice(0, m).reverse();
            var rightAligned = arr.slice(m);
            var combined = [];
            var maxLen = Math.max(leftAligned.length, rightAligned.length);
            
            for (var i = 0; i < maxLen; i++) {
                var lVal = leftAligned[i];
                var rVal = rightAligned[i];
                
                if (lVal === undefined) {
                    combined.push(rVal);
                } else if (rVal === undefined) {
                    combined.push(lVal);
                } else {
                    combined.push((lVal + rVal) / 2);
                }
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
        "bars = " + service.activeBars + "\\n" +
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

    Component.onCompleted: {
        updateProcessState();
    }

    onActiveBarsChanged: {
        if (cavaProcess.running) {
            service.restarting = true;
            cavaProcess.running = false;
        } else if (!service.restarting) {
            updateProcessState();
        }
    }

    onCavaEnabledChanged: {
        if (cavaEnabled) {
            retryTimer.stop();
        } else {
            targetValues = [];
        }
        updateProcessState();
    }

    Timer {
        id: retryTimer
        interval: 5000
        repeat: false
        onTriggered: {
            updateProcessState();
        }
    }

    Process {
        id: cavaProcess
        command: service.cavaCommand
        running: false

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
            if (service.restarting) {
                service.restarting = false;
                updateProcessState();
            } else if (service.cavaEnabled) {
                retryTimer.restart();
            }
        }
    }
}