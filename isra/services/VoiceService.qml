pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.style

Singleton {
    id: root

    property string phase: "idle"
    property string message: ""
    property string elapsed: "0:00"
    property bool capture: false
    signal dictated(string text)

    readonly property var cfg: Config.voice
    readonly property bool busy: phase === "recording" || phase === "transcribing"

    readonly property string scriptPath: Quickshell.shellDir + "/scripts/voice-transcribe.py"

    readonly property string dataDir: Quickshell.env("HOME") + "/.local/share/israshell/voice"
    readonly property string modelsDir: dataDir + "/models"
    readonly property var models: [
        { id: "tiny", name: "Tiny", file: "ggml-tiny-q5_1.bin", params: "39M", size: "32 MB" },
        { id: "base", name: "Base", file: "ggml-base-q5_1.bin", params: "74M", size: "60 MB" },
        { id: "small", name: "Small", file: "ggml-small-q5_1.bin", params: "244M", size: "190 MB" },
        { id: "medium", name: "Medium", file: "ggml-medium-q5_0.bin", params: "769M", size: "539 MB" },
        { id: "turbo", name: "Large v3 turbo", file: "ggml-large-v3-turbo-q5_0.bin", params: "809M", size: "574 MB" }
    ]
    readonly property string serverBin: cfg.serverPath ? _expand(cfg.serverPath) : dataDir + "/bin/whisper-server"
    readonly property string modelFile: cfg.modelPath ? _expand(cfg.modelPath) : modelsDir + "/" + (models.find(m => m.id === cfg.model)?.file ?? "")

    property bool hasWtype: true
    readonly property string output: hasWtype ? cfg.output : "copy"
    property bool serverFound: false
    property bool modelFound: false
    readonly property bool ready: serverFound && modelFound

    readonly property string whisperTag: "b5454"
    readonly property string llamaTag: "b11588"
    readonly property string engineTag: whisperTag + "+" + llamaTag
    property string engineVersion: ""
    property var downloaded: []
    property string installStep: ""
    property real installProgress: 0
    property string installError: ""
    property string downloading: ""
    property real downloadProgress: 0

    onServerBinChanged: refresh()
    onModelFileChanged: refresh()
    readonly property var serverCommand: [serverBin, "-m", modelFile, "--host", "127.0.0.1", "--port", String(cfg.port), "-t", "4", "-l", cfg.language].concat(cfg.gpu ? [] : ["--no-gpu"])
    onServerCommandChanged: {
        if (serverOurs && !busy)
            serverProc.running = false;
    }
    Component.onCompleted: refresh()

    function _percent(data) {
        const m = /([\d.]+)%/.exec(data);
        const p = m ? parseFloat(m[1]) : -1;
        return p >= 0 && p < 100 ? p / 100 : -1;
    }

    function refresh() {
        scanProc.running = false;
        scanProc.running = true;
    }

    function installEngine() {
        if (installProc.running)
            return;
        root.installError = "";
        root.installProgress = 0;
        root.installStep = "download";
        installProc.running = true;
    }

    function downloadModel(id) {
        const m = models.find(m => m.id === id);
        if (!m || dlProc.running)
            return;
        root.downloading = id;
        root.downloadProgress = 0;
        dlProc.target = modelsDir + "/" + m.file;
        dlProc.command = ["curl", "-fL", "--progress-bar", "-C", "-", "--create-dirs", "-o", dlProc.target + ".part", "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/" + m.file];
        dlProc.running = true;
    }

    function cancelDownload() {
        dlProc.running = false;
    }

    function deleteModel(id) {
        const m = models.find(m => m.id === id);
        if (!m || fsProc.running)
            return;
        fsProc.command = ["rm", "-f", modelsDir + "/" + m.file];
        fsProc.running = true;
    }

    function selectModel(id) {
        Config.update({
            voice: Object.assign({}, Config.voice, {
                model: id,
                modelPath: ""
            })
        });
    }

    property bool serverReady: false
    property bool serverOurs: false
    property bool _cancelled: false
    property double _startTime: 0
    property int _healthTries: 0
    property bool _gotText: false
    property bool _failed: false
    property bool _noWtype: false
    property bool _held: false
    property string _acc: ""
    property var _typeQueue: []

    function _expand(p) {
        return String(p).replace(/^~(?=\/|$)/, Quickshell.env("HOME"));
    }

    function press() {
        root.capture = false;
        root._held = true;
        start();
    }

    function release() {
        stop();
    }

    function toggle() {
        if (phase === "recording") {
            stop();
        } else {
            root.capture = false;
            root._held = false;
            start();
        }
    }

    function toggleCapture() {
        if (phase === "recording") {
            stop();
        } else if (!busy) {
            root.capture = true;
            root._held = false;
            start();
        }
    }

    function start() {
        if (busy)
            return;
        flashTimer.stop();
        if (!root.ready) {
            root._finish("error", Localization.t("voice.not_set_up"));
            return;
        }
        root._cancelled = false;
        root._gotText = false;
        root._failed = false;
        root._noWtype = false;
        root._acc = "";
        root._typeQueue = [];
        root.phase = "recording";
        root._startTime = Date.now();
        root.elapsed = "0:00";
        streamProc.running = true;
        root._ensureServer();
    }

    function stop() {
        if (phase === "recording") {
            root.phase = "transcribing";
            streamProc.running = false;
        }
    }

    function cancel() {
        if (!busy)
            return;
        root._cancelled = true;
        root._typeQueue = [];
        streamProc.running = false;
        root._finish("idle", "");
    }

    function _finish(phase, message) {
        root.phase = phase;
        root.message = message;
        unloadTimer.restart();
        if (phase === "done" || phase === "error")
            flashTimer.interval = phase === "error" ? 3000 : 1400;
        if (phase === "done" || phase === "error")
            flashTimer.restart();
    }

    function _ensureServer() {
        unloadTimer.stop();
        if (root.serverReady || healthProc.running || serverStartTimer.running)
            return;
        healthProc.running = true;
    }

    function _onLine(line) {
        let r = {};
        try {
            r = JSON.parse(line);
        } catch (e) {
            return;
        }
        if (root._cancelled)
            return;
        if (r.silence) {
            if (!root._held)
                root.stop();
        } else if (r.error) {
            root._failed = true;
            root.serverReady = false;
        } else if (r.text) {
            const chunk = (root._gotText ? " " : "") + r.text;
            root._gotText = true;
            if (root.output === "copy" || root._noWtype || root.capture) {
                root._acc += chunk;
            } else {
                root._typeQueue.push(chunk);
                root._pump();
            }
        }
    }

    function _pump() {
        if (typeProc.running)
            return;
        if (root._typeQueue.length > 0) {
            const chunk = root._typeQueue.shift();
            typeProc.chunk = chunk;
            typeProc.command = ["sh", "-c", 'command -v wtype >/dev/null || exit 127; exec wtype -- "$1"', "sh", chunk];
            typeProc.running = true;
        } else {
            root._maybeFinish();
        }
    }

    function _maybeFinish() {
        if (root.phase !== "transcribing" || streamProc.running || typeProc.running || root._typeQueue.length > 0)
            return;
        if (root._acc !== "" && root.capture) {
            root.dictated(root._acc);
            root._finish("idle", "");
        } else if (root._acc !== "") {
            copyProc.fellBack = root._noWtype;
            copyProc.command = ["wl-copy", "--", root._acc];
            copyProc.running = true;
        } else if (root._gotText) {
            root._finish("done", Localization.t("voice.typed"));
        } else {
            root._finish(root._failed ? "error" : "done", Localization.t(root._failed ? "voice.failed" : "voice.nothing_heard"));
        }
    }

    Timer {
        interval: 250
        running: root.phase === "recording"
        repeat: true
        onTriggered: {
            const s = Math.floor((Date.now() - root._startTime) / 1000);
            root.elapsed = Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
        }
    }

    Process {
        id: streamProc
        command: ["python3", "-I", root.scriptPath, String(root.cfg.port), root.cfg.language]
        stdout: SplitParser {
            onRead: line => root._onLine(line)
        }
        onExited: {
            if (root._cancelled)
                return;
            root.phase = "transcribing";
            root._pump();
        }
    }

    Process {
        id: healthProc
        command: ["curl", "-sf", "-m", "1", "http://127.0.0.1:" + root.cfg.port + "/health"]
        onExited: code => {
            if (code === 0) {
                root.serverReady = true;
                serverStartTimer.stop();
            } else if (!serverProc.running) {
                root._healthTries = 0;
                root.serverOurs = true;
                serverProc.running = true;
                serverStartTimer.restart();
            }
        }
    }

    Process {
        id: serverProc
        command: root.serverCommand
        onExited: {
            root.serverReady = false;
            root.serverOurs = false;
            serverStartTimer.stop();
            if (root.busy) {
                root._cancelled = true;
                streamProc.running = false;
                root._finish("error", Localization.t("voice.server_failed"));
            }
        }
    }

    Timer {
        id: serverStartTimer
        interval: 400
        repeat: true
        onTriggered: {
            if (++root._healthTries > 150) {
                stop();
                serverProc.running = false;
                return;
            }
            if (!healthProc.running)
                healthProc.running = true;
        }
    }

    Timer {
        id: unloadTimer
        interval: Math.max(1, root.cfg.unloadSeconds) * 1000
        onTriggered: {
            if (root.serverOurs && !root.busy && root.cfg.unloadSeconds > 0)
                serverProc.running = false;
        }
    }

    Process {
        id: typeProc
        property string chunk: ""
        onExited: code => {
            if (root._cancelled)
                return;
            if (code === 127) {
                root._noWtype = true;
                root._acc = [chunk].concat(root._typeQueue).join("");
                root._typeQueue = [];
            } else if (code !== 0) {
                root._failed = true;
            }
            root._pump();
        }
    }

    Process {
        id: copyProc
        property bool fellBack: false
        onExited: code => {
            root._finish(code === 0 ? "done" : "error", code !== 0 ? Localization.t("voice.failed") : (fellBack ? Localization.t("voice.copied_no_wtype") : Localization.t("voice.copied")));
            fellBack = false;
        }
    }

    Process {
        id: scanProc
        command: ["sh", "-c", 'test -x "$1" && echo server; test -f "$2" && echo model; command -v wtype >/dev/null && echo wtype; cat "$3/bin/version" 2>/dev/null | sed "s/^/version /"; ls "$3/models" 2>/dev/null', "sh", root.serverBin, root.modelFile, root.dataDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").filter(l => l !== "");
                root.serverFound = lines.includes("server");
                root.hasWtype = lines.includes("wtype");
                root.modelFound = lines.includes("model");
                root.engineVersion = (lines.find(l => l.startsWith("version ")) ?? "").slice(8);
                root.downloaded = lines.filter(l => l.endsWith(".bin"));
            }
        }
    }

    Process {
        id: installProc
        property int stage: 1
        command: ["bash", Quickshell.shellDir + "/scripts/voice-install.sh", root.dataDir, root.whisperTag, root.llamaTag]
        stderr: SplitParser {
            splitMarker: "\r"
            onRead: data => {
                const p = root._percent(data);
                const st = /stage:(\d)/.exec(data);
                if (st)
                    installProc.stage = parseInt(st[1]);
                else if (p >= 0)
                    root.installProgress = installProc.stage === 1 ? p * 0.75 : 0.75 + p * 0.25;
                else if (!st && data.trim() !== "" && !data.includes("#"))
                    root.installError = data.trim();
            }
        }
        onExited: code => {
            if (code === 0)
                root.installProgress = 1;
            root.installStep = code === 0 ? "" : "error";
            root.refresh();
        }
    }

    Process {
        id: dlProc
        property string target: ""
        stderr: SplitParser {
            splitMarker: "\r"
            onRead: data => {
                const p = root._percent(data);
                if (p >= 0)
                    root.downloadProgress = p;
            }
        }
        onExited: code => {
            const id = root.downloading;
            root.downloading = "";
            if (code === 0) {
                root.downloadProgress = 1;
                fsProc.command = ["mv", dlProc.target + ".part", dlProc.target];
                fsProc.running = true;
                root.selectModel(id);
            }
        }
    }

    Process {
        id: fsProc
        onExited: root.refresh()
    }

    Timer {
        id: flashTimer
        onTriggered: root.phase = "idle"
    }
}
