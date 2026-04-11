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

    property string _query: ""

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

        if (/\d/.test(q) || /[+\-*\/^%()]/.test(q))
            return "math";
        if (/\b(?:sqrt|sin|cos|tan|log|pi|to|in|km|mile|kg|lb|oz|inch|foot|feet|meter|cm|mm|liter|gallon|celsius|fahrenheit)\b/i.test(q))
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
        return q;
    }

    readonly property bool _widgetShown: {
        if (widgetType === "math")
            return mathWidget.hasResult;
        if (widgetType === "translate")
            return modeQuery.trim() !== "";
        if (widgetType === "color")
            return colorWidget.hasResult;
        if (widgetType === "timestamp")
            return timestampWidget._mode !== "" && (timestampWidget._unixDate !== null || timestampWidget._daysResult !== null);
        if (widgetType === "define")
            return widgetQuery.trim() !== "";
        if (widgetType === "whois")
            return widgetQuery.trim() !== "";
        return false;
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

    property var _emojiData: []
    property bool _emojiLoaded: false

    Process {
        id: emojiLoader
        command: ["sh", "-c", ["dir=\"$HOME/.config/quickshell/components/emojis\"", "files=\"emojis_smileys_emotion.csv emojis_people_body.csv emojis_activities.csv emojis_animals_nature.csv emojis_food_drink.csv emojis_objects.csv emojis_travel_places.csv emojis_symbols.csv emojis_flags.csv\"", "for f in $files; do cat \"$dir/$f\" 2>/dev/null; done"].join("\n")]
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

    Component.onCompleted: emojiLoader.running = true

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
        launcherList.resetToTop();
        if (mode === "clipboard") {
            _clipEntries = [];
            clipLoader.running = false;
            clipLoader.running = true;
        }
    }

    ScriptModel {
        id: unifiedModel
        objectProp: "uid"
        values: {
            const q = root.modeQuery.trim().toLowerCase();
            const mode = root.mode;

            if (mode === "apps" || mode === "translate") {
                const all = DesktopEntries.applications.values.slice();
                const mapped = arr => arr.map(d => ({
                                type: "app",
                                uid: "app_" + d.id,
                                entry: d
                            }));
                if (q === "")
                    return mapped(all.sort((a, b) => a.name.localeCompare(b.name)));
                return mapped(all.filter(d => d.name?.toLowerCase().includes(q) || d.genericName?.toLowerCase().includes(q) || d.keywords?.some(k => k.toLowerCase().includes(q)) || d.categories?.some(c => c.toLowerCase().includes(q))).sort((a, b) => {
                    const an = a.name.toLowerCase(), bn = b.name.toLowerCase();
                    const aS = an.startsWith(q), bS = bn.startsWith(q);
                    return aS === bS ? an.localeCompare(bn) : aS ? -1 : 1;
                }));
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
                if (q === "")
                    return root._emojiData.slice(0, 150).map(e => Object.assign({
                            type: "emoji",
                            uid: "emoji_" + e.emoji
                        }, e));
                const words = q.split(/\s+/).filter(Boolean);
                return root._emojiData.filter(e => {
                    const s = (e.name + " " + e.keywords.join(" ")).toLowerCase();
                    return words.every(w => s.includes(w));
                }).slice(0, 100).map(e => Object.assign({
                        type: "emoji",
                        uid: "emoji_" + e.emoji
                    }, e));
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
            Quickshell.execDetached({
                command: e.command,
                workingDirectory: cwd,
                environment: {
                    FASTFETCH_SKIP: null
                }
            });
            close();
        } else if (entry.type === "clip") {
            if (entry.isImage) {
                imgCopyProc.command = ["sh", "-c", "clipvault get " + entry.id + " | wl-copy --type " + entry.mime];
                imgCopyProc.running = true;
            } else {
                copyProc.command = ["wl-copy", entry.content];
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
        _opening = true;
        isOpen = true;
        launcherInput.reset();
        if (prefix !== "")
            launcherInput.prefill(prefix);
        Qt.callLater(() => {
            launcherInput.forceInputFocus();
            launcherList.resetToTop();
        });
        openGuard.restart();
    }

    function close() {
        isOpen = false;
        _query = "";
        launcherList.resetToTop();
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

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.isOpen && modelData !== panel.screen
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
        id: panel
        visible: root.isOpen
        focusable: true
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell-launcher"
        exclusionMode: ExclusionMode.Ignore
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        onVisibleChanged: {
            if (visible)
                Qt.callLater(() => launcherList.resetToTop());
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }

        Item {
            id: stack
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(panel.height * 0.3)
            width: 520
            height: listCard.y + listCard.height

            opacity: root.isOpen ? 1.0 : 0.0
            scale: root.isOpen ? 1.0 : 0.80
            transformOrigin: Item.Center
            Behavior on opacity {
                enabled: !root._opening
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on scale {
                enabled: !root._opening
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutExpo
                }
            }

            readonly property int gap: 8

            LauncherInput {
                id: launcherInput
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                mode: root.mode
                widgetType: root.widgetType
                onQueryChanged: q => {
                    root._query = q;
                }
                onEscapePressed: root.close()
                onUpPressed: launcherList.moveUp()
                onDownPressed: launcherList.moveDown()
                onEnterPressed: launcherList.activateCurrent()
                onTabPressed: launcherList.moveDown()
            }

            ClippingRectangle {
                id: widgetCard
                anchors {
                    top: launcherInput.bottom
                    topMargin: stack.gap
                    left: parent.left
                    right: parent.right
                }
                radius: 20
                color: Colors.md3.surface_container
                clip: true

                height: root._widgetShown ? (widgetInner.implicitHeight + 28) : 0
                opacity: root._widgetShown ? 1.0 : 0.0
                scale: root._widgetShown ? 1.0 : 0.80
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
                    implicitHeight: mathWidget.visible ? mathWidget.implicitHeight : translateWidget.visible ? translateWidget.implicitHeight : colorWidget.visible ? colorWidget.implicitHeight : timestampWidget.visible ? timestampWidget.implicitHeight : defineWidget.visible ? defineWidget.implicitHeight : whoisWidget.visible ? whoisWidget.implicitHeight : 0

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
                            launcherInput.prefill(q);
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
                }
            }

            ClippingRectangle {
                id: listCard
                anchors {
                    top: widgetCard.bottom
                    topMargin: stack.gap
                    left: parent.left
                    right: parent.right
                }
                radius: 20
                color: Colors.md3.surface_container
                clip: true

                border.width: 1
                border.color: Colors.md3.outline_variant

                readonly property int _min: 150
                readonly property int _max: 400
                height: Math.max(_min, Math.min(_max, launcherList.listContentHeight + 12))
                Behavior on height {
                    enabled: !root._opening
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }

                LauncherList {
                    id: launcherList
                    anchors.fill: parent
                    model: unifiedModel
                    mode: root.mode
                    onItemActivated: entry => root._handleActivation(entry)
                    onActionActivated: root.close()
                }
            }
        }
    }
}
