pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.style

Singleton {
    id: root

    readonly property int port: 53317
    readonly property string socketPath: (Quickshell.env("XDG_RUNTIME_DIR") ?? "/tmp") + "/localsendd.sock"
    property bool reachable: false
    property bool daemonMissing: false

    readonly property bool widgetActive: PanelService.current?.panelType === "localsend"

    signal event(string type, var data)

    property var devices: []
    // {sessionId, from, deviceType, fileCount, totalBytes, files[]}
    property var pendingIncoming: null
    // {id, direction, phase, peer, deviceType, fileName, index, total,
    //  bytesDone, bytesTotal} while a transfer is in flight
    property var activeTransfer: null
    // {id, kind, peer, deviceType, count, files[], code, detail}
    property var lastResult: null
    property string localAlias: ""
    property string localIp: ""
    property string localDeviceType: ""
    property string localDownloadDir: ""
    property bool multicastOk: true
    property bool discoverable: false
    property bool encryptionOn: true
    property var encryptionPending: null
    readonly property bool encryptionTarget: root.encryptionPending !== null ? !!root.encryptionPending : root.encryptionOn
    readonly property bool ready: root.reachable && root.discoverable
    property int stateSeq: -1

    // Clientside {name, path, size}
    property var attachedFiles: []
    // {targetIp, filePaths, targetName, ...} while the recipient demands a pin
    property var pinRequest: null
    property var pendingSend: null
    // {device, filePaths, pin}
    property var lastSendRequest: null

    readonly property bool canRetry: root.resultIsError && !!root.lastSendRequest

    readonly property var okKinds: ["sent", "received"]
    readonly property var neutralKinds: ["cancelled", "recv_cancelled", "remote_cancelled", "declined", "recv_timeout"]

    readonly property bool resultIsOk: !!root.lastResult && root.okKinds.includes(root.lastResult.kind)
    readonly property bool resultIsNeutral: !!root.lastResult && root.neutralKinds.includes(root.lastResult.kind)
    readonly property bool resultIsPin: root.lastResult?.kind === "pin_required"
    readonly property bool resultIsError: !!root.lastResult && !root.resultIsOk && !root.resultIsNeutral && !root.resultIsPin

    readonly property bool transferring: !!root.activeTransfer && root.activeTransfer.phase === "transferring"
    readonly property bool awaitingPeer: (!!root.activeTransfer && root.activeTransfer.phase !== "transferring") || (!root.activeTransfer && !!root.pendingSend)
    readonly property bool receiving: root.activeTransfer?.direction === "recv"

    readonly property string pillState: {
        if (root.pendingIncoming)
            return "incoming";
        if (root.pinRequest)
            return "pin";
        if (root.transferring)
            return root.receiving ? "receiving" : "sending";
        if (root.awaitingPeer)
            return "waiting";
        if (root.resultIsError)
            return "error";
        if (root.attachedFiles.length > 0)
            return "staged";
        if (root.lastResult)
            return "done";
        return "idle";
    }

    readonly property real transferProgress: {
        const t = root.activeTransfer;
        if (!t)
            return 0;
        if ((t.bytesTotal ?? 0) > 0)
            return Math.max(0, Math.min(1, (t.bytesDone ?? 0) / t.bytesTotal));
        if ((t.total ?? 0) > 0)
            return Math.max(0, Math.min(1, (t.index ?? 0) / t.total));
        return 0;
    }

    readonly property var deviceTypes: ["desktop", "mobile", "web", "headless", "server"]

    function deviceTypeIcon(t) {
        switch (t) {
        case "mobile":
            return "mobile";
        case "desktop":
            return "monitor";
        case "web":
            return "language";
        case "headless":
            return "terminal";
        case "server":
            return "dns";
        default:
            return "question-mark";
        }
    }

    function resultTitle(r) {
        if (!r)
            return "";
        const who = r.peer ?? Localization.t("localSend.device");
        switch (r.kind) {
        case "sent":
            return who;
        case "received":
            return who;
        case "declined":
            return Localization.t("localSend.who_declined").arg(who);
        case "cancelled":
            return Localization.t("localSend.cancelled");
        case "recv_cancelled":
            return Localization.t("localSend.who_cancelled").arg(who);
        case "remote_cancelled":
            return Localization.t("localSend.who_cancelled").arg(who);
        case "recv_timeout":
            return Localization.t("localSend.request_expired");
        case "recv_failed":
            return Localization.t("localSend.transfer_from_who_failed").arg(who);
        case "busy":
            return Localization.t("localSend.who_is_busy").arg(who);
        case "rate_limited":
            return Localization.t("localSend.who_is_rate_limiting").arg(who);
        case "unreachable":
            return Localization.t("localSend.couldnt_reach_who").arg(who);
        case "pin_required":
            return Localization.t("localSend.who_requires_a_pin").arg(who);
        default:
            return Localization.t("localSend.couldnt_send_to_who").arg(who);
        }
    }

    function resultDetail(r) {
        if (!r)
            return "";
        if (r.detail)
            return r.detail;
        return r.code ? "The other device answered with HTTP " + r.code + "." : "";
    }


    function cycleDeviceType() {
        const cur = Config.localsend.deviceType ?? "desktop";
        const next = root.deviceTypes[(root.deviceTypes.indexOf(cur) + 1) % root.deviceTypes.length];
        Config.update({
            localsend: Object.assign({}, Config.localsend, {
                deviceType: next
            })
        });
        _call("set_device_type", { type: next });
    }

    function setEnabled(v) {
        Config.update({
            localsend: Object.assign({}, Config.localsend, {
                enabled: v
            })
        });
        _call("set_discoverable", { discoverable: !!v });
    }

    function setAlias(name) {
        Config.update({
            localsend: Object.assign({}, Config.localsend, {
                alias: name
            })
        });
        _call("set_alias", { alias: (name ?? "").trim() });
    }
    
    function setEncryption(enabled) {
        _call("set_encryption", {
            encryption: !!enabled
        }, (result, error) => {
            if (error) {
                root.notify("LocalSend", error.message || "Couldn't change encryption.", "normal", 5000);
                return;
            }
            if (result?.deferred)
                root.notify("LocalSend", "Encryption will change when the transfer finishes.", "low", 4000);
            root._pushedEncryption = !!enabled;
            Config.update({
                localsend: Object.assign({}, Config.localsend, {
                    encryption: !!enabled
                })
            });
        });
    }

    function setPin(pin) {
        Config.update({
            localsend: Object.assign({}, Config.localsend, {
                pin: pin
            })
        });
        _call("set_pin", { pin: pin ?? "" });
    }

    function attachFiles(files) {
        const staged = new Set(root.attachedFiles.map(f => f.path));
        const fresh = files.filter(f => !staged.has(f.path) && (staged.add(f.path), true));
        if (fresh.length > 0)
            root.attachedFiles = root.attachedFiles.concat(fresh);
    }

    function removeAttached(path) {
        root.attachedFiles = root.attachedFiles.filter(f => f.path !== path);
    }

    function clearAttached() {
        root.attachedFiles = [];
    }

    function attachedBytes() {
        return root.attachedFiles.reduce((a, f) => a + (f.size ?? 0), 0);
    }

    function attachFilesFromUrls(urls) {
        const paths = urls.map(u => decodeURIComponent(u.toString().replace(/^file:\/\//, "")));
        if (paths.length === 0)
            return;

        const proc = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        const collector = Qt.createQmlObject('import Quickshell.Io; StdioCollector {}', proc);
        proc.command = ["stat", "--format=%s|%n", "--"].concat(paths);
        proc.stdout = collector;
        collector.streamFinished.connect(() => {
            const files = collector.text.trim().split("\n").filter(l => l.length > 0).map(line => {
                const idx = line.indexOf("|");
                const size = parseInt(line.slice(0, idx), 10);
                const path = line.slice(idx + 1);
                return {
                    name: path.split("/").pop(),
                    path: path,
                    size: isNaN(size) ? 0 : size
                };
            });
            root.attachFiles(files);
            proc.destroy();
        });
        proc.running = true;
    }

    function sendFiles(device, filePaths, pin) {
        if (!filePaths || filePaths.length === 0)
            return;
        
        const ip = device?.ip ?? device?.address ?? (typeof device === "string" ? device : "");
        if (!ip)
            return;

        const actualPaths = filePaths.map(p => {
            let pathStr = typeof p === "string" ? p : (p.path ?? p.url ?? String(p));
            return pathStr.replace(/^file:\/\//, "");
        }).filter(p => p.length > 0);

        if (actualPaths.length === 0)
            return;

        const who = device?.alias ?? device?.name ?? ip;
        root.pinRequest = null;
        root.dismissResult();
        root.lastSendRequest = {
            device: device,
            filePaths: actualPaths,
            pin: pin ?? ""
        };
        root.pendingSend = {
            targetIp: ip,
            targetName: who,
            deviceType: device?.deviceType ?? "desktop",
            fileCount: actualPaths.length,
            filePaths: actualPaths,
            pin: pin ?? ""
        };
        pendingSendWatchdog.restart();

        _call("send", {
            to: ip,
            port: device?.port,
            protocol: device?.protocol,
            name: who,
            deviceType: device?.deviceType,
            files: actualPaths,
            pin: pin ?? ""
        }, (result, error) => {
            if (!error)
                return;
            root.pendingSend = null;
            pendingSendWatchdog.stop();
            root.lastResult = {
                id: "local-" + Date.now(),
                kind: error.code === "busy" ? "busy" : "local_error",
                peer: who,
                deviceType: device?.deviceType ?? "desktop",
                count: actualPaths.length,
                files: [],
                code: error.code,
                detail: error.message || "localsendd didn't accept the request.",
                local: true
            };
            root._maybeNotifyResult();
        });
    }

    function retryLastSend() {
        const req = root.lastSendRequest;
        if (!req)
            return;
        root.sendFiles(req.device, req.filePaths, req.pin);
    }

    function submitPin(pin) {
        if (!root.pinRequest)
            return;
        const r = root.pinRequest;
        root.pinRequest = null;
        root.sendFiles(r.device, r.filePaths, pin);
    }

    function cancelPinRequest() {
        root.pinRequest = null;
        if (root.resultIsPin)
            root.dismissResult();
    }

    function cancelAll() {
        root.pendingSend = null;
        pendingSendWatchdog.stop();
        _call("cancel");
    }

    function dismissResult() {
        const r = root.lastResult;
        root.lastResult = null;
        if (!r || r.local)
            return;
        _call("dismiss_result", { id: r.id ?? "" });
    }

    function confirmReceive(sessionId, confirmed) {
        if (!sessionId)
            return;
        if (root.pendingIncoming?.sessionId === sessionId)
            root.pendingIncoming = null;
        _call("confirm_receive", { sessionId: sessionId, confirmed: !!confirmed });
    }

    function scanNow() {
        if (!root.reachable)
            return;
        _call("scan", {}, () => refreshDelay.restart());
    }

    property int _nextCallId: 0
    property var _pendingCalls: ({})

    function _call(method, params, onDone) {
        if (!root.socketConnected) {
            onDone?.(null, {
                code: "unreachable",
                message: "localsendd isn't running."
            });
            return;
        }
        root._nextCallId++;
        const id = root._nextCallId;
        if (onDone)
            root._pendingCalls[id] = onDone;
        root._socket.write(JSON.stringify({
            id: id,
            method: method,
            params: params ?? {}
        }) + "\n");
        root._socket.flush();
    }

    function _failPendingCalls() {
        const pending = root._pendingCalls;
        root._pendingCalls = ({});
        for (const id in pending) {
            const cb = pending[id];
            if (cb)
                cb(null, {
                    code: "unreachable",
                    message: "localsendd went away."
                });
        }
    }

    property string _daemonPath: ""
    property var _socket: null
    readonly property bool socketConnected: root._socket?.connected ?? false
    property string _pushedPin: ""
    property var _pushedDiscoverable: null
    property var _pushedEncryption: null
    property string _instanceId: ""
    property string _lastNotifiedResultId: ""
    property string _lastNotifiedIncomingId: ""
    property string _pendingConfirmSessionId: ""

    function _applyState(s) {
        if (!s || typeof s !== "object")
            return;

        const instance = s.instanceId ?? "";
        if (instance !== root._instanceId) {
            root._instanceId = instance;
            root.stateSeq = -1;
        }
        if ((s.seq ?? 0) < root.stateSeq)
            return;
        root.stateSeq = s.seq ?? 0;

        root.devices = s.devices ?? [];
        const inc = s.incoming ?? null;
        if ((inc?.sessionId ?? "") !== (root.pendingIncoming?.sessionId ?? ""))
            root.pendingIncoming = inc;
        root.activeTransfer = s.active ?? null;

        const wasLocal = root.lastResult?.local ?? false;
        const incomingResult = s.result ?? null;
        if (incomingResult || !wasLocal)
            root.lastResult = incomingResult;

        if (s.self) {
            root.localAlias = s.self.alias ?? "";
            root.localIp = s.self.localIp ?? "";
            root.localDeviceType = s.self.deviceType ?? "";
            root.localDownloadDir = s.self.downloadDir ?? "";
            root.multicastOk = s.self.multicast !== false;
            root.discoverable = s.self.discoverable !== false;
            root.encryptionOn = s.self.encryption !== false;
            root.encryptionPending = s.self.pendingEncryption ?? null;
            root._pushIdentity();
        }

        if (root.activeTransfer || root.lastResult) {
            root.pendingSend = null;
            pendingSendWatchdog.stop();
        }

        root._reconcilePinRequest();
        root._maybeNotifyResult();
        root._maybeNotifyIncoming();
    }

    function _reconcilePinRequest() {
        const r = root.lastResult;
        if (r?.kind !== "pin_required") {
            if (root.pinRequest && r && r.id !== root.pinRequest.resultId)
                root.pinRequest = null;
            return;
        }
        if (root.pinRequest?.resultId === r.id)
            return;
        const req = root.lastSendRequest;
        root.pinRequest = {
            resultId: r.id,
            targetName: r.peer,
            deviceType: r.deviceType,
            badPin: !!(req?.pin),
            device: req?.device ?? null,
            filePaths: req?.filePaths ?? root.attachedFiles.map(f => f.path)
        };
    }

    function refreshState() {
        _call("get_state", {}, (data, error) => {
            if (!error)
                root._applyState(data);
        });
    }

    function _onReachable() {
        root.reachable = true;
        root.daemonMissing = false;
        root.stateSeq = -1;
        root._pushedPin = "";
        root._pushedDiscoverable = null;
        root._pushedEncryption = null;
    }

    function _pushIdentity() {
        const wantType = Config.localsend.deviceType ?? "desktop";
        if (root.deviceTypes.includes(wantType) && root.localDeviceType && root.localDeviceType !== wantType)
            _call("set_device_type", { type: wantType });
        const wantAlias = (Config.localsend.alias ?? "").trim();
        if (wantAlias && root.localAlias && root.localAlias !== wantAlias)
            _call("set_alias", { alias: wantAlias });
        const wantPin = Config.localsend.pin ?? "";
        if (root._pushedPin !== wantPin) {
            root._pushedPin = wantPin;
            _call("set_pin", { pin: wantPin });
        }
        const wantVisible = Config.localsend.enabled ?? false;
        if (root._pushedDiscoverable !== wantVisible) {
            root._pushedDiscoverable = wantVisible;
            _call("set_discoverable", { discoverable: wantVisible });
        }
        const wantEncryption = Config.localsend.encryption ?? true;
        if (root._pushedEncryption !== wantEncryption) {
            root._pushedEncryption = wantEncryption;
            _call("set_encryption", { encryption: wantEncryption });
        }
    }

    function _onUnreachable() {
        root.reachable = false;
        root._failPendingCalls();
        root.pendingIncoming = null;
        root.activeTransfer = null;
        root.pendingSend = null;
        root.pinRequest = null;
        root.devices = [];
        root.stateSeq = -1;
        root._instanceId = "";
        if (root.lastResult && !root.lastResult.local)
            root.lastResult = null;
    }

    function notify(summary, body, urgency, timeout, deviceType) {
        const proc = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        proc.command = ["notify-send", "-u", urgency ?? "normal", "-a", "LocalSend", "-t", String(timeout ?? 5000), "-h", "boolean:suppress-sound:true", "-h", "string:x-material-icon:" + root.deviceTypeIcon(deviceType ?? "desktop"), summary, body ?? ""];
        proc.onExited.connect(() => proc.destroy());
        proc.running = true;
    }

    function _fileListPreview(files) {
        const names = (files ?? []).map(f => f.fileName ?? f.name ?? "file");
        if (names.length === 0)
            return "";
        if (names.length <= 3)
            return names.join(", ");
        return names.slice(0, 3).join(", ") + " and " + (names.length - 3) + " more";
    }

    function _maybeNotifyResult() {
        const r = root.lastResult;
        if (!r || r.id === root._lastNotifiedResultId)
            return;
        root._lastNotifiedResultId = r.id;
        if (root.resultIsOk)
            doneClearTimer.restart();
        else if (root.resultIsNeutral)
            neutralClearTimer.restart();

        if (r.kind === "sent") {
            root.clearAttached();
            root.lastSendRequest = null;
        }

        root.event("result", r);

        if (!Config.localsend.notifyOnReceive)
            return;
        if (r.kind === "sent")
            SoundService.localSendDone();
        else if (r.kind === "received")
            SoundService.localSendDone();
        else if (root.resultIsError)
            SoundService.localSendError();

        if (root.widgetActive)
            return;
        const names = root._fileListPreview(r.files);
        if (r.kind === "sent") {
            root.notify("LocalSend", "Sent " + (names || root.plural(r.count, "file")) + " to " + r.peer, "low", 5000, r.deviceType);
        } else if (r.kind === "received") {
            root.notify("LocalSend", "Received " + (names || root.plural(r.count, "file")) + " from " + r.peer, "low", 5000, r.deviceType);
        } else if (root.resultIsError) {
            root.notify("LocalSend", root.resultTitle(r) + " — " + root.resultDetail(r), "critical", 6000, r.deviceType);
        }
    }

    function _maybeNotifyIncoming() {
        const inc = root.pendingIncoming;
        if (!inc) {
            root._lastNotifiedIncomingId = "";
            return;
        }
        if (inc.sessionId === root._lastNotifiedIncomingId)
            return;
        root._lastNotifiedIncomingId = inc.sessionId;
        root.event("incoming", inc);

        if (!Config.localsend.notifyOnReceive)
            return;
        SoundService.localSendIncoming();

        if (root.widgetActive)
            return;
        root._pendingConfirmSessionId = inc.sessionId;
        const fc = inc.fileCount ?? (inc.files?.length ?? 0);
        confirmPromptProc.command = ["notify-send", "--action=accept=Accept", "--action=reject=Decline", "-u", "normal", "-a", "LocalSend", "-t", "0", "-h", "boolean:suppress-sound:true", "-h", "string:x-material-icon:" + root.deviceTypeIcon(inc.deviceType), (inc.from ?? "A device") + " wants to send " + root.plural(fc, "file"), root._fileListPreview(inc.files)];
        confirmPromptProc.running = true;
    }

    function plural(n, noun) {
        return (n ?? 0) + " " + noun + ((n ?? 0) === 1 ? "" : "s");
    }

    function _handleMessage(line) {
        let msg;
        try {
            msg = JSON.parse(line);
        } catch (e) {
            console.log("[LocalSend] bad frame from localsendd:", e);
            return;
        }

        if (msg.id !== undefined && msg.id !== null) {
            const cb = root._pendingCalls[msg.id];
            if (!cb)
                return;
            delete root._pendingCalls[msg.id];
            if (msg.ok)
                cb(msg.result ?? {}, null);
            else
                cb(null, msg.error ?? {
                    code: "unknown",
                    message: "Request failed."
                });
            return;
        }

        if (msg.type === "state")
            root._applyState(msg.data);
        root.event(msg.type, msg.data ?? {});
    }

    Timer {
        id: doneClearTimer
        interval: 5000
        onTriggered: if (root.resultIsOk)
            root.dismissResult()
    }

    Timer {
        id: neutralClearTimer
        interval: 6000
        onTriggered: if (root.resultIsNeutral)
            root.dismissResult()
    }

    Timer {
        id: pendingSendWatchdog
        interval: 8000
        onTriggered: {
            root.pendingSend = null;
            root.refreshState();
        }
    }

    Timer {
        id: refreshDelay
        interval: 600
        onTriggered: root.refreshState()
    }

    Process {
        id: daemonProbe
        command: ["sh", "-c", "command -v localsendd"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root._daemonPath = text.trim();
                root.daemonMissing = root._daemonPath.length === 0;
                if (root.daemonMissing)
                    console.log("[LocalSend] localsendd not found on PATH — install with: uv tool install localsendd");
            }
        }
    }

    Component {
        id: socketComponent

        Socket {
            path: root.socketPath
            connected: true
            parser: SplitParser {
                splitMarker: "\n"
                onRead: data => root._handleMessage(data)
            }
            onConnectionStateChanged: {
                if (connected) {
                    root._onReachable();
                } else {
                    root.stateSeq = -1;
                    root._onUnreachable();
                }
            }
        }
    }

    function _reopenSocket() {
        if (root._socket) {
            root._socket.connected = false;
            root._socket.destroy();
            root._socket = null;
        }
        root._socket = socketComponent.createObject(root);
    }

    Timer {
        interval: 700
        repeat: true
        running: !root.socketConnected
        triggeredOnStart: true
        onTriggered: root._reopenSocket()
    }

    Process {
        id: confirmPromptProc
        stdout: SplitParser {
            onRead: action => {
                const sessionId = root._pendingConfirmSessionId;
                root._pendingConfirmSessionId = "";
                if (sessionId && (action === "accept" || action === "reject"))
                    root.confirmReceive(sessionId, action === "accept");
            }
        }
    }

    onWidgetActiveChanged: if (!widgetActive)
        root._lastNotifiedIncomingId = ""
}