pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.style

Singleton {
    id: root

    property bool isRecording: false
    property bool isRecognizing: false
    property string recordingTime: "00:00"
    property double startTime: 0
    property var recordRegion: null
    property bool recordingGif: false
    property bool converting: false
    property int convertProgress: -1
    property int recordPills: 0

    Component.onCompleted: refresh()

    function toolEnabled(name) {
        if (name === "colorpicker" && CompositorService.backendName !== "hyprland")
            return false;
        return !Config.screencap.blacklist.includes(name);
    }

    function refresh() {
        if (!recordingCheckProc.running)
            recordingCheckProc.running = true;
        if (!songrecCheckProc.running)
            songrecCheckProc.running = true;
    }

    function toggleRecognitionOptimistic() {
        root.isRecognizing = !root.isRecognizing;
        confirmTimer.restart();
    }

    function markRecordingStoppedOptimistic() {
        root.converting = root.recordingGif;
        root.convertProgress = -1;
        root.isRecording = false;
        root.recordingTime = "00:00";
        root.recordRegion = null;
        root.recordingGif = false;
        confirmTimer.restart();
    }

    function stopRecording(): void {
        Quickshell.execDetached(["sh", "-c", "qs -c isra ipc call screenshot stopRecord"]);
    }

    function _setRegion(text) {
        const m = /^(-?\d+),(-?\d+) (\d+)x(\d+)/.exec(text.trim());
        const r = m ? { x: +m[1], y: +m[2], w: +m[3], h: +m[4] } : null;
        const c = root.recordRegion;
        const same = r === null ? (c === null) : (c !== null && c.x === r.x && c.y === r.y && c.w === r.w && c.h === r.h);
        if (!same)
            root.recordRegion = r;
    }

    Process {
        id: recordingCheckProc
        command: ["sh", "-c", "cat /tmp/screenrec-region.geometry 2>/dev/null; echo; cat /tmp/screenrec-region.format 2>/dev/null; for f in /tmp/screenrec-convert.*; do [ -f \"$f\" ] || continue; if kill -0 \"${f##*.}\" 2>/dev/null; then echo \"conv:$(cat \"$f\")\"; else rm -f \"$f\"; fi; done; test -f /tmp/screenrec-region.pid"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root._setRegion(text);
                root.recordingGif = /^gif$/m.test(text);
                const conv = text.match(/^conv:\d*$/gm);
                const pct = conv ? conv[conv.length - 1].slice(5) : "";
                root.converting = conv !== null || (root.converting && confirmTimer.running);
                root.convertProgress = pct !== "" ? +pct : -1;
            }
        }
        onExited: exitCode => {
            var currentlyRunning = (exitCode === 0);

            if (currentlyRunning && !root.isRecording) {
                root.isRecording = true;
                root.startTime = Date.now();
            } else if (!currentlyRunning && root.isRecording) {
                root.isRecording = false;
                root.recordingTime = "00:00";
                root.recordingGif = false;
            }
        }
    }

    Process {
        id: songrecCheckProc
        command: ["sh", "-c", "test -f /tmp/songrec_script.pid && kill -0 $(cat /tmp/songrec_script.pid) 2>/dev/null"]
        running: false
        onExited: exitCode => {
            var currentlyRunning = (exitCode === 0);
            if (currentlyRunning !== root.isRecognizing) {
                root.isRecognizing = currentlyRunning;
            }
        }
    }

    Timer {
        id: pollTimer
        interval: root.converting ? 500 : 1000
        running: root.isRecording || root.isRecognizing || root.converting
        repeat: true
        onTriggered: root.refresh()
    }

    Timer {
        id: confirmTimer
        interval: 1500
        onTriggered: root.refresh()
    }

    Timer {
        id: displayTimer
        interval: 100
        running: root.isRecording
        repeat: true
        onTriggered: {
            var diff = Math.floor((Date.now() - root.startTime) / 1000);
            var hrs = Math.floor(diff / 3600);
            var mins = Math.floor((diff % 3600) / 60);
            var secs = diff % 60;

            root.recordingTime = hrs > 0 ? `${String(hrs).padStart(2, "0")}:${String(mins).padStart(2, "0")}:${String(secs).padStart(2, "0")}` : `${String(mins).padStart(2, "0")}:${String(secs).padStart(2, "0")}`;
        }
    }
}
