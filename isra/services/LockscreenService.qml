pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pam
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

    property var _savedWorkspaces: ({})
    property string _savedActiveWindow: "" 
    property string _savedActiveMonitor: ""

    signal unlocked()
    signal lockAnimationStart()
    signal unlockAnimationStart()

    onCurrentTextChanged: showFailure = false
    Component.onCompleted: {
        if (Config.startLocked)
            sessionCheckProcess.running = true
    }

    function lock(): void {
        if (Config.useHyprlock) {
            hyprlockProcess.running = true
            return
        }
        lockAnimating = true
        lockAnimationStart()
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

    function _restoreWorkspaces(): void {
        const saved = root._savedWorkspaces
        root._savedWorkspaces = {}
        let batch = ""
        
        for (const monitorName in saved) {
            const ws = saved[monitorName]
            batch += `hyprctl dispatch 'hl.dsp.focus({monitor="${monitorName}"})'; `
            batch += `hyprctl dispatch 'hl.dsp.focus({workspace=${ws}})'; `
        }
        
        if (root._savedActiveMonitor !== "") {
            batch += `hyprctl dispatch 'hl.dsp.focus({monitor="${root._savedActiveMonitor}"})'; `
        }

        if (root._savedActiveWindow !== "") {
            batch += `hyprctl dispatch focuswindow address:${root._savedActiveWindow}; `
            root._savedActiveWindow = ""
        }
        
        root._savedActiveMonitor = ""

        if (batch.length > 0)
            Quickshell.execDetached(["bash", "-c", batch])
    }

    Timer {
        id: lockVisualDelayTimer
        interval: 200
        onTriggered: root.lockVisualActive = true
    }

    Timer {
        id: lockEngageTimer
        interval: 600
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
    
    Process {
        id: saveWorkspaceProcess
        command: ["sh", "-c", "hyprctl monitors -j && echo '---SPLIT---' && hyprctl activewindow -j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parts = text.split("---SPLIT---")
                    const monitorsText = parts[0].trim()
                    const activeWindowText = parts[1] ? parts[1].trim() : ""

                    if (activeWindowText && activeWindowText !== "Invalid") {
                        try {
                            const win = JSON.parse(activeWindowText)
                            if (win && win.address) {
                                root._savedActiveWindow = win.address
                            }
                        } catch (e) {
                            console.log("Failed to parse active window JSON:", e)
                        }
                    }

                    const monitors = JSON.parse(monitorsText)
                    if (monitors.length === 0) {
                        lockVisualDelayTimer.start()
                        lockEngageTimer.start()
                        return
                    }

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
                        const dummy = 2147483647 - ws
                        batch += `hyprctl dispatch 'hl.dsp.focus({monitor="${mon.name}"})'; `
                        batch += `hyprctl dispatch 'hl.dsp.focus({workspace=${dummy}})'; `
                    }
                    root._savedWorkspaces = saved
                    
                    if (originalFocusedMonitor !== "") {
                        batch += `hyprctl dispatch 'hl.dsp.focus({monitor="${originalFocusedMonitor}"})'; `
                    }

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
    IpcHandler {
        target: "lockscreen"
        function lock(): void {
            root.lock()
        }
    }
    Process {
        id: sessionCheckProcess
        command: [
            "sh",
            "-c",
            `[ ! -f /run/user/$(id -u)/israshell-session ] && echo "fresh"`
        ]
        stdout: SplitParser {
            onRead: data => {
                if (data.trim() === "fresh")
                    root.lock()
            }
        }
        onExited: markerWriteProcess.running = true
    }
    Process {
        id: markerWriteProcess
        command: [
            "sh",
            "-c",
            "touch /run/user/$(id -u)/israshell-session"
        ]
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