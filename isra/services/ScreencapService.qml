pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool isRecording: false
    property bool isRecognizing: false
    property string recordingTime: "00:00"
    property double startTime: 0

    function refresh() {
        if (!recordingCheckProc.running)
            recordingCheckProc.running = true;
        if (!songrecCheckProc.running)
            songrecCheckProc.running = true;
    }

    Process {
        id: recordingCheckProc
        command: ["sh", "-c", "test -f /tmp/screenrec-region.pid"]
        running: false
        onExited: exitCode => {
            var currentlyRunning = (exitCode === 0);

            if (currentlyRunning && !root.isRecording) {
                root.isRecording = true;
                root.startTime = Date.now();
            } else if (!currentlyRunning && root.isRecording) {
                root.isRecording = false;
                root.recordingTime = "00:00";
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
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Timer {
        id: displayTimer
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            if (!root.isRecording)
                return;

            var diff = Math.floor((Date.now() - root.startTime) / 1000);
            var hrs = Math.floor(diff / 3600);
            var mins = Math.floor((diff % 3600) / 60);
            var secs = diff % 60;

            root.recordingTime = hrs > 0 ? `${String(hrs).padStart(2, "0")}:${String(mins).padStart(2, "0")}:${String(secs).padStart(2, "0")}` : `${String(mins).padStart(2, "0")}:${String(secs).padStart(2, "0")}`;
        }
    }
}
