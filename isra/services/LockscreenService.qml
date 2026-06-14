pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

Singleton {
    id: root

    property bool locked: false
    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false

    onCurrentTextChanged: showFailure = false

    signal unlocked()

    function lock(): void {
        root.locked = true
    }

    function tryUnlock(): void {
        if (currentText === "") return
        unlockInProgress = true
        pam.start()
    }

    IpcHandler {
        target: "lockscreen"
        function lock(): void { root.lock() }
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