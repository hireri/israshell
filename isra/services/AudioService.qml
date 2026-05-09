pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property real volume: sink?.audio?.volume ?? 0.0
    readonly property bool muted: sink?.audio?.muted ?? false

    readonly property var nodes: Pipewire.nodes.values

    function deviceName(node) {
        return node.nickname || node.description || node.name || "Unknown";
    }

    function appNodeDisplayName(node) {
        return node.properties["application.process.binary"] || node.properties["application.name"] || node.description || node.name || "Unknown";
    }

    function streamIconName(node) {
        const explicit = node.properties["application.icon-name"] ?? "";
        if (explicit.length > 0)
            return explicit;
        const binary = node.properties["application.process.binary"] ?? "";
        return binary.toLowerCase();
    }

    function isDefaultSink(node) {
        return sink?.id !== undefined && sink?.id === node?.id;
    }

    function setVolume(vol) {
        if (sink?.ready && sink?.audio)
            sink.audio.volume = Math.max(0.0, Math.min(1.5, vol));
    }

    function toggleMute() {
        if (sink?.ready && sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    function setDefaultSink(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }

    PwObjectTracker {
        objects: [root.sink, root.source]
    }
}
