pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.style

Singleton {
    id: root

    property bool visible: false
    readonly property bool excludeFromBarOverlay: true
    property var history: []
    property string draftText: ""
    property var pendingAttachments: []
    property string streamedAnswer: ""
    property string displayedAnswer: ""
    property bool isStreaming: false
    property bool awaitingFirstToken: false
    property bool hasError: false
    property string errorText: ""

    readonly property int maxAttachments: 5

    property int _parsedLength: 0
    property string _streamBuffer: ""
    property string _pendingSubmitText: ""
    property var _pendingSubmitAttachments: []
    property bool _resendOnly: false
    property var _activeXhr: null

    readonly property var _mimeByExt: ({
            png: "image/png",
            jpg: "image/jpeg",
            jpeg: "image/jpeg",
            webp: "image/webp",
            gif: "image/gif",
            bmp: "image/bmp"
        })

    function currentProviderSupportsVision(): bool {
        return Config.aiAssistant.providers[Config.aiAssistant.provider]?.supportsVision === true;
    }

    function attachImageFromUrl(url: var): void {
        root._attachFromUrl(url);
    }

    function attachFileFromUrl(url: var): void {
        root._attachFromUrl(url);
    }

    function _attachFromUrl(url: var): void {
        if (root.pendingAttachments.length >= root.maxAttachments)
            return;
        const path = decodeURIComponent(url.toString().replace(/^file:\/\//, ""));
        const name = path.split("/").pop();
        const ext = name.includes(".") ? name.split(".").pop().toLowerCase() : "";
        const mimeType = root._mimeByExt[ext];

        if (mimeType && !root.currentProviderSupportsVision()) {
            root.hasError = true;
            root.errorText = Localization.t("aiAssistant.provider_lacks_vision");
            return;
        }

        const proc = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        const collector = Qt.createQmlObject('import Quickshell.Io; StdioCollector {}', proc);
        if (mimeType) {
            proc.command = ["base64", "-w0", path];
        } else {
            proc.command = ["head", "-c", "200000", path];
        }
        proc.stdout = collector;
        collector.streamFinished.connect(() => {
            if (collector.text.trim() !== "" && root.pendingAttachments.length < root.maxAttachments) {
                const attachment = mimeType ? {
                    kind: "image",
                    name: name,
                    mimeType: mimeType,
                    base64: collector.text.trim()
                } : {
                    kind: "file",
                    name: name,
                    textContent: collector.text
                };
                root.pendingAttachments = root.pendingAttachments.concat([attachment]);
            }
            proc.destroy();
        });
        proc.running = true;
    }

    function removeAttachment(index: int): void {
        const list = root.pendingAttachments.slice();
        if (index < 0 || index >= list.length)
            return;
        list.splice(index, 1);
        root.pendingAttachments = list;
    }

    function clearAttachments(): void {
        root.pendingAttachments = [];
    }

    signal responseFinished

    onVisibleChanged: visible ? PanelService.opened(root) : PanelService.closed(root)

    property var screenShots: ({})
    readonly property bool hasScreenAttachment: pendingAttachments.some(a => a.isScreenAttachment === true)

    function open(): void {
        if (root.visible)
            return;
        root.visible = true;
        root._captureAllScreens();
    }

    function _captureAllScreens(): void {
        root.screenShots = {};
        const screens = Quickshell.screens ?? [];
        for (const scr of screens) {
            const name = scr.name;
            const proc = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
            const collector = Qt.createQmlObject('import Quickshell.Io; StdioCollector {}', proc);
            proc.command = ["bash", "-c", "grim -o '" + name.replace(/'/g, "'\\''") + "' - | base64 -w0"];
            proc.stdout = collector;
            collector.streamFinished.connect(() => {
                if (collector.text.trim() !== "") {
                    const shots = Object.assign({}, root.screenShots);
                    shots[name] = {
                        mimeType: "image/png",
                        base64: collector.text.trim()
                    };
                    root.screenShots = shots;
                }
                proc.destroy();
            });
            proc.running = true;
        }
    }

    function attachScreenshot(screenName: string): void {
        const shot = root.screenShots[screenName];
        if (!shot || root.pendingAttachments.length >= root.maxAttachments)
            return;
        if (!root.currentProviderSupportsVision()) {
            root.hasError = true;
            root.errorText = Localization.t("aiAssistant.provider_lacks_vision");
            return;
        }
        root.pendingAttachments = root.pendingAttachments.concat([{
                kind: "image",
                name: "screen.png",
                mimeType: shot.mimeType,
                base64: shot.base64,
                isScreenAttachment: true
            }]);
    }

    function close(): void {
        root.visible = false;
    }

    function stop(): void {
        const xhr = root._activeXhr;
        root._activeXhr = null;
        if (xhr)
            xhr.abort();
        if (root.isStreaming) {
            if (root.awaitingFirstToken) {
                const last = root.history[root.history.length - 1];
                if (last?.role === "user")
                    root.history = root.history.slice(0, -1);
            } else if (root.streamedAnswer !== "") {
                _displayFlushTimer.stop();
                root.displayedAnswer = root.streamedAnswer;
                root.history = root.history.concat([{
                        role: "model",
                        text: root.streamedAnswer,
                        _skipEntranceAnim: true
                    }]);
            }
            root.isStreaming = false;
            root.awaitingFirstToken = false;
        }
    }

    function clearHistory(): void {
        root.stop();
        root.history = [];
        root.streamedAnswer = "";
        root.displayedAnswer = "";
        root.hasError = false;
        root.errorText = "";
        root.pendingAttachments = [];
    }

    function toggle(): void {
        if (root.visible)
            root.close();
        else
            root.open();
    }

    Timer {
        id: _retryTimer
        interval: 150
        onTriggered: root._trySubmit()
    }

    function submit(text: string): void {
        const trimmed = text.trim();
        if ((trimmed === "" && root.pendingAttachments.length === 0) || root.isStreaming)
            return;
        root._resendOnly = false;
        root._pendingSubmitText = trimmed;
        root._pendingSubmitAttachments = root.pendingAttachments;
        root.pendingAttachments = [];
        root._trySubmit();
    }

    readonly property bool canRetry: !isStreaming && hasError && history[history.length - 1]?.role === "user"

    function retry(): void {
        if (!root.canRetry)
            return;
        root._resendOnly = true;
        root._pendingSubmitText = root.history[root.history.length - 1].text ?? "";
        root._pendingSubmitAttachments = [];
        root._trySubmit();
    }

    function _trySubmit(): void {
        const cfg = Config.aiAssistant.providers[Config.aiAssistant.provider];
        if (!cfg) {
            root.hasError = true;
            root.errorText = Localization.t("aiAssistant.unknown_provider").arg(Config.aiAssistant.provider);
            return;
        }
        if (cfg.requiresAuth && !Secrets.ready) {
            _retryTimer.restart();
            return;
        }

        const resendOnly = root._resendOnly;
        root._resendOnly = false;

        const text = root._pendingSubmitText;
        const attachments = root._pendingSubmitAttachments.filter(a => a.kind === "file" || cfg.supportsVision === true);
        root._pendingSubmitText = "";
        root._pendingSubmitAttachments = [];

        if (!resendOnly)
            root.history = root.history.concat([{
                    role: "user",
                    text: text,
                    attachments: attachments
                }]);
        root.awaitingFirstToken = true;
        root._parsedLength = 0;
        root._streamBuffer = "";
        root.hasError = false;
        root.errorText = "";
        root.isStreaming = true;

        root._dispatch(cfg, text);
    }

    function _resolveSystemPrompt(): string {
        const template = Config.aiAssistant.systemPrompt ?? "";
        if (template.trim() === "")
            return "";
        const vars = {
            time: Qt.formatTime(new Date(), "h:mm AP"),
            date: Qt.formatDate(new Date(), "dddd, MMMM d"),
            compositor: SystemInfo.compositor,
            distro: SystemInfo.distroName,
            user: Quickshell.env("USER") ?? "user"
        };
        return template.replace(/\{(\w+)\}/g, (match, key) => vars[key] !== undefined ? vars[key] : match);
    }

    function _effectiveTextForTurn(h): string {
        let text = h.text ?? "";
        const files = (h.attachments ?? []).filter(a => a.kind === "file");
        files.forEach((f, i) => {
            text += (text ? "\n\n" : "") + "[BEGIN PASTED FILE " + (i + 1) + ": " + f.name + "]\n" + f.textContent + "\n[END PASTED FILE " + (i + 1) + "]";
        });
        return text;
    }

    function _dispatch(cfg, text): void {
        switch (cfg.apiType) {
        case "gemini":
            root._requestGemini(cfg);
            break;
        case "openai":
            root._requestOpenAi(cfg);
            break;
        case "ollama":
            root._requestOllama(cfg);
            break;
        default:
            root._fail(Localization.t("aiAssistant.unsupported_provider_type").arg(cfg.apiType));
        }
    }

    function _requestGemini(cfg): void {
        const key = cfg.requiresAuth ? Secrets.get(Config.aiAssistant.provider) : "";
        if (cfg.requiresAuth && key === "") {
            root._fail(Localization.t("aiAssistant.no_api_key").arg(Config.aiAssistant.provider));
            return;
        }

        const contents = root.history.map(h => {
            const parts = [];
            const text = root._effectiveTextForTurn(h);
            if (text)
                parts.push({
                    text: text
                });
            for (const img of (h.attachments ?? []).filter(a => a.kind === "image")) {
                parts.push({
                    inlineData: {
                        mimeType: img.mimeType,
                        data: img.base64
                    }
                });
            }
            return {
                role: h.role,
                parts: parts
            };
        });

        const systemPrompt = root._resolveSystemPrompt();
        const body = {
            contents: contents
        };
        if (systemPrompt)
            body.systemInstruction = {
                parts: [{
                        text: systemPrompt
                    }]
            };

        const xhr = new XMLHttpRequest();
        root._activeXhr = xhr;
        xhr.onreadystatechange = function () {
            root._handleSseProgress(xhr, root._extractGeminiDelta);
        };
        xhr.open("POST", cfg.endpoint + "/models/" + cfg.model + ":streamGenerateContent?alt=sse");
        xhr.setRequestHeader("Content-Type", "application/json");
        if (cfg.requiresAuth)
            xhr.setRequestHeader("x-goog-api-key", key);
        xhr.send(JSON.stringify(body));
    }

    function _extractGeminiDelta(json): string {
        return json?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
    }

    function _requestOpenAi(cfg): void {
        const key = cfg.requiresAuth ? Secrets.get(Config.aiAssistant.provider) : "";
        if (cfg.requiresAuth && key === "") {
            root._fail(Localization.t("aiAssistant.no_api_key").arg(Config.aiAssistant.provider));
            return;
        }

        const messages = root.history.map(h => {
            const text = root._effectiveTextForTurn(h);
            const images = (h.attachments ?? []).filter(a => a.kind === "image");
            if (images.length > 0) {
                const content = [];
                if (text)
                    content.push({
                        type: "text",
                        text: text
                    });
                for (const img of images) {
                    content.push({
                        type: "image_url",
                        image_url: {
                            url: "data:" + img.mimeType + ";base64," + img.base64
                        }
                    });
                }
                return {
                    role: h.role === "model" ? "assistant" : "user",
                    content: content
                };
            }
            return {
                role: h.role === "model" ? "assistant" : "user",
                content: text
            };
        });

        const systemPrompt = root._resolveSystemPrompt();
        if (systemPrompt)
            messages.unshift({
                role: "system",
                content: systemPrompt
            });

        const xhr = new XMLHttpRequest();
        root._activeXhr = xhr;
        xhr.onreadystatechange = function () {
            root._handleSseProgress(xhr, root._extractOpenAiDelta);
        };
        xhr.open("POST", cfg.endpoint + "/chat/completions");
        xhr.setRequestHeader("Content-Type", "application/json");
        if (cfg.requiresAuth)
            xhr.setRequestHeader("Authorization", "Bearer " + key);
        xhr.send(JSON.stringify({
                model: cfg.model,
                messages: messages,
                stream: true
            }));
    }

    function _extractOpenAiDelta(json): string {
        return json?.choices?.[0]?.delta?.content ?? "";
    }

    function _requestOllama(cfg): void {
        const key = cfg.requiresAuth ? Secrets.get(Config.aiAssistant.provider) : "";
        if (cfg.requiresAuth && key === "") {
            root._fail(Localization.t("aiAssistant.no_api_key").arg(Config.aiAssistant.provider));
            return;
        }

        const messages = root.history.map(h => {
            const msg = {
                role: h.role === "model" ? "assistant" : "user",
                content: root._effectiveTextForTurn(h)
            };
            const images = (h.attachments ?? []).filter(a => a.kind === "image").map(a => a.base64);
            if (images.length > 0)
                msg.images = images;
            return msg;
        });

        const systemPrompt = root._resolveSystemPrompt();
        if (systemPrompt)
            messages.unshift({
                role: "system",
                content: systemPrompt
            });

        const xhr = new XMLHttpRequest();
        root._activeXhr = xhr;
        xhr.onreadystatechange = function () {
            root._handleNdjsonProgress(xhr);
        };
        xhr.open("POST", cfg.endpoint + "/api/chat");
        xhr.setRequestHeader("Content-Type", "application/json");
        if (cfg.requiresAuth)
            xhr.setRequestHeader("Authorization", "Bearer " + key);
        xhr.send(JSON.stringify({
                model: cfg.model,
                messages: messages,
                stream: true
            }));
    }

    function _handleSseProgress(xhr, extractDelta): void {
        if (xhr !== root._activeXhr)
            return;
        const newSlice = xhr.responseText.substring(root._parsedLength);
        root._parsedLength = xhr.responseText.length;
        if (newSlice !== "")
            root._streamBuffer += newSlice.replace(/\r\n/g, "\n");

        const parts = root._streamBuffer.split("\n\n");
        root._streamBuffer = parts.pop() ?? "";
        root._consumeSseFrames(parts, extractDelta);

        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (root._streamBuffer.trim() !== "") {
                root._consumeSseFrames([root._streamBuffer], extractDelta);
                root._streamBuffer = "";
            }
            if (xhr.status === 200)
                root._finishStream();
            else
                root._fail(root._shortErrorMessage(xhr.status, xhr.responseText));
        }
    }

    function _appendDelta(delta: string): void {
        if (delta === "")
            return;
        if (root.awaitingFirstToken) {
            root.streamedAnswer = delta;
            root.displayedAnswer = delta;
            root.awaitingFirstToken = false;
        } else {
            root.streamedAnswer += delta;
            if (!_displayFlushTimer.running)
                _displayFlushTimer.start();
        }
    }

    Timer {
        id: _displayFlushTimer
        interval: 200
        repeat: true
        onTriggered: {
            if (root.displayedAnswer === root.streamedAnswer) {
                stop();
                return;
            }
            root.displayedAnswer = root.streamedAnswer;
        }
    }

    function _consumeSseFrames(frames, extractDelta): void {
        for (const frame of frames) {
            const line = frame.trim();
            if (!line.startsWith("data:"))
                continue;
            const payload = line.slice(5).trim();
            if (payload === "[DONE]")
                continue;
            try {
                const json = JSON.parse(payload);
                root._appendDelta(extractDelta(json));
            } catch (e) {
                console.log("AiAssistantService: SSE parse error:", e, payload);
            }
        }
    }

    function _handleNdjsonProgress(xhr): void {
        if (xhr !== root._activeXhr)
            return;
        const newSlice = xhr.responseText.substring(root._parsedLength);
        root._parsedLength = xhr.responseText.length;
        if (newSlice !== "")
            root._streamBuffer += newSlice.replace(/\r\n/g, "\n");

        const lines = root._streamBuffer.split("\n");
        root._streamBuffer = lines.pop() ?? "";
        let sawDone = root._consumeNdjsonLines(lines);

        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (root._streamBuffer.trim() !== "") {
                sawDone = root._consumeNdjsonLines([root._streamBuffer]) || sawDone;
                root._streamBuffer = "";
            }
            if (xhr.status === 200)
                root._finishStream();
            else
                root._fail(root._shortErrorMessage(xhr.status, xhr.responseText));
        } else if (sawDone) {
            root._finishStream();
        }
    }

    function _consumeNdjsonLines(lines): bool {
        let sawDone = false;
        for (const line of lines) {
            if (line.trim() === "")
                continue;
            try {
                const json = JSON.parse(line);
                root._appendDelta(json?.message?.content ?? "");
                if (json?.done === true)
                    sawDone = true;
            } catch (e) {
                console.log("AiAssistantService: NDJSON parse error:", e, line);
            }
        }
        return sawDone;
    }

    function _finishStream(): void {
        root._activeXhr = null;
        if (!root.isStreaming)
            return;
        _displayFlushTimer.stop();
        const wasVisible = !root.awaitingFirstToken;
        const finalText = root.awaitingFirstToken ? "" : root.streamedAnswer;
        root.streamedAnswer = finalText;
        root.displayedAnswer = finalText;
        root.history = root.history.concat([{
                role: "model",
                text: finalText,
                _skipEntranceAnim: wasVisible
            }]);
        root.isStreaming = false;
        root.awaitingFirstToken = false;

        if (Config.aiAssistant.notifyOnFinish)
            root._notify(Localization.t("aiAssistant.notify_summary"), finalText.length > 120 ? finalText.slice(0, 120) + "…" : finalText);

        root.responseFinished();
    }

    function _fail(message: string): void {
        root._activeXhr = null;
        if (!root.isStreaming)
            return;
        root.isStreaming = false;
        root.awaitingFirstToken = false;
        root.hasError = true;
        root.errorText = message;
    }

    function _notify(summary: string, body: string): void {
        const proc = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        proc.command = ["notify-send", "-u", "normal", "-a", "QuickShell", "-t", "5000", summary, body];
        proc.onExited.connect(() => proc.destroy());
        proc.running = true;
    }

    readonly property var _apiStatusMessages: ({
            INVALID_ARGUMENT: "Invalid request, check the prompt or key format",
            FAILED_PRECONDITION: "Free tier unavailable in your region, enable billing",
            PERMISSION_DENIED: "Invalid or unauthorized API key",
            NOT_FOUND: "Model not found",
            RESOURCE_EXHAUSTED: "Rate limit hit, wait a bit and try again",
            INTERNAL: "Server error, try again",
            UNAVAILABLE: "Server is overloaded, try again shortly",
            DEADLINE_EXCEEDED: "Request timed out, try again"
        })

    readonly property var _httpStatusMessages: ({
            400: "Invalid request",
            401: "Invalid API key",
            403: "Invalid or unauthorized API key",
            404: "Model not found",
            429: "Rate limit hit, wait a bit and try again",
            500: "Server error, try again",
            503: "Server is overloaded, try again shortly",
            504: "Request timed out, try again"
        })

    function _shortErrorMessage(status, bodyText): string {
        let apiStatus = "";
        try {
            apiStatus = JSON.parse(bodyText)?.error?.status ?? "";
        } catch (e) {}
        return root._apiStatusMessages[apiStatus] ?? root._httpStatusMessages[status] ?? Localization.t("aiAssistant.request_failed").arg(status);
    }
}
