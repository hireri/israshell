pragma Singleton
import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Io
import qs.services
import qs.style

Singleton {
    id: root
    readonly property string _sysDir: "/usr/share/sounds/"
    readonly property string _userDir: "$HOME/.local/share/sounds/"
    property var availableThemes: ["freedesktop"]

    MediaDevices {
        id: mediaDevices
    }

    MediaPlayer {
        id: player
        audioOutput: AudioOutput {
            device: mediaDevices.defaultAudioOutput
            volume: Config.sounds.volume
        }
    }

    Process {
        id: resolveProc
        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim();
                if (path.length === 0)
                    return;
                player.stop();
                player.source = "file://" + path;
                player.play();
            }
        }
    }

    function play(file, bypassDnd = false) {
        if (!Config.sounds.enabled)
            return;
        if (BedtimeService.active && (Config.bedtime.muteSounds ?? false))
            return;
        if (!bypassDnd && (NotificationService.dnd || (Config.sounds.muteDuringMedia && MediaPlayerState.isPlaying)))
            return;

        const theme = Config.sounds.theme;
        const bases = [root._userDir + theme, root._sysDir + theme, root._userDir + "freedesktop", root._sysDir + "freedesktop"];
        const script = `for base in ${bases.map(b => `"${b}"`).join(" ")}; do
  for sub in "" action/ alert/ notification/; do
    for ext in oga ogg wav; do
      p="$base/stereo/\${sub}${file}.$ext"
      [ -f "$p" ] && { echo -n "$p"; exit 0; }
    done
  done
done`;
        resolveProc.running = false;
        resolveProc.command = ["bash", "-c", script];
        resolveProc.running = true;
    }

    function rescanThemes() { themeScanProc.running = true; }

    property string _ttsPath: ""
    property string _ttsFallbackText: ""
    property string _ttsFallbackLang: ""

    function speak(text, lang = "en") {
        if (!text)
            return;
        root._ttsFallbackText = text;
        root._ttsFallbackLang = lang;
        root._ttsPath = "/tmp/qs-tts-" + Date.now() + "-" + Math.floor(Math.random() * 1e6) + ".mp3";
        ttsGenProc.command = ["gtts-cli", text, "-l", lang, "-o", root._ttsPath];
        ttsGenProc.running = true;
    }

    function _ttsFallback() {
        espeakProc.command = ["espeak-ng", "-v", root._ttsFallbackLang, "--", root._ttsFallbackText];
        espeakProc.running = true;
    }

    MediaPlayer {
        id: ttsPlayer
        audioOutput: AudioOutput {
            device: mediaDevices.defaultAudioOutput
        }
        onMediaStatusChanged: {
            if (mediaStatus !== MediaPlayer.EndOfMedia && mediaStatus !== MediaPlayer.InvalidMedia)
                return;
            if (mediaStatus === MediaPlayer.InvalidMedia)
                root._ttsFallback();
            if (root._ttsPath) {
                ttsCleanupProc.command = ["rm", "-f", root._ttsPath];
                ttsCleanupProc.running = true;
                root._ttsPath = "";
            }
        }
    }

    Process {
        id: ttsGenProc
        onExited: code => {
            if (code === 0) {
                ttsPlayer.source = "file://" + root._ttsPath;
                ttsPlayer.play();
            } else {
                root._ttsFallback();
            }
        }
    }

    Process { id: espeakProc }
    Process { id: ttsCleanupProc }

    property real _lastNotificationSoundTime: 0
    readonly property int _notificationDebounceMs: 500

    function notification(critical = false) {
        if (!Config.sounds.notifications)
            return;
        const now = Date.now();
        if (now - root._lastNotificationSoundTime < root._notificationDebounceMs)
            return;
        root._lastNotificationSoundTime = now;
        play(critical ? "dialog-warning" : "message-new-instant", critical);
    }
    function volumeChange() { if (Config.sounds.volumeChange) play("audio-volume-change"); }
    function screenshot() { if (Config.sounds.screenshot) play("screen-capture"); }
    function unlock() { if (Config.sounds.unlock) play("complete"); }
    function unlockFail() { if (Config.sounds.unlock) play("dialog-error"); }
    function startup() { if (Config.sounds.startup) play("service-login"); }
    function lock() { if (Config.sounds.lock) play("service-logout"); }
    function chargerPlug(plugged) { if (Config.sounds.chargerPlug) play(plugged ? "power-plug" : "power-unplug"); }
    function lowBattery() { if (Config.sounds.batteryLow) play("battery-caution", true); }
    function localSendDone() { if (Config.sounds.localsend) play("complete"); }
    function localSendError() { if (Config.sounds.localsend) play("dialog-error"); }
    function localSendIncoming() { if (Config.sounds.localsend) play("message"); }
    function bluetoothConnect(connected) { if (Config.sounds.bluetooth) play(connected ? "device-added" : "device-removed"); }

    Process {
        id: themeScanProc
        command: ["bash", "-c", `for d in ${root._sysDir}*/ ${root._userDir}*/; do [ -f "$d/index.theme" ] && basename "$d"; done`]
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
