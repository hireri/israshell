pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.style

Singleton {
    id: root

    property real rxBytesPerSec: 0
    property real txBytesPerSec: 0

    property var _lastRx: 0
    property var _lastTx: 0
    property bool _haveLast: false

    readonly property bool active: Config.quicksettings.icons.includes("traffic")
    onActiveChanged: root._haveLast = false

    Timer {
        interval: 1000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: pollProc.running = true
    }

    Process {
        id: pollProc
        command: ["sh", "-c", "for i in /sys/class/net/*/; do n=$(basename \"$i\"); [ \"$n\" = lo ] && continue; echo \"$(cat \"$i/statistics/rx_bytes\" 2>/dev/null) $(cat \"$i/statistics/tx_bytes\" 2>/dev/null)\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                let rx = 0, tx = 0;
                for (const line of text.trim().split("\n")) {
                    const parts = line.trim().split(/\s+/);
                    if (parts.length !== 2)
                        continue;
                    rx += parseInt(parts[0]) || 0;
                    tx += parseInt(parts[1]) || 0;
                }
                if (root._haveLast) {
                    root.rxBytesPerSec = Math.max(0, rx - root._lastRx);
                    root.txBytesPerSec = Math.max(0, tx - root._lastTx);
                }
                root._lastRx = rx;
                root._lastTx = tx;
                root._haveLast = true;
            }
        }
    }
}
