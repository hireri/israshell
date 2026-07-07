pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property real volume: sink?.audio?.volume ?? 0.0
    readonly property bool muted: sink?.audio?.muted ?? false

    readonly property real sourceVolume: source?.audio?.volume ?? 0.0
    readonly property bool sourceMuted: source?.audio?.muted ?? false

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

    function isDefaultSource(node) {
        return source?.id !== undefined && source?.id === node?.id;
    }

    // People keep joking about setting volume to 5018% so...
    function setVolume(vol) {
        if (sink?.ready && sink?.audio)
            sink.audio.volume = Math.max(0.0, Math.min(1.5, vol));
    }

    function setSourceVolume(vol) {
        if (source?.ready && source?.audio)
            source.audio.volume = Math.max(0.0, Math.min(1.5, vol));
    }

    function toggleMute() {
        if (sink?.ready && sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    function toggleSourceMute() {
        if (source?.ready && source?.audio)
            source.audio.muted = !source.audio.muted;
    }

    function setDefaultSink(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function setDefaultSource(node) {
        Pipewire.preferredDefaultAudioSource = node;
    }

    property real micLevel: 0.0
    property bool micMeterActive: false

    function startMicMeter() {
        if (micMeterActive || !source?.ready)
            return;
        micMeterActive = true;
        _launchMicMeter();
    }

    function stopMicMeter() {
        micMeterActive = false;
        micMeterProcess.running = false;
        micLevel = 0.0;
    }

    function _launchMicMeter() {
        if (!source?.name)
            return;
        const config = "[general]\n" +
            "bars = 1\n" +
            "framerate = 60\n" +
            "autosens = 0\n" +
            "sensitivity = 100\n" +
            "[input]\n" +
            "method = pulse\n" +
            "source = " + source.name + "\n" +
            "[output]\n" +
            "method = raw\n" +
            "channels = mono\n" +
            "raw_target = /dev/stdout\n" +
            "data_format = ascii\n" +
            "ascii_max_range = 100\n" +
            "bar_delimiter = 59\n";
        const b64 = Qt.btoa(config);
        micMeterProcess.command = ["bash", "-c",
            "echo " + b64 + " | base64 -d | cava -p /dev/stdin"];
        micMeterProcess.running = false;
        micMeterProcess.running = true;
    }

    onSourceChanged: {
        if (micMeterActive)
            _launchMicMeter();
    }

    Process {
        id: micMeterProcess

        stdout: SplitParser {
            onRead: line => {
                const raw = line.trim().replace(";", "");
                const n = parseInt(raw, 10);
                if (!isNaN(n))
                    root.micLevel = Math.max(0, Math.min(100, n)) / 100.0;
            }
        }
        stderr: SplitParser {
            onRead: line => console.warn("cava stderr:", line)
        }
        onExited: (code, status) => console.warn("cava process exited:", code, status)
    }

    PwObjectTracker {
        objects: [root.sink, root.source]
    }
}
