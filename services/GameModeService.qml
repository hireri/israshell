pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: false

    Process {
        id: checkProc
        running: true
        command: ["bash", "-c", "[ -f /tmp/hypr_gamemode_state ] && echo 1 || echo 0"]
        stdout: StdioCollector {
            onStreamFinished: root.active = text.trim() === "1"
        }
    }

    Process {
        id: toggleProc
        onExited: {
            checkProc.running = false;
            checkProc.running = true;
        }
    }

    function toggle() {
        toggleProc.command = ["bash", Quickshell.env("HOME") + "/.config/quickshell/scripts/gamemode.sh"];
        toggleProc.running = false;
        toggleProc.running = true;
    }

    function refresh() {
        checkProc.running = false;
        checkProc.running = true;
    }
}
