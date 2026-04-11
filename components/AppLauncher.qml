import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.style
import qs.components.launcher

Scope {
    id: root

    property bool isOpen: false

    readonly property string mode: {
        const q = _query;
        if (q.startsWith(">"))
            return "shell";
        if (q.startsWith(";"))
            return "clipboard";
        if (q.startsWith(":"))
            return "emoji";
        if (_detectLang(q) !== "")
            return "translate";
        return "apps";
    }

    readonly property string modeQuery: {
        if (mode === "shell" || mode === "clipboard" || mode === "emoji")
            return _query.slice(1).replace(/^\s+/, "");
        if (mode === "translate") {
            const sp = _query.indexOf(" ");
            return sp === -1 ? "" : _query.slice(sp + 1);
        }
        return _query;
    }

    readonly property string translateTarget: _detectLang(_query)

    property string _query: ""

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
        return _langMap[parts[0].toLowerCase()] ?? "";
    }

    function open(prefix) {
        isOpen = true;
        launcherInput.reset();
        if (prefix !== "")
            launcherInput.prefill(prefix);
        Qt.callLater(() => launcherInput.forceInputFocus());
    }

    function close() {
        isOpen = false;
        _query = "";
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
            const modeForPrefix = {
                ";": "clipboard",
                ":": "emoji",
                ">": "shell"
            };
            if (root.isOpen && root.mode === (modeForPrefix[prefix] ?? "apps")) {
                root.close();
            } else {
                root.open(prefix);
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

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }

        Rectangle {
            id: launcherBox
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Math.round(panel.height * 0.14)
            width: 660
            height: mainColumn.implicitHeight + 32
            radius: 18
            color: Colors.md3.surface_container
            border.color: Colors.md3.outline_variant
            border.width: 1

            opacity: root.isOpen ? 1.0 : 0.0
            scale: root.isOpen ? 1.0 : 0.85

            Behavior on opacity {
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: 320
                    easing.type: Easing.OutExpo
                }
            }

            ColumnLayout {
                id: mainColumn
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 16
                }
                spacing: 10

                LauncherInput {
                    id: launcherInput
                    Layout.fillWidth: true
                    mode: root.mode
                    onQueryChanged: q => {
                        root._query = q;
                    }
                    onEscapePressed: root.close()
                    onUpPressed: _activeList().moveUp()
                    onDownPressed: _activeList().moveDown()
                    onEnterPressed: _activeList().activateCurrent()
                    onTabPressed: _activeList().moveDown()
                }

                MathWidget {
                    id: mathWidget
                    Layout.fillWidth: true
                    visible: root.mode === "apps" && hasResult
                    query: root.modeQuery
                }

                TranslateWidget {
                    id: translateWidget
                    Layout.fillWidth: true
                    visible: root.mode === "translate" && root.modeQuery.trim() !== ""
                    sourceText: root.modeQuery
                    targetLang: root.translateTarget
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: 400

                    AppList {
                        id: appList
                        anchors.fill: parent
                        visible: root.mode === "apps" || root.mode === "translate"
                        query: root.modeQuery
                        onLaunched: root.close()
                    }

                    Item {
                        anchors.fill: parent
                        visible: root.mode === "shell"
                        Text {
                            anchors.centerIn: parent
                            text: "Shell is uh. coming soon."
                            color: Colors.md3.on_surface_variant
                            font.pixelSize: 13
                            font.family: Config.fontFamily
                            opacity: 0.5
                        }
                    }

                    ClipboardList {
                        id: clipList
                        anchors.fill: parent
                        visible: root.mode === "clipboard"
                        active: root.mode === "clipboard" && root.isOpen
                        query: root.modeQuery
                        onSelected: root.close()
                    }

                    EmojiList {
                        id: emojiList
                        anchors.fill: parent
                        visible: root.mode === "emoji"
                        query: root.modeQuery
                        onSelected: root.close()
                    }
                }

                Row {
                    Layout.fillWidth: true
                    spacing: 14

                    Repeater {
                        model: [
                            {
                                key: "↑↓",
                                hint: "navigate"
                            },
                            {
                                key: "⏎",
                                hint: "select"
                            },
                            {
                                key: "esc",
                                hint: "close"
                            }
                        ]
                        Row {
                            spacing: 5
                            Rectangle {
                                width: kl.implicitWidth + 10
                                height: 20
                                radius: 4
                                color: Colors.md3.surface_container_high
                                Text {
                                    id: kl
                                    anchors.centerIn: parent
                                    text: modelData.key
                                    color: Colors.md3.on_surface_variant
                                    font.pixelSize: 10
                                    font.family: Config.fontFamily
                                }
                            }
                            Text {
                                text: modelData.hint
                                color: Colors.md3.on_surface_variant
                                font.pixelSize: 10
                                font.family: Config.fontFamily
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }

                Item {
                    implicitHeight: 4
                }
            }
        }
    }

    function _activeList() {
        if (mode === "clipboard")
            return clipList;
        if (mode === "emoji")
            return emojiList;
        return appList;
    }
}
