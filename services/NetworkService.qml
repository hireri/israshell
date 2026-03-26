pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool wifiEnabled: false

    Process {
        id: initProc
        command: ["nmcli", "radio", "wifi"]
        running: true
        stdout: SplitParser {
            onRead: data => root.wifiEnabled = data.trim() === "enabled"
        }
    }

    Process {
        id: monitorProc
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                if (data.includes("wifi") || data.includes("wireless"))
                    pollProc.running = true;
            }
        }
    }

    Process {
        id: pollProc
        command: ["nmcli", "radio", "wifi"]
        stdout: SplitParser {
            onRead: data => root.wifiEnabled = data.trim() === "enabled"
        }
    }

    Process {
        id: enableProc
        command: ["nmcli", "radio", "wifi", "on"]
        onExited: pollProc.running = true
    }

    Process {
        id: disableProc
        command: ["nmcli", "radio", "wifi", "off"]
        onExited: pollProc.running = true
    }

    function toggle() {
        if (root.wifiEnabled)
            disableProc.running = true;
        else
            enableProc.running = true;
    }
}
