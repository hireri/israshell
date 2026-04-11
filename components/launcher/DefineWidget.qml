import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.style

Item {
    id: root

    property string word: ""
    signal copyResult(string text)

    property bool _loading: false
    property bool _error: false
    property string _errMsg: ""
    property string _word: ""
    property string _phonetic: ""
    property var _meanings: []
    property var _activeXhr: null

    implicitHeight: col.implicitHeight

    onWordChanged: {
        if (word.trim() === "")
            return;
        _deb.restart();
    }

    Timer {
        id: _deb
        interval: 400
        onTriggered: root._fetch(root.word.trim().toLowerCase())
    }

    function _fetch(w) {
        if (!w)
            return;

        if (_activeXhr) {
            _activeXhr.abort();
            _activeXhr = null;
        }

        _loading = true;
        _error = false;
        _errMsg = "";
        _word = "";
        _phonetic = "";
        _meanings = [];

        const xhr = new XMLHttpRequest();
        _activeXhr = xhr;

        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (root._activeXhr !== xhr)
                return;
            root._activeXhr = null;
            root._loading = false;

            if (xhr.status === 404) {
                root._error = true;
                root._errMsg = "\"" + w + "\" not found";
                return;
            }
            if (xhr.status !== 200) {
                root._error = true;
                root._errMsg = "lookup failed (" + xhr.status + ")";
                return;
            }
            try {
                const data = JSON.parse(xhr.responseText);
                const entry = data[0];
                root._word = entry.word ?? w;
                root._phonetic = entry.phonetic ?? (entry.phonetics?.find(p => p.text)?.text ?? "");
                root._meanings = (entry.meanings ?? []).slice(0, 3).map(m => ({
                            partOfSpeech: m.partOfSpeech ?? "",
                            definition: m.definitions?.[0]?.definition ?? "",
                            example: m.definitions?.[0]?.example ?? "",
                            synonyms: (m.synonyms ?? []).slice(0, 5)
                        }));
            } catch (_) {
                root._error = true;
                root._errMsg = "parse error";
            }
        };
        xhr.open("GET", "https://api.dictionaryapi.dev/api/v2/entries/en/" + encodeURIComponent(w));
        xhr.send();
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

    function _speak(text) {
        fallbackProc.running = false;
        fallbackProc.command = ["espeak-ng", text];

        speakProc.running = false;
        speakProc.command = ["sh", "-c", "gtts-cli " + JSON.stringify(text) + " -l en 2>/dev/null | mpv --no-terminal - 2>/dev/null"];
        speakProc.running = true;
    }

    component PillBtn: Rectangle {
        id: pb
        property string label: ""
        property bool primary: false
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
        spacing: 10

        RowLayout {
            visible: root._loading
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                width: 6
                height: 6
                radius: 3
                color: Colors.md3.primary
                SequentialAnimation on opacity {
                    running: root._loading
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: 0.2
                        duration: 500
                    }
                    NumberAnimation {
                        to: 0.9
                        duration: 500
                    }
                }
            }
            Text {
                text: "looking up \"" + root.word + "\"..."
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

        Item {
            visible: !root._loading && !root._error && root._word !== ""
            Layout.fillWidth: true
            implicitHeight: wordStack.implicitHeight

            ColumnLayout {
                id: wordStack
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
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
                    visible: root._phonetic !== ""
                    text: root._phonetic
                    color: Colors.md3.on_surface_variant
                    font.pixelSize: 13
                    font.family: Config.fontFamily
                    font.italic: true
                    opacity: 0.55
                }
            }
        }

        Repeater {
            model: root._meanings

            delegate: ColumnLayout {
                required property var modelData
                required property int index
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
                    border.width: 1
                    border.color: Colors.md3.outline_variant

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
                    maximumLineCount: 4
                    elide: Text.ElideRight
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
                            color: Colors.md3.surface_container_high
                            border.width: 1
                            border.color: Colors.md3.outline_variant

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
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.copyResult(modelData)
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
            topPadding: 2

            PillBtn {
                label: "󰆏  copy word"
                primary: true
                onTapped: root.copyResult(root._word)
            }
            PillBtn {
                label: "󰆏  copy definition"
                visible: root._meanings.length > 0
                onTapped: root.copyResult(root._meanings[0]?.definition ?? "")
            }
            PillBtn {
                label: "󰕾  speak"
                onTapped: root._speak(root._word)
            }
        }
    }
}
