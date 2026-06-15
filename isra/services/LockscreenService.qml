pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

import qs.style

Singleton {
    id: root

    property bool locked: false
    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false

    onCurrentTextChanged: showFailure = false

    signal unlocked()

    readonly property string _sessionMarker: `/run/user/${Qt.application.arguments[0]}/israshell-session`

    Component.onCompleted: {
        if (Config.startLocked) {
            sessionCheckProcess.running = true
        }
    }

    function lock(): void {
        if (Config.useHyprlock) {
            hyprlockProcess.running = true
        } else {
            root.locked = true
        }
    }

    function tryUnlock(): void {
        if (Config.useHyprlock) return
        if (currentText === "") return
        unlockInProgress = true
        pam.start()
    }

    IpcHandler {
        target: "lockscreen"
        function lock(): void { root.lock() }
    }

    Process {
        id: sessionCheckProcess
        command: ["sh", "-c", `[ ! -f /run/user/$(id -u)/israshell-session ] && echo "fresh"`]
        running: false
        onExited: (code, status) => {
            markerWriteProcess.running = true
        }
        stdout: SplitParser {
            onRead: data => {
                if (data.trim() === "fresh") {
                    root.lock()
                }
            }
        }
    }

    Process {
        id: markerWriteProcess
        command: ["sh", "-c", "touch /run/user/$(id -u)/israshell-session"]
        running: false
    }

    Process {
        id: hyprlockProcess
        command: ["hyprlock"]
        running: false
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
            if (this.responseRequired)
                this.respond(root.currentText)
        }
        onCompleted: result => {
            if (result === PamResult.Success) {
                root.locked = false
                root.unlocked()
            } else {
                root.currentText = ""
                root.showFailure = true
            }
            root.unlockInProgress = false
        }
    }
}