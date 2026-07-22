import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import qs.components.launcher
import qs.style

Scope {
    id: root

    property bool isOpen: false
    property bool _opening: false
    property bool _animating: false

    readonly property var _visual: visualLoader.item

    property string _query: ""

    property bool _sortAlpha: true

    readonly property string mode: {
        const q = _query;
        if (q.startsWith(";"))
            return "clipboard";
        if (q.startsWith(":"))
            return "emoji";
        if (_detectLang(q) !== "")
            return "translate";
        return "apps";
    }

    readonly property string modeQuery: {
        if (mode === "clipboard" || mode === "emoji")
            return _query.slice(1).replace(/^\s+/, "");
        if (mode === "translate") {
            const sp = _query.indexOf(" ");
            return sp === -1 ? "" : _query.slice(sp + 1);
        }
        return _query;
    }

    readonly property string translateTarget: _detectLang(_query)

    readonly property string widgetType: {
        if (mode === "translate")
            return "translate";
        if (mode !== "apps")
            return "";
        const q = _query.trim();
        if (q === "")
            return "";

        if (/^#[0-9a-fA-F]{3,8}$/.test(q))
            return "color";
        if (/^(?:rgb|hsl|oklch)\s*\(/.test(q))
            return "color";

        if (/^\d{9,11}$/.test(q))
            return "timestamp";
        if (/^(?:days?\s+(?:until|since|to|from)|time\s+since|how\s+long\s+(?:since|ago))/i.test(q))
            return "timestamp";

        if (/^def(?:ine)?\s+\S+/i.test(q))
            return "define";

        if (/^whois\s+\S+/i.test(q))
            return "whois";
        if (/^ip\s+[\d.]/i.test(q))
            return "whois";

        if (/^kao(?:moji)?(?:\s|$)/i.test(q))
            return "kaomoji";

        if (/^[+-]?[\d.,]+\s*°?\s*[a-zA-Z][a-zA-Z\/]{0,19}\s+(?:to|in)\s+°?\s*[a-zA-Z][a-zA-Z\/]{0,19}$/i.test(q))
            return "math";
        if (/\d/.test(q) && /[+\-*\/^%]/.test(q))
            return "math";
        if (/\b(?:sqrt|cbrt|sind?|cosd?|tand?|asin|acos|atan2?|log|ln|exp|abs|floor|ceil|round|trunc|pow|min|max)\s*\(/.test(q))
            return "math";
        if (/\b(?:pi|e)\b/.test(q) && /[+\-*\/^%]/.test(q))
            return "math";

        return "";
    }

    readonly property string widgetQuery: {
        const q = _query.trim();
        const defM = /^def(?:ine)?\s+(.+)$/i.exec(q);
        if (defM)
            return defM[1].trim();
        const whoisM = /^(?:whois|ip)\s+(.+)$/i.exec(q);
        if (whoisM)
            return whoisM[1].trim();
        const kaoM = /^kao(?:moji)?(?:\s+(.*))?$/i.exec(q);
        if (kaoM)
            return (kaoM[1] || "").trim();
        return q;
    }

    readonly property var _langMap: ({
            "en": "en",
            "english": "en",
            "de": "de",
            "german": "de",
            "deutsch": "de",
            "fr": "fr",
            "french": "fr",
            "it": "it",
            "italian": "it",
            "es": "es",
            "spanish": "es",
            "pt": "pt",
            "portuguese": "pt",
            "ru": "ru",
            "russian": "ru",
            "ja": "ja",
            "japanese": "ja",
            "zh": "zh",
            "chinese": "zh",
            "ko": "ko",
            "korean": "ko",
            "ar": "ar",
            "arabic": "ar",
            "nl": "nl",
            "dutch": "nl",
            "pl": "pl",
            "polish": "pl",
            "tr": "tr",
            "turkish": "tr",
            "sv": "sv",
            "swedish": "sv",
            "no": "no",
            "norwegian": "no",
            "da": "da",
            "danish": "da",
            "fi": "fi",
            "finnish": "fi"
        })

    function _detectLang(q) {
        const parts = q.trim().split(/\s+/);
        if (parts.length < 2)
            return "";
        const first = parts[0].toLowerCase();
        if (!(first in _langMap))
            return "";
        if (first.length <= 2 && parts.slice(1).join(" ").trim().length < 3)
            return "";
        return _langMap[first];
    }

    function _substringEditDistance(query, target, maxEdits) {
        const m = query.length;
        const n = target.length;
        if (m === 0) return 0;
        if (n === 0) return m;

        if (maxEdits !== undefined && (m - n) > maxEdits)
            return maxEdits + 1;

        let prevRow = new Array(n + 1).fill(0);
        let currRow = new Array(n + 1);

        for (let i = 1; i <= m; i++) {
            currRow[0] = i;
            for (let j = 1; j <= n; j++) {
                const cost = query.charAt(i - 1) === target.charAt(j - 1) ? 0 : 1;
                currRow[j] = Math.min(
                    prevRow[j - 1] + cost,
                    prevRow[j] + 1,
                    currRow[j - 1] + 1
                );
            }
            const tmp = prevRow;
            prevRow = currRow;
            currRow = tmp;
        }

        let minVal = prevRow[0];
        for (let j = 1; j <= n; j++) {
            if (prevRow[j] < minVal) {
                minVal = prevRow[j];
                if (minVal === 0)
                    break;
            }
        }
        return minVal;
    }

    function _maxAllowedEdits(queryLength) {
        if (queryLength <= 2) return 0;
        if (queryLength <= 4) return 1;
        if (queryLength <= 7) return 2;
        return Math.floor(queryLength / 3);
    }

    function _scoreApp(app, q) {
        const name = (app.name || "").toLowerCase();
        const genericName = (app.genericName || "").toLowerCase();
        const comment = (app.comment || "").toLowerCase();

        if (name === q) {
            return { matched: true, score: 1000 };
        }
        if (name.startsWith(q)) {
            return { matched: true, score: 900 - name.length };
        }
        if (name.includes(q)) {
            return { matched: true, score: 800 - name.indexOf(q) - name.length };
        }

        const maxEdits = _maxAllowedEdits(q.length);

        const nameDist = _substringEditDistance(q, name, maxEdits);
        if (nameDist <= maxEdits) {
            return { matched: true, score: 700 - nameDist * 50 - name.length };
        }

        if (genericName !== "") {
            if (genericName.startsWith(q)) {
                return { matched: true, score: 600 - genericName.length };
            }
            if (genericName.includes(q)) {
                return { matched: true, score: 550 - genericName.length };
            }
            const genDist = _substringEditDistance(q, genericName, maxEdits);
            if (genDist <= maxEdits) {
                return { matched: true, score: 500 - genDist * 50 - genericName.length };
            }
        }

        const keywords = app.keywords || [];
        for (let i = 0; i < keywords.length; i++) {
            const kw = keywords[i].toLowerCase();
            if (kw === q) {
                return { matched: true, score: 450 };
            }
            if (kw.startsWith(q)) {
                return { matched: true, score: 400 - kw.length };
            }
            if (kw.includes(q)) {
                return { matched: true, score: 380 - kw.length };
            }
            const kwDist = _substringEditDistance(q, kw, maxEdits);
            if (kwDist <= maxEdits) {
                return { matched: true, score: 350 - kwDist * 50 };
            }
        }

        if (comment !== "") {
            if (comment.includes(q)) {
                return { matched: true, score: 300 - comment.length * 0.1 };
            }
        }

        const categories = app.categories || [];
        for (let i = 0; i < categories.length; i++) {
            const cat = categories[i].toLowerCase();
            if (cat === q) {
                return { matched: true, score: 200 };
            }
            if (cat.startsWith(q)) {
                return { matched: true, score: 180 - cat.length };
            }
            if (cat.includes(q)) {
                return { matched: true, score: 160 - cat.length };
            }
        }

        return { matched: false, score: 0 };
    }

    property var _emojiData: []
    property bool _emojiLoaded: false

    Process {
        id: emojiLoader
        command: ["sh", "-c", ["dir=\"$HOME/.config/quickshell/isra/components/emojis\"", "files=\"emojis_smileys_emotion.csv emojis_people_body.csv emojis_activities.csv emojis_animals_nature.csv emojis_food_drink.csv emojis_objects.csv emojis_travel_places.csv emojis_symbols.csv emojis_flags.csv\"", "for f in $files; do cat \"$dir/$f\" 2>/dev/null; done"].join("\n")]
        stdout: StdioCollector {
            onStreamFinished: {
                const re = /^(\S+)\s+(.*?)\s*(?:<small>\(([^)]*)\)<\/small>)?\s*$/;
                const parsed = [];
                for (const line of this.text.split("\n")) {
                    if (!line.trim())
                        continue;
                    const m = line.match(re);
                    if (!m)
                        continue;
                    parsed.push({
                        emoji: m[1],
                        name: m[2].trim(),
                        keywords: m[3] ? m[3].split(",").map(k => k.trim().toLowerCase()) : []
                    });
                }
                root._emojiData = parsed;
                root._emojiLoaded = true;
            }
        }
    }

    property var _kaomojiData: []
    property bool _kaomojiLoaded: false

    function _splitCsvLine(line) {
        const fields = [];
        let cur = "";
        let inQuotes = false;
        for (let i = 0; i < line.length; i++) {
            const c = line[i];
            if (inQuotes) {
                if (c === "\"") {
                    if (line[i + 1] === "\"") {
                        cur += "\"";
                        i++;
                    } else {
                        inQuotes = false;
                    }
                } else {
                    cur += c;
                }
            } else if (c === "\"" && cur === "") {
                inQuotes = true;
            } else if (c === ",") {
                fields.push(cur);
                cur = "";
            } else {
                cur += c;
            }
        }
        fields.push(cur);
        return fields;
    }

    Process {
        id: kaomojiLoader
        command: ["sh", "-c", "cat \"$HOME/.config/quickshell/isra/components/emojis/kaomoji.csv\" 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parsed = [];
                for (const rawLine of this.text.split("\n")) {
                    const line = rawLine.replace(/\r$/, "");
                    if (!line.trim())
                        continue;
                    const fields = root._splitCsvLine(line);
                    if (fields.length < 3)
                        continue;
                    const face = fields[0].trim();
                    if (face.toLowerCase() === "emoji")
                        continue;
                    const tagsStr = fields[fields.length - 1];
                    const tags = tagsStr.split("|").map(t => t.trim().toLowerCase()).filter(Boolean);
                    if (face === "" || tags.length === 0)
                        continue;
                    parsed.push({
                        face: face,
                        tags: tags
                    });
                }
                root._kaomojiData = parsed;
                root._kaomojiLoaded = true;
            }
        }
    }

    property var _clipEntries: []

    Process {
        id: clipLoader
        command: ["clipvault", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parsed = [];
                for (const line of this.text.trim().split("\n")) {
                    if (!line.trim())
                        continue;
                    const tab = line.indexOf("\t");
                    if (tab === -1)
                        continue;
                    const id = line.slice(0, tab).trim();
                    const content = line.slice(tab + 1);
                    const trimmed = content.trim();
                    if (trimmed.startsWith("[[ binary data ")) {
                        const mm = /\[\[ binary data ([^\]]+?)\s*\]\]/.exec(trimmed);
                        parsed.push({
                            id,
                            isImage: true,
                            content: "",
                            mime: mm ? mm[1].trim() : "image/png"
                        });
                    } else {
                        parsed.push({
                            id,
                            isImage: false,
                            content: trimmed,
                            mime: "text/plain"
                        });
                    }
                }
                root._clipEntries = parsed;
            }
        }
    }

    onModeChanged: {
        const v = _visual;
        if (v) v.launcherList.resetToTop();
        if (mode === "clipboard") {
            _clipEntries = [];
            clipLoader.running = false;
            clipLoader.running = true;
        }
        if (mode === "emoji" && !root._emojiLoaded)
            emojiLoader.running = true;
    }

    onWidgetTypeChanged: {
        if (widgetType === "kaomoji" && !root._kaomojiLoaded)
            kaomojiLoader.running = true;
    }

    ScriptModel {
        id: unifiedModel
        objectProp: "uid"
        values: {
            const q = root.modeQuery.trim().toLowerCase();
            const mode = root.mode;

            if (mode === "apps" || mode === "translate") {
                const all = DesktopEntries.applications.values.slice();

                if (q === "") {
                    const mapped = arr => arr.map(d => ({
                                    type: "app",
                                    uid: "app_" + d.id,
                                    entry: d
                                }));
                    if (root._sortAlpha) {
                        return mapped(all.sort((a, b) => a.name.localeCompare(b.name)));
                    } else {
                        return mapped(all.sort((a, b) => {
                            const ac = a.categories?.[0] ?? "ZZZ";
                            const bc = b.categories?.[0] ?? "ZZZ";
                            const cmp = ac.localeCompare(bc);
                            return cmp !== 0 ? cmp : a.name.localeCompare(b.name);
                        }));
                    }
                }

                const scored = [];
                for (let i = 0; i < all.length; i++) {
                    const d = all[i];
                    const res = root._scoreApp(d, q);
                    if (res.matched) {
                        scored.push({
                            type: "app",
                            uid: "app_" + d.id,
                            entry: d,
                            _score: res.score
                        });
                    }
                }

                return scored.sort((a, b) => {
                    if (Math.abs(a._score - b._score) < 0.0001) {
                        return a.entry.name.localeCompare(b.entry.name);
                    }
                    return b._score - a._score;
                });
            }

            if (mode === "clipboard") {
                const entries = root._clipEntries;
                const filtered = q === "" ? entries : entries.filter(e => e.isImage ? e.mime.includes(q) || "image".includes(q) : e.content.toLowerCase().includes(q));
                return filtered.slice(0, 200).map(e => Object.assign({
                        type: "clip",
                        uid: "clip_" + e.id
                    }, e));
            }

            if (mode === "emoji") {
                if (!root._emojiLoaded)
                    return [];
                const words = q === "" ? [] : q.split(/\s+/).filter(Boolean);
                if (words.length === 0)
                    return root._emojiData.map(e => Object.assign({
                            type: "emoji",
                            uid: "emoji_" + e.emoji
                        }, e));

                return root._emojiData.map(e => {
                    const name = e.name.toLowerCase();
                    const keyStr = e.keywords.join(" ");
                    if (!words.every(w => (name + " " + keyStr).includes(w)))
                        return null;

                    let score = 3;
                    if (name === q)
                        score = 0;
                    else if (name.startsWith(q))
                        score = 1;
                    else if (name.includes(q))
                        score = 2;

                    return Object.assign({
                        type: "emoji",
                        uid: "emoji_" + e.emoji,
                        _score: score
                    }, e);
                }).filter(Boolean).sort((a, b) => a._score - b._score || a.name.localeCompare(b.name));
            }

            return [];
        }
    }

    Process {
        id: launchProc
        running: false
    }
    Process {
        id: copyProc
        running: false
    }
    Process {
        id: imgCopyProc
        running: false
    }

    function _handleActivation(entry) {
        if (entry.type === "app") {
            const e = entry.entry;
            const cwd = e.workingDirectory !== "" ? e.workingDirectory : Quickshell.env("HOME");

            let cmd;
            if (e.runInTerminal) {
                cmd = ["kitty", "-e", ...e.command];
            } else {
                cmd = e.command;
            }

            Quickshell.execDetached({
                command: cmd,
                workingDirectory: cwd
            });
            close();
        } else if (entry.type === "clip") {
            if (entry.isImage) {
                imgCopyProc.command = ["sh", "-c", "clipvault get " + entry.id + " | wl-copy --type " + entry.mime];
                imgCopyProc.running = true;
            } else {
                copyProc.command = ["sh", "-c", "clipvault get " + entry.id + " | wl-copy &"];
                copyProc.running = true;
            }
            close();
        } else if (entry.type === "emoji") {
            copyProc.command = ["wl-copy", entry.emoji];
            copyProc.running = true;
            close();
        }
    }

    function open(prefix) {
        _animating = false;
        _opening = true;
        isOpen = true;

        Qt.callLater(() => {
            const v = _visual;
            if (!v) return;
            v.closeAnim.stop();
            v.stack.opacity = 1.0;
            v.stack.scale = 1.0;
            v.launcherInput.reset();
            if (prefix !== "")
                v.launcherInput.prefill(prefix);
            Qt.callLater(() => {
                const v2 = _visual;
                if (!v2) return;
                v2.launcherInput.forceInputFocus();
                v2.launcherList.resetToTop();
            });
        });
        openGuard.restart();
    }

    function close() {
        if (_animating)
            return;
        _animating = true;
        const v = _visual;
        if (v)
            v.closeAnim.start();
        else {
            isOpen = false;
            _animating = false;
        }
    }

    Timer {
        id: openGuard
        interval: 280
        onTriggered: root._opening = false
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            if (root.isOpen)
                root.close();
            else
                root.open("");
        }
        function openWith(prefix: string): void {
            const m = {
                ";": "clipboard",
                ":": "emoji"
            };
            if (root.isOpen && root.mode === (m[prefix] ?? "apps"))
                root.close();
            else
                root.open(prefix);
        }
    }

    HyprlandFocusGrab {
        id: focusGrab
        active: root.isOpen && _visual !== null
        windows: _visual ? [_visual.panel] : []
        onCleared: root.close()
    }

    Loader {
        id: visualLoader
        active: root.isOpen || root._animating
        asynchronous: false

        sourceComponent: Component {
            Item {
                id: loaderRoot

                property alias panel:       _panel
                property alias stack:       _stack
                property alias closeAnim:   _closeAnim
                property alias launcherInput: _launcherInput
                property alias launcherList:  _launcherList

                readonly property var activeWidget: {
                    switch (root.widgetType) {
                        case "math":      return mathWidget;
                        case "translate": return translateWidget;
                        case "color":     return colorWidget;
                        case "timestamp": return timestampWidget;
                        case "define":    return defineWidget;
                        case "whois":     return whoisWidget;
                        case "kaomoji":   return kaomojiWidget;
                        default:          return null;
                    }
                }

                readonly property bool widgetShown: activeWidget !== null && activeWidget.hasResult

                Variants {
                    model: Quickshell.screens
                    PanelWindow {
                        required property var modelData
                        screen: modelData
                        visible: root.isOpen || root._animating
                        color: "transparent"
                        WlrLayershell.layer: WlrLayer.Overlay
                        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                        WlrLayershell.namespace: "quickshell-launcher-overlay"
                        exclusionMode: ExclusionMode.Ignore
                        anchors {
                            top: true
                            bottom: true
                            left: true
                            right: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.close()
                        }
                    }
                }

                PanelWindow {
                    id: _panel
                    visible: root.isOpen
                    focusable: true
                    color: "transparent"
                    WlrLayershell.layer: WlrLayer.Overlay
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
                    WlrLayershell.namespace: "quickshell-launcher"
                    exclusionMode: ExclusionMode.Ignore
                    screen: Quickshell.screens[0]
                    anchors {
                        top: true
                        bottom: true
                        left: true
                        right: true
                    }

                    onVisibleChanged: {
                        if (visible && _launcherList)
                            Qt.callLater(() => _launcherList.resetToTop());
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.close()
                    }

                    Item {
                        id: _stack
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: Math.round(_panel.height * 0.3)

                        width: {
                            if (root.mode === "apps")
                                return root.widgetType === "kaomoji" ? 480 : 420;
                            if (root.mode === "emoji")
                                return 480;
                            return 520;
                        }

                        Behavior on width {
                            enabled: !root._opening
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }

                        height: listCard.y + listCard.height
                        transformOrigin: Item.Center

                        opacity: 1.0
                        scale: 1.0

                        ParallelAnimation {
                            id: _closeAnim
                            NumberAnimation {
                                target: _stack
                                property: "opacity"
                                to: 0.0
                                duration: 100
                                easing.type: Easing.InCubic
                            }
                            NumberAnimation {
                                target: _stack
                                property: "scale"
                                to: 0.80
                                duration: 200
                                easing.type: Easing.OutSine
                            }
                            onFinished: {
                                root._query = "";
                                _launcherList.resetToTop();

                                root.isOpen = false;
                                root._animating = false;
                                _stack.opacity = 1.0;
                                _stack.scale = 1.0;
                            }
                        }

                        readonly property int gap: 8

                        LauncherInput {
                            id: _launcherInput
                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                            }
                            mode: root.mode
                            widgetType: root.widgetType
                            onQueryChanged: q => {
                                _launcherList.resetToTop();
                                root._query = q;
                            }
                            onEscapePressed: root.close()
                            onUpPressed: _launcherList.moveUp()
                            onDownPressed: _launcherList.moveDown()
                            onEnterPressed: _launcherList.activateCurrent()
                            onTabPressed: _launcherList.moveDown()
                        }

                        ClippingRectangle {
                            id: widgetCard
                            anchors {
                                top: _launcherInput.bottom
                                topMargin: _stack.gap
                                left: parent.left
                                right: parent.right
                            }
                            radius: 20
                            color: Colors.md3.surface_container
                            clip: true

                            height: loaderRoot.widgetShown ? (widgetInner.implicitHeight + 32) : 0
                            opacity: loaderRoot.widgetShown ? 1.0 : 0.0
                            scale: loaderRoot.widgetShown ? 1.0 : 0.80
                            transformOrigin: Item.Top

                            border.width: 1
                            border.color: Colors.md3.outline_variant

                            Behavior on height {
                                enabled: !root._opening
                                NumberAnimation {
                                    duration: 240
                                    easing.type: Easing.OutCubic
                                }
                            }
                            Behavior on opacity {
                                enabled: !root._opening
                                NumberAnimation {
                                    duration: 180
                                    easing.type: Easing.OutCubic
                                }
                            }
                            Behavior on scale {
                                enabled: !root._opening
                                NumberAnimation {
                                    duration: 280
                                    easing.type: Easing.OutExpo
                                }
                            }

                            Item {
                                id: widgetInner
                                anchors {
                                    top: parent.top
                                    left: parent.left
                                    right: parent.right
                                    margins: 16
                                }
                                implicitHeight: mathWidget.visible ? mathWidget.implicitHeight : translateWidget.visible ? translateWidget.implicitHeight : colorWidget.visible ? colorWidget.implicitHeight : timestampWidget.visible ? timestampWidget.implicitHeight : defineWidget.visible ? defineWidget.implicitHeight : whoisWidget.visible ? whoisWidget.implicitHeight : kaomojiWidget.visible ? kaomojiWidget.implicitHeight : 0

                                MathWidget {
                                    id: mathWidget
                                    anchors {
                                        top: parent.top
                                        left: parent.left
                                        right: parent.right
                                    }
                                    visible: root.widgetType === "math"
                                    query: root.modeQuery
                                    onCopyResult: result => {
                                        copyProc.command = ["wl-copy", result];
                                        copyProc.running = true;
                                    }
                                    onSwapRequested: q => {
                                        _launcherInput.prefill(q);
                                    }
                                }

                                TranslateWidget {
                                    id: translateWidget
                                    anchors {
                                        top: parent.top
                                        left: parent.left
                                        right: parent.right
                                    }
                                    visible: root.widgetType === "translate"
                                    sourceText: root.modeQuery
                                    targetLang: root.translateTarget
                                    onCopyResult: text => {
                                        copyProc.command = ["wl-copy", text];
                                        copyProc.running = true;
                                    }
                                }

                                ColorWidget {
                                    id: colorWidget
                                    anchors {
                                        top: parent.top
                                        left: parent.left
                                        right: parent.right
                                    }
                                    visible: root.widgetType === "color"
                                    query: root._query.trim()
                                    onCopyResult: text => {
                                        copyProc.command = ["wl-copy", text];
                                        copyProc.running = true;
                                    }
                                }

                                TimestampWidget {
                                    id: timestampWidget
                                    anchors {
                                        top: parent.top
                                        left: parent.left
                                        right: parent.right
                                    }
                                    visible: root.widgetType === "timestamp"
                                    query: root._query.trim()
                                    onCopyResult: text => {
                                        copyProc.command = ["wl-copy", text];
                                        copyProc.running = true;
                                    }
                                }

                                DefineWidget {
                                    id: defineWidget
                                    anchors {
                                        top: parent.top
                                        left: parent.left
                                        right: parent.right
                                    }
                                    visible: root.widgetType === "define"
                                    word: root.widgetQuery
                                    onCopyResult: text => {
                                        copyProc.command = ["wl-copy", text];
                                        copyProc.running = true;
                                    }
                                }

                                WhoisWidget {
                                    id: whoisWidget
                                    anchors {
                                        top: parent.top
                                        left: parent.left
                                        right: parent.right
                                    }
                                    visible: root.widgetType === "whois"
                                    subject: root.widgetQuery
                                    onCopyResult: text => {
                                        copyProc.command = ["wl-copy", text];
                                        copyProc.running = true;
                                    }
                                }

                                KaomojiWidget {
                                    id: kaomojiWidget
                                    anchors {
                                        top: parent.top
                                        left: parent.left
                                        right: parent.right
                                    }
                                    visible: root.widgetType === "kaomoji"
                                    entries: root._kaomojiData
                                    query: root.widgetQuery
                                    onCopyResult: result => {
                                        copyProc.command = ["wl-copy", result];
                                        copyProc.running = true;
                                    }
                                    onCategoryRequested: tag => {
                                        _launcherInput.prefill("kao " + tag);
                                    }
                                }
                            }
                        }

                        ClippingRectangle {
                            id: listCard
                            anchors {
                                top: widgetCard.bottom
                                topMargin: _stack.gap
                                left: parent.left
                                right: parent.right
                            }
                            radius: 20
                            color: Colors.md3.surface_container
                            clip: true

                            border.width: 1
                            border.color: Colors.md3.outline_variant

                            readonly property int _max: root.mode === "clipboard" ? 600 : 400
                            height: _launcherList.count === 0 ? 220 : Math.min(_max, Math.max(60, _launcherList.listContentHeight + 40))

                            Behavior on height {
                                enabled: !root._opening
                                NumberAnimation {
                                    duration: 220
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Column {
                                anchors.fill: parent

                                LauncherHeader {
                                    id: listHeader
                                    width: parent.width
                                    mode: root.mode
                                    count: unifiedModel.values.length
                                    sortAlpha: root._sortAlpha
                                    onClearRequested: {
                                        clearProc.running = true;
                                        clearClipboardProc.running = true;
                                        root._clipEntries = [];
                                    }
                                    onSortToggled: {
                                        root._sortAlpha = !root._sortAlpha;
                                        _launcherList.resetToTop();
                                    }
                                    onSkinToneChanged: index => _launcherList.skinToneIndex = index
                                }

                                Process {
                                    id: clearProc
                                    command: ["clipvault", "clear"]
                                    running: false
                                    onRunningChanged: if (!running)
                                        clipLoader.running = true
                                }

                                Process {
                                    id: clearClipboardProc
                                    command: ["wl-copy", "--clear"]
                                    running: false
                                }

                                LauncherList {
                                    id: _launcherList
                                    width: parent.width
                                    height: parent.height - listHeader.height
                                    model: unifiedModel
                                    mode: root.mode
                                    onItemActivated: entry => root._handleActivation(entry)
                                    onActionActivated: root.close()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
