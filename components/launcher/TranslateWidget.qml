import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.style

Item {
    id: root

    property string sourceText: ""
    property string targetLang: ""

    property string _translated: ""
    property string _detectedSrc: ""
    property bool _loading: false
    property bool _error: false

    implicitHeight: 70

    onSourceTextChanged: _debounce.restart()
    onTargetLangChanged: {
        if (targetLang !== "")
            _debounce.restart();
    }

    Timer {
        id: _debounce
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
        _detectedSrc = "";

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
                _translated = data.sentences?.map(s => s.trans).join("") ?? "";
                _detectedSrc = data.src ?? "";
            } catch (_) {
                _error = true;
            }
        };

        xhr.open("POST", "https://chopped-gurt.imadeliciousegg.workers.dev");
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.send(JSON.stringify({
            text: root.sourceText,
            dest: root.targetLang
        }));
    }

    Process {
        id: copyProc
        running: false
    }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: Colors.md3.secondary_container

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 14
                rightMargin: 14
            }
            spacing: 12

            Text {
                text: "󰗊"
                color: Colors.md3.on_secondary_container
                font.pixelSize: 18
                font.family: Config.fontFamily
                Layout.alignment: Qt.AlignVCenter
                opacity: 0.75
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 3

                Text {
                    text: root._loading ? "Translating..." : root._error ? "Translation failed" : root._translated !== "" ? root._translated : "..."
                    color: Colors.md3.on_secondary_container
                    font.pixelSize: 14
                    font.family: Config.fontFamily
                    font.bold: !root._loading && !root._error && root._translated !== ""
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    visible: !root._loading && !root._error
                    text: {
                        const src = root._detectedSrc !== "" ? root._detectedSrc : "?";
                        return src + " → " + root.targetLang;
                    }
                    color: Colors.md3.on_secondary_container
                    font.pixelSize: 10
                    font.family: Config.fontFamily
                    opacity: 0.6
                }
            }

            Text {
                text: "click to copy"
                color: Colors.md3.on_secondary_container
                font.pixelSize: 10
                font.family: Config.fontFamily
                Layout.alignment: Qt.AlignVCenter
                opacity: 0.55
                visible: root._translated !== ""
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            enabled: root._translated !== ""
            onClicked: {
                copyProc.command = ["wl-copy", root._translated];
                copyProc.running = true;
            }
        }
    }
}
