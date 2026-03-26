pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0.0
    readonly property bool muted: sink?.audio?.muted ?? false

    PwObjectTracker {
        objects: [root.sink]
    }

    function setVolume(vol: real) {
        if (sink?.ready && sink?.audio)
            sink.audio.volume = Math.max(0.0, Math.min(1.5, vol));
    }

    function toggleMute() {
        if (sink?.ready && sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }
}
