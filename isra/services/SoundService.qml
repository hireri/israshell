pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.style

Singleton {
    id: root
    readonly property string _sep: "/usr/share/sounds/"
    property var availableThemes: ["freedesktop"]

    function play(file, bypassDnd = false) {
        if (!Config.sounds.enabled)
            return;
        if (!bypassDnd && (NotificationService.dnd || (Config.sounds.muteDuringMedia && MediaPlayerState.isPlaying)))
            return;

        const themeDir = root._sep + Config.sounds.theme;
        const script = `for base in "${themeDir}" "${root._sep}freedesktop"; do
  for sub in "" action/ alert/ notification/; do
    p="$base/stereo/\${sub}${file}.oga"
    [ -f "$p" ] && exec pw-play --volume ${Config.sounds.volume} "$p"
  done
done`;
        Quickshell.execDetached(["bash", "-c", script]);
    }

    property real _lastNotificationSoundTime: 0
    readonly property int _notificationDebounceMs: 500

    function notification(critical = false) {
        if (!Config.sounds.notifications)
            return;
        const now = Date.now();
        if (now - root._lastNotificationSoundTime < root._notificationDebounceMs)
            return;
        root._lastNotificationSoundTime = now;
        play("message-new-instant", critical);
    }
    function volumeChange() { if (Config.sounds.volumeChange) play("audio-volume-change"); }
    function screenshot() { if (Config.sounds.screenshot) play("screen-capture"); }
    function unlock() { if (Config.sounds.lockUnlock) play("complete"); }
    function unlockFail() { if (Config.sounds.lockUnlock) play("dialog-error"); }
    function startup() { if (Config.sounds.startup) play("service-login"); }

    Process {
        id: themeScanProc
        command: ["bash", "-c", `for d in ${root._sep}*/ ~/.local/share/sounds/*/; do [ -f "$d/index.theme" ] && basename "$d"; done`]
        stdout: StdioCollector {
            onStreamFinished: {
                const names = text.trim().split("\n").filter(n => n.length > 0);
                if (names.length > 0 && !names.includes("freedesktop"))
                    names.push("freedesktop");
                root.availableThemes = names.length > 0 ? names : ["freedesktop"];
            }
        }
    }

    Component.onCompleted: themeScanProc.running = true
}
