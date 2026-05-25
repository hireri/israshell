pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property var profiles: ["balanced", "power-saver", "performance"]
    property int profileIndex: 1
    readonly property string activeProfile: profiles[profileIndex]

    Process {
        id: getProc
        running: true
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = text.trim()
                const i = root.profiles.indexOf(v)
                if (i >= 0) root.profileIndex = i
            }
        }
    }

    Process {
        id: setProc
        onExited: {
            getProc.running = false
            getProc.running = true
        }
    }

    function cycle(direction) {
        const n = profiles.length
        profileIndex = (profileIndex + direction + n) % n
        setProc.command = ["powerprofilesctl", "set", profiles[profileIndex]]
        setProc.running = false
        setProc.running = true
    }

    function refresh() {
        getProc.running = false
        getProc.running = true
    }
}