pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.style

Singleton {
    id: root

    property int refCount: 0
    readonly property bool active: refCount > 0

    property real x: 0
    property real y: 0

    property int intervalMs: 33

    function acquire(): void {
        refCount += 1;
    }

    function release(): void {
        refCount = Math.max(0, refCount - 1);
    }

    onActiveChanged: {
        if (active) {
            pollTimer.start();
        } else {
            pollTimer.stop();
            cursorProc.running = false;
        }
    }

    Timer {
        id: pollTimer
        interval: root.intervalMs
        repeat: true
        onTriggered: {
            if (!cursorProc.running)
                cursorProc.running = true;
        }
    }

    Process {
        id: cursorProc
        running: Config.weyes.enabled
        command: ["hyprctl", "cursorpos", "-j"]
        stdout: StdioCollector {
            id: collector
            onStreamFinished: {
                try {
                    const data = JSON.parse(collector.text);
                    if (typeof data.x === "number" && typeof data.y === "number") {
                        root.x = data.x;
                        root.y = data.y;
                    }
                } catch (e) { }
            }
        }
    }
}
