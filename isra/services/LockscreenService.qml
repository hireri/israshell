pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import qs.services
import qs.style

Singleton {
    id: root
    property bool locked: false
    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false
    property bool lockAnimating: false
    property bool unlockAnimating: false
    property bool lockVisualActive: false
    property bool _isFirstLock: false

    property var _savedWorkspaces: ({})
    property string _savedActiveWindow: ""
    property string _savedActiveMonitor: ""

    signal unlocked()
    signal unlockAnimationStart()

    onCurrentTextChanged: showFailure = false
    Component.onCompleted: {
        if (Config.startLocked)
            sessionCheckProcess.running = true
    }

    function lock(isFresh = false): void {
        if (root.locked || root.lockAnimating) return
        root._isFirstLock = isFresh;

        if (Config.useHyprlock) {
            hyprlockProcess.running = true
            return
        }

        if (!isFresh) {
            lockAnimating = true
        }
        saveWorkspaceProcess.running = true
    }

    function tryUnlock(): void {
        if (Config.useHyprlock)
            return
        if (currentText === "")
            return
        unlockInProgress = true
        pam.start()
    }

    function _doUnlock(): void {
        unlockInProgress = false
        locked = false
        lockVisualActive = false
        unlockAnimating = true
        unlockAnimationStart()
        _restoreWorkspaces()
        unlockAnimationTimer.start()
        unlocked()
    }

    function _doRestoreDispatch(saved, activeMonitor, activeWindow): void {
        CompositorService.restoreLayout(saved, activeMonitor, activeWindow)
        Quickshell.execDetached(["bash", "-c", "rm -f /run/user/$(id -u)/israshell/workspaces"])
    }

    function _restoreWorkspaces(): void {
        const saved = root._savedWorkspaces
        const activeMonitor = root._savedActiveMonitor
        const activeWindow = root._savedActiveWindow
        root._savedWorkspaces = {}
        root._savedActiveMonitor = ""
        root._savedActiveWindow = ""

        if (Object.keys(saved).length > 0) {
            _doRestoreDispatch(saved, activeMonitor, activeWindow)
        } else {
            restoreFromDiskProcess.running = true
        }
    }

    Timer {
        id: lockVisualDelayTimer
        interval: 50
        onTriggered: root.lockVisualActive = true
    }

    Timer {
        id: lockEngageTimer
        interval: 450
        onTriggered: {
            root.lockAnimating = false
            root.locked = true
        }
    }

    Timer {
        id: unlockAnimationTimer
        interval: 500
        onTriggered: root.unlockAnimating = false
    }

    readonly property int _dummyWorkspaceBase: 2147483647

    function _parseSaveOutput(text) {
        const parts = text.split("---SPLIT---")
        const monitorsText = parts[0].trim()
        const activeWindowText = parts[1] ? parts[1].trim() : ""

        let activeWindowAddr = ""
        if (activeWindowText && activeWindowText !== "Invalid") {
            try {
                const win = JSON.parse(activeWindowText)
                if (win && win.address)
                    activeWindowAddr = win.address
            } catch (e) {
                console.log("Failed to parse active window JSON:", e)
            }
        }

        return { monitors: JSON.parse(monitorsText), activeWindowAddr: activeWindowAddr }
    }

    function _buildLockBatch(monitors): string {
        let originalFocusedMonitor = ""
        for (const mon of monitors) {
            if (mon.focused === true) {
                originalFocusedMonitor = mon.name
                root._savedActiveMonitor = mon.name
                break
            }
        }

        const saved = {}
        let batch = ""
        for (const mon of monitors) {
            if (mon.activeWorkspace === undefined || mon.activeWorkspace.id === undefined)
                continue
            const ws = mon.activeWorkspace.id
            saved[mon.name] = ws

            if (!root._isFirstLock) {
                const dummy = root._dummyWorkspaceBase - ws;
                batch += `hyprctl dispatch 'hl.dsp.focus({monitor="${mon.name}"})'; `
                batch += `hyprctl dispatch 'hl.dsp.focus({workspace=${dummy}})'; `
            } else {
                batch += `hyprctl dispatch 'hl.dsp.focus({monitor="${mon.name}"})'; `
            }
        }
        root._savedWorkspaces = saved

        const saveData = JSON.stringify({
            workspaces: saved,
            activeMonitor: root._savedActiveMonitor,
            activeWindow: root._savedActiveWindow
        })
        batch += `mkdir -p /run/user/$(id -u)/israshell && echo '${saveData}' > /run/user/$(id -u)/israshell/workspaces; `

        if (originalFocusedMonitor !== "") {
            batch += `hyprctl dispatch 'hl.dsp.focus({monitor="${originalFocusedMonitor}"})'; `
        }

        return batch
    }

    Process {
        id: saveWorkspaceProcess
        command: ["sh", "-c", "hyprctl monitors -j && echo '---SPLIT---' && hyprctl activewindow -j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = root._parseSaveOutput(text)
                    if (parsed.activeWindowAddr)
                        root._savedActiveWindow = parsed.activeWindowAddr

                    if (parsed.monitors.length === 0) {
                        lockVisualDelayTimer.start()
                        lockEngageTimer.start()
                        return
                    }

                    const batch = root._buildLockBatch(parsed.monitors)
                    if (batch.length > 0)
                        Quickshell.execDetached(["bash", "-c", batch])
                    lockVisualDelayTimer.start()
                    lockEngageTimer.start()
                } catch (e) {
                    console.log("Failed to parse monitors:", e)
                    lockVisualDelayTimer.start()
                    lockEngageTimer.start()
                }
            }
        }
    }

    Process {
        id: restoreFromDiskProcess
        command: ["sh", "-c", "cat /run/user/$(id -u)/israshell/workspaces 2>/dev/null || echo ''"]
        stdout: StdioCollector {
            onStreamFinished: {
                const content = text.trim()
                if (!content) {
                    console.log("No workspace save file found, cannot restore")
                    return
                }
                try {
                    const data = JSON.parse(content)
                    root._doRestoreDispatch(
                        data.workspaces || {},
                        data.activeMonitor || "",
                        data.activeWindow || ""
                    )
                } catch (e) {
                    console.log("Failed to parse workspace save file:", e)
                }
            }
        }
    }

    IpcHandler {
        target: "lockscreen"
        function lock(): void {
            root.lock()
        }
    }

    Process {
        id: sessionCheckProcess
        command: ["sh", "-c", `[ ! -f /run/user/$(id -u)/israshell/session ] && echo "fresh"`]
        stdout: SplitParser {
            onRead: data => {
                if (data.trim() === "fresh")
                    root.lock(true)
            }
        }
        onExited: markerWriteProcess.running = true
    }

    Process {
        id: markerWriteProcess
        command: ["sh", "-c", "mkdir -p /run/user/$(id -u)/israshell && touch /run/user/$(id -u)/israshell/session"]
    }

    Process {
        id: hyprlockProcess
        command: ["hyprlock"]
        onRunningChanged: {
            if (!running) {
                root.locked = false
                root.unlocked()
            }
        }
    }

    PamContext {
        id: pam
        configDirectory: Quickshell.shellDir + "/pam"
        config: "password.conf"
        onPamMessage: {
            if (responseRequired)
                respond(root.currentText)
        }
        onCompleted: result => {
            if (result === PamResult.Success) {
                root._doUnlock()
            } else {
                root.currentText = ""
                root.showFailure = true
                root.unlockInProgress = false
            }
        }
    }
}
