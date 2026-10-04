pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.services
import qs.style

Singleton {
    id: root

    property string status: "waiting"
    property string channel: ""
    property string detail: ""
    property var users: []

    readonly property bool wanted: GameOverlayService.isOpen("discordVoice") && (status === "authorize" || GameOverlayService.visible || GameOverlayService.instantHidden || GameOverlayService.widgetState("discordVoice").pinned === true)

    onStatusChanged: {
        if (status === "authorize") {
            GameOverlayService.close();
            notifyProc.running = true;
        }
    }

    Process {
        running: root.wanted
        command: ["python3", Quickshell.shellDir + "/scripts/discord-voice.py"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    const m = JSON.parse(line);
                    root.status = m.status;
                    root.detail = m.detail ?? "";
                    if (m.status === "ok") {
                        root.channel = m.channel ?? "";
                        root.users = m.users;
                    }
                } catch (e) {}
            }
        }
        onRunningChanged: if (!running) {
            root.status = "waiting";
            root.channel = "";
            root.users = [];
        }
    }

    Process {
        id: notifyProc
        command: ["notify-send", "-a", "QuickShell", Localization.t("gameOverlay.discord"), Localization.t("gameOverlay.discord_authorize")]
    }
}
