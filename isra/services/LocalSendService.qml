pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.style

Singleton {
    id: root

    readonly property string baseUrl: "http://" + Config.localsend.host + ":" + Config.localsend.port
    property bool reachable: false

    readonly property bool widgetActive: WidgetService.allIds.includes("screencap") && !Config.bar.disabled.includes("screencap") && !Config.screencap.blacklist.includes("localsend")

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
            return "sending";
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
        const who = r.peer ?? "device";
        switch (r.kind) {
        case "sent":
            return who;
        case "received":
            return who;
        case "declined":
            return who + " declined";
        case "cancelled":
            return "Cancelled";
        case "recv_cancelled":
            return who + " cancelled";
        case "remote_cancelled":
            return who + " cancelled";
        case "recv_timeout":
            return "Request expired";
        case "recv_failed":
            return "Transfer from " + who + " failed";
        case "busy":
            return who + " is busy";
        case "rate_limited":
            return who + " is rate limiting";
        case "unreachable":
            return "Couldn't reach " + who;
        case "pin_required":
            return who + " requires a PIN";
        default:
            return "Couldn't send to " + who;
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
        _get("/api/self/v1/set-device-type?type=" + next, () => {});
    }

    function setEnabled(v) {
        Config.update({
            localsend: Object.assign({}, Config.localsend, {
                enabled: v
            })
        });
    }

    function setAlias(name) {
        Config.update({
            localsend: Object.assign({}, Config.localsend, {
                alias: name
            })
        });
        _get("/api/self/v1/set-alias?alias=" + encodeURIComponent((name ?? "").trim()), () => {});
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
        proc.command = ["stat", "--format=%s|%n"].concat(paths);
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
        const ip = device?.ip ?? device?.address ?? "";
        if (!ip)
            return;

        const who = device?.alias ?? device?.name ?? ip;
        root.pinRequest = null;
        root.dismissResult();
        root.lastSendRequest = {
            device: device,
            filePaths: filePaths,
            pin: pin ?? ""
        };
        root.pendingSend = {
            targetIp: ip,
            targetName: who,
            deviceType: device?.deviceType ?? "desktop",
            fileCount: filePaths.length,
            filePaths: filePaths,
            pin: pin ?? ""
        };
        pendingSendWatchdog.restart();

        _post("/api/self/v1/upload-batch", {
            target: ip,
            port: device?.port,
            protocol: device?.protocol,
            name: who,
            deviceType: device?.deviceType,
            files: filePaths.map(p => "file://" + p),
            pin: pin ?? ""
        }, (data, status) => {
            if (status !== null && status >= 200 && status < 300)
                return;
            root.pendingSend = null;
            pendingSendWatchdog.stop();
            root.lastResult = {
                id: "local-" + Date.now(),
                kind: status === 409 ? "busy" : "local_error",
                peer: who,
                deviceType: device?.deviceType ?? "desktop",
                count: filePaths.length,
                files: [],
                code: status,
                detail: status === 409 ? "Another transfer is already running." : (status === 400 ? "None of those files could be read." : "The LocalSend server didn't accept the request."),
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
        _get("/api/self/v1/cancel", () => root.refreshState());
    }

    function dismissResult() {
        const r = root.lastResult;
        root.lastResult = null;
        if (!r || r.local)
            return;
        _get("/api/self/v1/dismiss-result?id=" + encodeURIComponent(r.id ?? ""), () => {});
    }

    function confirmReceive(sessionId, confirmed) {
        if (!sessionId)
            return;
        if (root.pendingIncoming?.sessionId === sessionId)
            root.pendingIncoming = null;
        _get("/api/self/v1/confirm-recv?sessionId=" + encodeURIComponent(sessionId) + "&confirmed=" + (confirmed ? "true" : "false"), () => root.refreshState());
    }

    function scanNow() {
        if (!root.reachable)
            return;
        _get("/api/self/v1/scan-now", () => refreshDelay.restart());
    }

    function _request(method, path, body, onDone) {
        const req = new XMLHttpRequest();
        req.open(method, root.baseUrl + path);
        if (body !== undefined && body !== null)
            req.setRequestHeader("Content-Type", "application/json");
        req.onreadystatechange = () => {
            if (req.readyState !== XMLHttpRequest.DONE)
                return;
            const status = req.status === 0 ? null : req.status;
            if (status === null || status < 200 || status >= 300) {
                onDone?.(null, status);
                return;
            }
            try {
                onDone?.(req.responseText ? JSON.parse(req.responseText) : {}, status);
            } catch (e) {
                console.log("[LocalSend] parse error:", e);
                onDone?.(null, status);
            }
        };
        if (body !== undefined && body !== null)
            req.send(JSON.stringify(body));
        else
            req.send();
    }

    function _get(path, onDone) {
        _request("GET", path, null, onDone);
    }

    function _post(path, body, onDone) {
        _request("POST", path, body ?? {}, onDone);
    }

    property int _unreachableStreak: 0
    property bool _wasReachable: false
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
        root.pendingIncoming = s.incoming ?? null;
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
        _get("/api/self/v1/state", (data, status) => {
            root.reachable = data !== null;
            if (data === null) {
                root._onUnreachable();
                return;
            }
            root._onReachable();
            root._applyState(data);
        });
    }

    function _onReachable() {
        root._unreachableStreak = 0;
        if (!root._wasReachable) {
            root.stateSeq = -1;
            eventsSocket.connected = false;
            reconnectKick.restart();
        }
        root._wasReachable = true;
    }

    function _pushIdentity() {
        const wantType = Config.localsend.deviceType ?? "desktop";
        if (root.deviceTypes.includes(wantType) && root.localDeviceType && root.localDeviceType !== wantType)
            _get("/api/self/v1/set-device-type?type=" + wantType, () => {});
        const wantAlias = (Config.localsend.alias ?? "").trim();
        if (wantAlias && root.localAlias && root.localAlias !== wantAlias)
            _get("/api/self/v1/set-alias?alias=" + encodeURIComponent(wantAlias), () => {});
    }

    function _onUnreachable() {
        root._unreachableStreak++;
        root._wasReachable = false;
        root.pendingIncoming = null;
        root.activeTransfer = null;
        root.pendingSend = null;
        root.pinRequest = null;
        root.devices = [];
        root.stateSeq = -1;
        root._instanceId = "";
        if (root.lastResult && !root.lastResult.local)
            root.lastResult = null;

        if (serverProc.manageLocally && Config.localsend.enabled && root._unreachableStreak === 3) {
            console.log("[LocalSend] server unresponsive for", root._unreachableStreak * reachabilityTimer.interval / 1000, "s — forcing restart");
            serverProc.running = false;
            restartKick.restart();
        }
    }

    function notify(summary, body, urgency, timeout) {
        const proc = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        proc.command = ["notify-send", "-u", urgency ?? "normal", "-a", "LocalSend", "-t", String(timeout ?? 5000), summary, body ?? ""];
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

        if (root.widgetActive || !Config.localsend.notifyOnReceive)
            return;
        const names = root._fileListPreview(r.files);
        if (r.kind === "sent")
            root.notify("LocalSend", "Sent " + (names || root.plural(r.count, "file")) + " to " + r.peer, "low", 5000);
        else if (r.kind === "received")
            root.notify("LocalSend", "Received " + (names || root.plural(r.count, "file")) + " from " + r.peer, "low", 5000);
        else if (root.resultIsError)
            root.notify("LocalSend", root.resultTitle(r) + " — " + root.resultDetail(r), "critical", 6000);
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

        if (root.widgetActive || !Config.localsend.notifyOnReceive)
            return;
        root._pendingConfirmSessionId = inc.sessionId;
        const fc = inc.fileCount ?? (inc.files?.length ?? 0);
        confirmPromptProc.command = ["notify-send", "--action=accept=Accept", "--action=reject=Decline", "-u", "normal", "-a", "LocalSend", "-t", "0", (inc.from ?? "A device") + " wants to send " + root.plural(fc, "file"), root._fileListPreview(inc.files)];
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
            console.log("[LocalSend] bad message from server:", e);
            return;
        }
        if (msg.type === "state") {
            root.reachable = true;
            root._applyState(msg.data);
        }
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
        id: serverProc
        readonly property bool manageLocally: Config.localsend.host === "127.0.0.1" || Config.localsend.host === "localhost"
        command: ["python3", Quickshell.shellDir + "/scripts/localsend-server.py", "--port", String(Config.localsend.port), "--device-type", Config.localsend.deviceType ?? "desktop", "--alias", (Config.localsend.alias ?? "").trim()]
        running: Config.localsend.enabled && manageLocally
        onExited: (code, status) => console.log("[LocalSend] server exited, code:", code)
        stdout: SplitParser {
            onRead: line => console.log("[LocalSend/server]", line)
        }
        stderr: SplitParser {
            onRead: line => console.log("[LocalSend/server:err]", line)
        }
    }

    Timer {
        id: restartKick
        interval: 300
        onTriggered: serverProc.running = Config.localsend.enabled && serverProc.manageLocally
    }

    Socket {
        id: eventsSocket
        path: (Quickshell.env("XDG_RUNTIME_DIR") ?? "/tmp") + "/isra-localsend-events.sock"
        connected: Config.localsend.enabled
        parser: SplitParser {
            splitMarker: "\n"
            onRead: data => root._handleMessage(data)
        }
        onConnectionStateChanged: {
            if (connected)
                return;
            root.stateSeq = -1;
        }
    }

    Timer {
        id: reconnectKick
        interval: 400
        onTriggered: eventsSocket.connected = Config.localsend.enabled
    }

    Timer {
        interval: 500
        repeat: true
        running: Config.localsend.enabled && !eventsSocket.connected
        onTriggered: eventsSocket.connected = true
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

    Timer {
        id: reachabilityTimer
        interval: 3000
        repeat: true
        running: Config.localsend.enabled
        triggeredOnStart: true
        onTriggered: root.refreshState()
    }

    onWidgetActiveChanged: if (!widgetActive)
        root._lastNotifiedIncomingId = ""
}
