import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.style

Item {
    id: root

    property string word: ""
    signal copyResult(string text)

    property bool _loading: false
    property bool _error: false
    property string _errMsg: ""
    property string _word: ""
    property string _entryWord: ""
    property string _subtitle: ""
    property string _phonetic: ""
    property var _meanings: []
    property var _activeXhr: null
    property var _activeTlXhr: null
    property string _translation: ""
    readonly property bool hasResult: true
    readonly property int _maxContentHeight: 400
    readonly property bool _entrySwapped: root._entryWord.toLowerCase() !== root._word

    implicitHeight: col.implicitHeight

    onWordChanged: {
        if (word.trim() === "")
            return;
        _reset();
        _deb.restart();
    }

    Timer {
        id: _deb
        interval: 400
        onTriggered: root._fetch(root.word.trim().toLowerCase())
    }

    function _apiLang() {
        const code = (Config.language ?? "").split("_")[0].toLowerCase();
        return code === "" ? "en" : code;
    }

    function _reset() {
        if (_activeXhr) {
            _activeXhr.abort();
            _activeXhr = null;
        }
        if (_activeTlXhr) {
            _activeTlXhr.abort();
            _activeTlXhr = null;
        }
        _word = "";
        _entryWord = "";
        _subtitle = "";
        _phonetic = "";
        _meanings = [];
        _translation = "";
        _error = false;
        _errMsg = "";
    }

    function _fetch(w) {
        if (!w)
            return;

        _reset();
        _loading = true;

        if (_apiLang() === "en") {
            _lookup(w, w);
        } else {
            _translateInput(w);
        }
    }

    function _translateInput(w) {
        _google(_apiLang(), "en", w, function (sents) {
            let en = w;
            const t = (sents?.[0]?.trans ?? "").trim();
            if (t !== "")
                en = t.toLowerCase();
            _lookup(w, en);
        });
    }

    function _lookup(origW, enW) {
        _request(enW, function (data, status) {
            if (status !== 200 || data === null) {
                root._fail(origW, status === 200 ? "parse error" : "lookup failed (" + status + ")");
                return;
            }
            if ((data.entries ?? []).length === 0) {
                if (enW !== origW) {
                    _lookup(origW, origW);
                } else {
                    root._fail(origW);
                }
                return;
            }
            root._applyResult(origW, data);
            _finish(origW);
        });
    }

    function _finish(origW) {
        const userLang = _apiLang();
        if (userLang === "en") {
            root._loading = false;
            return;
        }
        _fetchLangEntry(origW, function (langData) {
            _translateOutput(function () {
                root._stitch(langData);
                root._loading = false;
            });
        });
    }

    function _fetchLangEntry(w, cb) {
        if (_activeXhr) {
            _activeXhr.abort();
            _activeXhr = null;
        }
        const xhr = new XMLHttpRequest();
        _activeXhr = xhr;
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (root._activeXhr !== xhr)
                return;
            root._activeXhr = null;
            let data = null;
            if (xhr.status === 200) {
                try {
                    data = JSON.parse(xhr.responseText);
                } catch (_) {}
            }
            cb(data);
        };
        xhr.open("GET", "https://freedictionaryapi.com/api/v1/entries/" + _apiLang() + "/" + encodeURIComponent(w));
        xhr.send();
    }

    function _stitch(langData) {
        const langEntries = langData?.entries ?? [];
        if (langEntries.length === 0)
            return;

        const langPhonetic = langEntries.map(e => (e.pronunciations ?? []).find(p => p.text)).find(p => p)?.text ?? "";
        if (langPhonetic !== "" && root._entrySwapped)
            root._subtitle = root._subtitle === "" ? langPhonetic : langPhonetic + " · " + root._subtitle;

        const available = langEntries.slice();
        root._meanings = root._meanings.map(m => {
            const i = available.findIndex(e => (e.partOfSpeech ?? "").toLowerCase() === (m.posSrc ?? "").toLowerCase());
            if (i === -1)
                return m;
            const le = available.splice(i, 1)[0];
            const syn = (le.senses ?? []).find(s => (s.synonyms ?? []).length > 0)?.synonyms ?? le.synonyms ?? [];
            const example = (le.senses ?? []).map(s => (s.examples ?? [])[0]).find(x => x) ?? m.example;
            return Object.assign({}, m, {
                synonyms: syn.length > 0 ? [...new Set(syn)].slice(0, 5) : m.synonyms,
                example: example
            });
        });
    }

    function _fail(w, msg) {
        root._loading = false;
        root._error = true;
        root._errMsg = msg ?? ("\"" + w + "\" not found");
    }

    function _request(w, onDone) {
        if (_activeXhr) {
            _activeXhr.abort();
            _activeXhr = null;
        }

        const xhr = new XMLHttpRequest();
        _activeXhr = xhr;

        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (root._activeXhr !== xhr)
                return;
            root._activeXhr = null;

            let data = null;
            if (xhr.status === 200) {
                try {
                    data = JSON.parse(xhr.responseText);
                } catch (_) {}
            }
            onDone(data, xhr.status);
        };
        const q = _apiLang() !== "en" ? "?translations=true" : "";
        xhr.open("GET", "https://freedictionaryapi.com/api/v1/entries/en/" + encodeURIComponent(w) + q);
        xhr.send();
    }

    function _google(sl, tl, text, cb) {
        if (_activeTlXhr) {
            _activeTlXhr.abort();
            _activeTlXhr = null;
        }
        const xhr = new XMLHttpRequest();
        _activeTlXhr = xhr;
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (root._activeTlXhr !== xhr)
                return;
            root._activeTlXhr = null;
            let sents = null;
            if (xhr.status === 200) {
                try {
                    sents = JSON.parse(xhr.responseText).sentences ?? null;
                } catch (_) {}
            }
            cb(sents);
        };
        const url = "https://clients5.google.com/translate_a/single?dj=1&dt=t&client=dict-chrome-ex&sl=" + sl + "&tl=" + encodeURIComponent(tl) + "&q=" + encodeURIComponent(text);
        xhr.open("GET", url);
        xhr.setRequestHeader("User-Agent", "Mozilla/5.0");
        xhr.send();
    }

    function _translateOutput(done) {
        const userLang = _apiLang();
        const lines = [];
        const fields = [];
        root._meanings.forEach((m, i) => {
            if (m.definition !== "") {
                lines.push((lines.length + 1) + ". " + m.definition);
                fields.push({
                        idx: i,
                        field: "definition"
                    });
            }
            if (m.partOfSpeech !== "") {
                lines.push((lines.length + 1) + ". " + m.partOfSpeech);
                fields.push({
                        idx: i,
                        field: "partOfSpeech"
                    });
            }
            if (m.example !== "") {
                lines.push((lines.length + 1) + ". " + m.example);
                fields.push({
                        idx: i,
                        field: "example"
                    });
            }
        });
        if (lines.length === 0) {
            done();
            return;
        }
        _google("en", userLang, lines.join("\n"), function (sents) {
            if (sents !== null)
                root._applyTranslations(sents, fields);
            done();
        });
    }

    function _applyResult(w, data) {
        root._word = w;
        root._entryWord = data.word ?? w;
        root._phonetic = (data.entries ?? []).map(e => (e.pronunciations ?? []).find(p => p.text)).find(p => p)?.text ?? "";
        root._meanings = (data.entries ?? []).slice(0, 3).map(e => {
                    const sense = (e.senses ?? []).find(s => (s.definition ?? "").trim()) ?? {};
                    const syn = (sense.synonyms?.length ? sense.synonyms : e.synonyms) ?? [];
                    return {
                        partOfSpeech: e.partOfSpeech ?? "",
                        posSrc: e.partOfSpeech ?? "",
                        definition: sense.definition ?? "",
                        example: sense.examples?.[0] ?? "",
                        synonyms: [...new Set(syn)].slice(0, 5)
                    };
                });

        root._subtitle = root._entrySwapped ? "" : root._phonetic;

        const userLang = _apiLang();
        if (userLang === "en" || root._entrySwapped) {
            root._translation = "";
        } else {
            root._translation = _userTranslation(data.entries, userLang);
        }
    }

    function _applyTranslations(sentences, fields) {
        const acc = fields.map(() => "");
        let cur = -1;
        for (const seg of sentences) {
            let t = seg.trans ?? "";
            const m = t.match(/^\s*(\d+)\s*[.)]\s*/);
            if (m !== null) {
                cur = parseInt(m[1], 10) - 1;
                t = t.slice(m[0].length);
            }
            if (cur >= 0 && cur < acc.length)
                acc[cur] += (acc[cur] === "" ? "" : " ") + t.trim();
        }

        let changed = false;
        const next = root._meanings.map(o => Object.assign({}, o));
        for (let k = 0; k < fields.length; k++) {
            const f = fields[k];
            const v = acc[k].trim();
            if (v !== "" && v !== next[f.idx][f.field]) {
                next[f.idx][f.field] = v;
                changed = true;
            }
        }
        if (changed)
            root._meanings = next;
    }

    function _userTranslation(entries, userLang) {
        for (const e of entries ?? []) {
            for (const s of e.senses ?? []) {
                const words = [...new Set((s.translations ?? [])
                            .filter(t => t.language?.code === userLang && t.word)
                            .map(t => t.word))];
                if (words.length > 0)
                    return words.slice(0, 3).join(", ");
            }
        }
        return "";
    }

    function _speak(text) {
        SoundService.speak(text, "en");
    }

    ColumnLayout {
        id: col
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        spacing: 10

        Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentCol.implicitHeight, root._maxContentHeight)
            contentHeight: contentCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: contentCol
                width: flick.width
                spacing: 10

                Text {
                    visible: !root._loading && !root._error && root._word === ""
                    Layout.fillWidth: true
                    text: Localization.t("defineWidget.type_a_word_to_look")
                    color: Colors.md3.on_surface_variant
                    font.pixelSize: 13
                    font.family: Config.fontFamily
                    opacity: 0.4
                }

                RowLayout {
                    visible: root._loading
                    Layout.fillWidth: true
                    spacing: 8

                    LoadingSpinner {
                        size: 14
                    }
                    Text {
                        text: Localization.t("defineWidget.looking_up").arg(root.word)
                        color: Colors.md3.on_surface_variant
                        font.pixelSize: 13
                        font.family: Config.fontFamily
                        opacity: 0.5
                    }
                }

                Text {
                    visible: root._error
                    Layout.fillWidth: true
                    text: root._errMsg
                    color: Colors.md3.error
                    font.pixelSize: 14
                    font.family: Config.fontFamily
                }

                ColumnLayout {
                    id: wordStack
                    visible: !root._loading && !root._error && root._word !== ""
                    Layout.fillWidth: true
                    spacing: 3

                    Text {
                        text: root._word
                        color: Colors.md3.on_surface
                        font.pixelSize: 30
                        font.weight: Font.Light
                        font.family: Config.fontFamily
                        lineHeight: 0.9
                    }

                    Text {
                        visible: root._subtitle !== ""
                        text: root._subtitle
                        color: Colors.md3.on_surface_variant
                        font.pixelSize: 13
                        font.family: Config.fontFamily
                        font.italic: true
                        opacity: 0.55
                        wrapMode: Text.Wrap
                    }

                    Text {
                        visible: root._translation !== ""
                        text: root._translation
                        color: Colors.md3.on_surface
                        font.pixelSize: 17
                        font.family: Config.fontFamily
                        wrapMode: Text.Wrap
                    }
                }

                Repeater {
                    model: root._meanings

                    delegate: ColumnLayout {
                        required property var modelData
                        required property int index
                        visible: !root._loading && !root._error && root._word !== ""
                        Layout.fillWidth: true
                        spacing: 4

                        Rectangle {
                            visible: index > 0
                            Layout.fillWidth: true
                            height: 1
                            color: Colors.md3.outline_variant
                            opacity: 0.35
                            Layout.topMargin: 2
                            Layout.bottomMargin: 2
                        }

                        Rectangle {
                            implicitWidth: posLbl.implicitWidth + 16
                            height: 22
                            radius: 11
                            color: Colors.md3.secondary_container

                            Text {
                                id: posLbl
                                anchors.centerIn: parent
                                text: modelData.partOfSpeech
                                color: Colors.md3.on_secondary_container
                                font.pixelSize: 11
                                font.family: Config.fontFamily
                                font.italic: true
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.definition
                            color: Colors.md3.on_surface
                            font.pixelSize: 14
                            font.family: Config.fontFamily
                            wrapMode: Text.Wrap
                            lineHeight: 1.4
                        }

                        Text {
                            visible: modelData.example !== ""
                            Layout.fillWidth: true
                            text: "\"" + modelData.example + "\""
                            color: Colors.md3.on_surface_variant
                            font.pixelSize: 12
                            font.family: Config.fontFamily
                            font.italic: true
                            opacity: 0.6
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }

                        Flow {
                            visible: modelData.synonyms.length > 0
                            Layout.fillWidth: true
                            spacing: 4

                            Repeater {
                                model: modelData.synonyms
                                delegate: Rectangle {
                                    required property string modelData
                                    implicitWidth: synLbl.implicitWidth + 12
                                    height: 20
                                    radius: 10
                                    color: Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)

                                    Text {
                                        id: synLbl
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: Colors.md3.on_surface_variant
                                        font.pixelSize: 11
                                        font.family: Config.fontFamily
                                        opacity: 0.7
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: root.copyResult(modelData)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Flow {
            visible: !root._loading && !root._error && root._word !== ""
            Layout.fillWidth: true
            spacing: 6

            PillBtn {
                label: Localization.t("defineWidget.copy_word")
                primary: true
                onTapped: root.copyResult(root._word)
            }
            PillBtn {
                label: Localization.t("defineWidget.copy_definition")
                visible: root._meanings.length > 0
                onTapped: root.copyResult(root._meanings[0]?.definition ?? "")
            }
            PillBtn {
                label: Localization.t("defineWidget.speak")
                onTapped: root._speak(root._entryWord)
            }
        }
    }
}
