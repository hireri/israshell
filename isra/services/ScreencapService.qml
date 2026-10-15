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
        root.isRecording = false;
        root.recordingTime = "00:00";
        root.recordRegion = null;
        root.recordingGif = false;
        confirmTimer.restart();
    }

    function stopRecording(): void {
        Quickshell.execDetached(["sh", "-c", "qs -c isra ipc call screenshot record"]);
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
        command: ["sh", "-c", "test -f /tmp/screenrec-region.pid || exit 1; cat /tmp/screenrec-region.geometry 2>/dev/null; echo; cat /tmp/screenrec-region.format 2>/dev/null; exit 0"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root._setRegion(text);
                root.recordingGif = /^gif$/m.test(text);
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
        interval: 1000
        running: root.isRecording || root.isRecognizing
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
