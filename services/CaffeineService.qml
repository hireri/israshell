pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: false

    Timer {
        id: pollTimer
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: pollProc.running = true
    }

    Process {
        id: pollProc
        command: ["pgrep", "-x", "hypridle"]
        onExited: code => {
            root.active = (code !== 0);
        }
    }

    Process {
        id: killProc
        command: ["pkill", "-x", "hypridle"]
        onExited: pollProc.running = true
    }

    Process {
        id: startProc
        command: ["hypridle"]
        onExited: pollProc.running = true
    }

    function toggle() {
        if (root.active) {
            root.active = false;
            startProc.running = true;
        } else {
            root.active = true;
            killProc.running = true;
        }

        pollTimer.restart();
    }
}
