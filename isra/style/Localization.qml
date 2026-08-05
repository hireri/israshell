pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.style

Singleton {
    id: root

    readonly property string localesDir: Quickshell.shellDir + "/i18n/locales"

    property var _en: ({})
    property var _active: ({})
    property var manifest: ({})

    property bool translating: false
    property string translateError: ""

    function t(key) {
        const v = root._active[key];
        if (v !== undefined && v !== "")
            return v;
        return root._en[key] ?? key;
    }

    function _parseOrEmpty(text) {
        if (!text)
            return {};
        try {
            return JSON.parse(text);
        } catch (e) {
            console.log("Localization parse error:", e);
            return {};
        }
    }

    function _syncActive() {
        root._active = Config.language === "en_US" ? root._en : root._parseOrEmpty(activeFile.text());
    }

    FileView {
        id: enFile
        path: root.localesDir + "/en_US.json"
        watchChanges: true
        blockLoading: true
        Component.onCompleted: {
            root._en = root._parseOrEmpty(text());
            root._syncActive();
        }
        onLoaded: {
            root._en = root._parseOrEmpty(text());
            root._syncActive();
        }
        onFileChanged: reload()
    }

    FileView {
        id: manifestFile
        path: root.localesDir + "/manifest.json"
        watchChanges: true
        blockLoading: true
        Component.onCompleted: root.manifest = root._parseOrEmpty(text())
        onLoaded: root.manifest = root._parseOrEmpty(text())
        onFileChanged: reload()
    }

    FileView {
        id: activeFile
        path: (Config.language !== "" && Config.language !== "en_US") ? (root.localesDir + "/" + Config.language + ".json") : ""
        watchChanges: true
        blockLoading: true
        Component.onCompleted: root._syncActive()
        onLoaded: root._syncActive()
        onLoadFailed: root._active = {}
        onFileChanged: reload()
    }

    Connections {
        target: Config
        function onLanguageChanged() {
            root._syncActive();
        }
    }

    FileView {
        id: writerFile
        watchChanges: false
    }

    function _stripCodeFence(text) {
        const trimmed = text.trim();
        const match = trimmed.match(/^```(?:json)?\s*([\s\S]*?)\s*```$/);
        return match ? match[1] : trimmed;
    }

    function _writeJson(path, obj) {
        writerFile.path = path;
        writerFile.setText(JSON.stringify(obj, null, 2));
    }

    function _notify(summary, body) {
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
            INTERNAL: "Gemini server error, try again",
            UNAVAILABLE: "Gemini is overloaded, try again shortly",
            DEADLINE_EXCEEDED: "Request timed out, try again"
        })

    readonly property var _httpStatusMessages: ({
            400: "Invalid request",
            401: "Invalid API key",
            403: "Invalid or unauthorized API key",
            404: "Model not found",
            429: "Rate limit hit, wait a bit and try again",
            500: "Gemini server error, try again",
            503: "Gemini is overloaded, try again shortly",
            504: "Request timed out, try again"
        })

    function _shortErrorMessage(status, bodyText) {
        let apiStatus = "";
        try {
            apiStatus = JSON.parse(bodyText)?.error?.status ?? "";
        } catch (e) {}
        return root._apiStatusMessages[apiStatus] ?? root._httpStatusMessages[status] ?? ("Request failed (" + status + ")");
    }

    readonly property var _toneInstructions: ({
            formal: "Use a formal, professional tone, consistent with standard desktop operating system UI copy (e.g. GNOME, KDE, Windows).",
            playful: "Use a playful, characterful tone with some light wit and warmth — but never at the expense of clarity. A user must still immediately understand what every button, label, and toggle does at a glance, with zero ambiguity. Avoid gimmicky, meme-y, or infantile phrasing; aim for the charming, human voice of a well-loved app, not a joke.",
            concise: "Use the shortest possible phrasing for each string — terse, minimal, no filler words — while keeping the meaning clear."
        })

    readonly property var toneLabels: ({
            formal: "Formal",
            playful: "Playful",
            concise: "Concise"
        })

    function localeId(code, tone) {
        return tone === "formal" ? code : (code + "_" + tone);
    }

    function requestTranslation(code, displayName) {
        if (root.translating)
            return;

        const tone = Object.keys(root._toneInstructions).includes(Config.translationTone) ? Config.translationTone : "formal";
        const id = root.localeId(code, tone);

        if (id === "en_US") {
            root.translateError = root.t("localization.english_formal_is_already_default");
            return;
        }
        if (id in root.manifest) {
            root.translateError = root.t("localization.that_language_and_tone_installed");
            return;
        }

        const apiKey = Secrets.get("gemini");
        if (apiKey === "") {
            root.translateError = root.t("localization.no_gemini_api_key_configured");
            return;
        }

        root.translating = true;
        root.translateError = "";

        const toneInstruction = root._toneInstructions[tone];
        const isEnglishRestyle = code === "en_US";

        const prompt = (isEnglishRestyle ? "You are restyling the UI text of a Linux desktop shell (a status bar, control center and settings app, similar in scope to GNOME or KDE system settings). "
            + "Rewrite the string VALUES ONLY of the following JSON object, keeping them in English — do not translate to another language, only change the phrasing/style. "
            : "You are localizing the UI text of a Linux desktop shell (a status bar, control center and settings app, similar in scope to GNOME or KDE system settings). "
            + "Translate the string VALUES ONLY of the following JSON object into " + displayName + " (locale code " + code + "). ")
            + "Keep every key exactly as-is, unchanged. Keep any %1/%2 style placeholders and short technical format tokens (like \"hh:mm\") unchanged if translating them would break their meaning. "
            + "These strings render inside fixed-width UI chrome — pills, tiles, buttons, tabs — that size themselves to the English original, so length matters as much as meaning. Keep each translated string as close as possible to the character count of its English source. This is critical for short, one- or two-word strings (e.g. status labels, button text): prefer a shorter, slightly less literal translation over a longer, more precise one whenever a language's natural phrasing would otherwise run noticeably longer than the original. "
            + toneInstruction + " "
            + "Do not use emojis in any translated string, under any circumstance. "
            + "Return ONLY a raw JSON object with the same keys and translated/restyled values, no markdown fences, no commentary.\n\n"
            + JSON.stringify(root._en);

        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            root.translating = false;

            if (xhr.status !== 200) {
                root.translateError = root._shortErrorMessage(xhr.status, xhr.responseText);
                console.log("Localization translate error:", xhr.status, xhr.responseText);
                return;
            }

            try {
                const data = JSON.parse(xhr.responseText);
                const modelStep = (data.steps ?? []).find(s => s.type === "model_output");
                const textPart = modelStep?.content?.find(c => c.type === "text");
                const raw = textPart?.text;
                if (!raw)
                    throw new Error("no model_output text in response");
                const translated = JSON.parse(root._stripCodeFence(raw));

                const label = displayName + (tone !== "formal" ? " (" + root.toneLabels[tone] + ")" : "");

                root._writeJson(root.localesDir + "/" + id + ".json", translated);
                const nextManifest = Object.assign({}, root.manifest, {
                    [id]: label
                });
                root._writeJson(root.localesDir + "/manifest.json", nextManifest);
                root.manifest = nextManifest;

                Config.update({
                    language: id
                });

                root._notify(root.t("localization.notify_summary"), root.t("localization.notify_body").arg(label));
            } catch (e) {
                root.translateError = root.t("localization.couldnt_parse_gemini_response");
                console.log("Localization translate error:", e, xhr.responseText);
            }
        };

        xhr.open("POST", "https://generativelanguage.googleapis.com/v1beta/interactions");
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.setRequestHeader("x-goog-api-key", apiKey);
        xhr.send(JSON.stringify({
            model: "gemini-flash-lite-latest",
            input: prompt,
            store: false
        }));
    }
}
