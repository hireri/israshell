import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.style

Item {
    id: root

    property string sourceText: ""
    property string targetLang: ""

    property string _translated: ""
    property string _romanized: ""
    property string _detectedSrc: ""
    property bool _loading: false
    property bool _error: false

    signal copyResult(string text)

    implicitHeight: col.implicitHeight

    onSourceTextChanged: {
        _translated = "";
        _romanized = "";
        _detectedSrc = "";
        _error = false;
        _deb.restart();
    }
    onTargetLangChanged: {
        if (targetLang !== "")
            _deb.restart();
    }

    Timer {
        id: _deb
        interval: 500
        onTriggered: {
            if (root.sourceText.trim() === "" || root.targetLang === "")
                return;
            root._fetch();
        }
    }

    function _fetch() {
        _loading = true;
        _error = false;
        _translated = "";
        _romanized = "";
        _detectedSrc = "";

        const url = "https://clients5.google.com/translate_a/single?dj=1&dt=sp&dt=t&dt=ld&dt=bd&client=dict-chrome-ex&sl=auto&tl=" + encodeURIComponent(root.targetLang) + "&q=" + encodeURIComponent(root.sourceText);

        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            _loading = false;
            if (xhr.status !== 200) {
                _error = true;
                return;
            }
            try {
                const data = JSON.parse(xhr.responseText);
                _translated = data.sentences?.map(s => s.trans ?? "").join("") ?? "";
                _detectedSrc = data.src ?? "";

                const rom = data.sentences?.map(s => (s.translit ?? s.src_translit ?? "")).join("").trim() ?? "";
                _romanized = rom;

                const needsRoman = /^(ja|zh|ko|ar)$/.test(root.targetLang) || /^(ja|zh|ko|ar)$/.test(_detectedSrc);
                if (_romanized === "" && needsRoman && _translated !== "") {
                    kanaProc.running = false;
                    kanaProc.command = ["sh", "-c", "printf '%s' " + JSON.stringify(_translated) + " | iconv -f utf8 -t eucjp | kakasi -i euc -w | kakasi -i euc -Ha -Ka -Ja -Ea -ka 2>/dev/null"];
                    kanaProc.running = true;
                }
            } catch (_) {
                _error = true;
            }
        };
        xhr.open("GET", url);
        xhr.setRequestHeader("User-Agent", "Mozilla/5.0");
        xhr.send();
    }

    function _speak(text, lang) {
        fallbackProc.running = false;
        fallbackProc.command = ["espeak-ng", "-v", lang, "--", text];

        speakProc.running = false;
        speakProc.command = ["bash", "-c", "TMP=$(mktemp /tmp/qs-trans-XXXXXX.mp3); " + "gtts-cli " + JSON.stringify(text) + " -l " + lang + " -o \"$TMP\" 2>/dev/null && " + "mpv --no-terminal --no-config --keep-open=no --force-window=no \"$TMP\" 2>/dev/null; " + "rm -f \"$TMP\""];
        speakProc.running = true;
    }

    Process {
        id: kanaProc
        stdout: StdioCollector {
            onStreamFinished: {
                const r = this.text.trim();
                if (r !== "" && r !== root._translated)
                    root._romanized = r;
            }
        }
    }

    Process {
        id: speakProc
        running: false
        onRunningChanged: {
            if (!running && exitCode !== 0)
                fallbackProc.running = true;
        }
    }

    Process {
        id: fallbackProc
        running: false
    }
    Process {
        id: browserProc
        running: false
    }

    component PillBtn: Rectangle {
        id: pb
        property string label: ""
        property bool primary: true
        signal tapped

        implicitWidth: lbl.implicitWidth + 22
        implicitHeight: 30
        radius: height / 2
        color: ma.containsMouse ? (primary ? Colors.md3.primary : Colors.md3.secondary_container) : (primary ? Colors.md3.primary_container : Colors.md3.surface_container_high)
        Behavior on color {
            ColorAnimation {
                duration: 90
            }
        }

        Text {
            id: lbl
            anchors.centerIn: parent
            text: pb.label
            color: ma.containsMouse ? (pb.primary ? Colors.md3.on_primary : Colors.md3.on_secondary_container) : (pb.primary ? Colors.md3.on_primary_container : Colors.md3.on_surface_variant)
            font.pixelSize: 12
            font.family: Config.fontFamily
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pb.tapped()
        }
    }

    ColumnLayout {
        id: col
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Rectangle {
                implicitWidth: srcLbl.implicitWidth + 16
                height: 24
                radius: 12
                color: Colors.md3.surface_container_high

                Text {
                    id: srcLbl
                    anchors.centerIn: parent
                    text: root._detectedSrc !== "" ? root._detectedSrc : "auto"
                    color: Colors.md3.on_surface_variant
                    font.pixelSize: 11
                    font.family: Config.fontFamily
                    font.weight: Font.Medium
                }
            }

            Text {
                text: "→"
                color: Colors.md3.on_surface_variant
                opacity: 0.35
                font.pixelSize: 13
            }

            Rectangle {
                implicitWidth: tgtLbl.implicitWidth + 16
                height: 24
                radius: 12
                color: Colors.md3.primary_container

                Text {
                    id: tgtLbl
                    anchors.centerIn: parent
                    text: root.targetLang
                    color: Colors.md3.primary
                    font.pixelSize: 11
                    font.family: Config.fontFamily
                    font.weight: Font.Medium
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                visible: root._loading
                width: 6
                height: 6
                radius: 3
                color: Colors.md3.primary
                opacity: 0.7
                SequentialAnimation on opacity {
                    running: root._loading
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: 0.2
                        duration: 500
                    }
                    NumberAnimation {
                        to: 0.8
                        duration: 500
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: root._error ? "Translation failed" : root._translated !== "" ? root._translated : "..."
            color: root._error ? Colors.md3.error : Colors.md3.on_surface
            font.pixelSize: 26
            font.weight: Font.Light
            font.family: Config.fontFamily
            wrapMode: Text.Wrap
            lineHeight: 1.2
            opacity: root._translated === "" && !root._error ? 0.35 : 1.0
            Behavior on opacity {
                NumberAnimation {
                    duration: 120
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: root._romanized !== ""
            text: root._romanized
            color: Colors.md3.on_surface_variant
            font.pixelSize: 13
            font.family: Config.fontFamily
            font.italic: true
            opacity: 0.55
            wrapMode: Text.Wrap
        }

        Flow {
            Layout.fillWidth: true
            spacing: 6

            PillBtn {
                label: "󰆏  copy"
                primary: true
                visible: root._translated !== ""
                onTapped: root.copyResult(root._translated)
            }
            PillBtn {
                label: "󰆏  copy romanized"
                primary: true
                visible: root._romanized !== ""
                onTapped: root.copyResult(root._romanized)
            }
            PillBtn {
                label: "󰕾  speak"
                primary: false
                visible: root._translated !== ""
                onTapped: root._speak(root._translated, root.targetLang)
            }
            PillBtn {
                label: "󰖟  open in browser"
                primary: false
                visible: root._translated !== ""
                onTapped: {
                    const url = "https://translate.google.com/?sl=auto&tl=" + root.targetLang + "&text=" + encodeURIComponent(root.sourceText) + "&op=translate";
                    browserProc.command = ["xdg-open", url];
                    browserProc.running = true;
                }
            }
        }
    }
}
