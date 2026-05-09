import QtQuick
import QtQuick.Layouts
import qs.style

Item {
    id: root
    implicitHeight: 58

    property string mode: "apps"
    property string widgetType: ""

    signal queryChanged(string q)
    signal escapePressed
    signal upPressed
    signal downPressed
    signal enterPressed
    signal tabPressed

    property string _prefix: ""
    readonly property var _prefixTriggers: [";", ":"]
    function _isPrefix(c) {
        return _prefixTriggers.indexOf(c) !== -1;
    }

    function reset() {
        _prefix = "";
        input.text = "";
    }

    function prefill(t) {
        if (t.length >= 1 && _isPrefix(t[0])) {
            _prefix = t[0];
            input.text = t.slice(1);
        } else {
            _prefix = "";
            input.text = t;
        }
        input.cursorPosition = input.text.length;
        queryChanged(_prefix + input.text);
    }

    function forceInputFocus() {
        input.forceActiveFocus();
    }

    readonly property var _icon: ({
            "apps": "󰍉",
            "clipboard": "󰅍",
            "emoji": "󰱨",
            "translate": "󰗊",
            "math": "󰪚",
            "color": "󰏘"
        })

    readonly property string _activeIcon: {
        if (mode === "apps" && (widgetType === "math" || widgetType === "color"))
            return _icon[widgetType];
        return _icon[mode] ?? "󱗼";
    }

    readonly property var _placeholder: ({
            "apps": "Search applications...",
            "clipboard": "Search clipboard...",
            "emoji": "Search emoji...",
            "translate": "Type to translate..."
        })

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Colors.md3.surface_container_high
        border.width: 1
        border.color: Colors.md3.outline_variant

        Rectangle {
            id: iconCircle
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                leftMargin: 8
            }
            width: 42
            height: 42
            radius: 21
            color: Colors.md3.primary

            Text {
                anchors.centerIn: parent
                text: root._activeIcon
                color: Colors.md3.on_primary
                font.pixelSize: 26
                font.family: Config.fontFamily
            }
        }

        Rectangle {
            id: innerPill
            anchors {
                left: iconCircle.right
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: 12
                rightMargin: 7
            }
            height: 42
            radius: height / 2
            color: Colors.md3.surface_container_low

            RowLayout {
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 14
                    rightMargin: 14
                }
                spacing: 6

                Rectangle {
                    visible: root._prefix !== ""
                    implicitWidth: pfxLbl.implicitWidth + 14
                    implicitHeight: 22
                    radius: 11
                    color: Colors.md3.primary_container
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        id: pfxLbl
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -1
                        text: root._prefix
                        color: Colors.md3.primary
                        font.pixelSize: 13
                        font.family: Config.fontFamily
                        font.weight: Font.Medium
                    }
                }

                TextInput {
                    id: input
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    color: Colors.md3.on_surface
                    font.pixelSize: 14
                    font.family: Config.fontFamily
                    clip: true
                    focus: true

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: root._placeholder[root.mode] ?? ""
                        color: Colors.md3.on_surface_variant
                        font: parent.font
                        visible: input.text === ""
                        opacity: 0.45
                    }

                    onTextChanged: {
                        const t = text;
                        if (root._prefix === "" && t.length === 1 && root._isPrefix(t[0])) {
                            root._prefix = t[0];
                            input.text = "";
                            return;
                        }
                        root.queryChanged(root._prefix + t);
                    }

                    Keys.onEscapePressed: root.escapePressed()
                    Keys.onPressed: event => {
                        switch (event.key) {
                        case Qt.Key_Backspace:
                            if (input.text === "" && root._prefix !== "") {
                                root._prefix = "";
                                root.queryChanged("");
                                event.accepted = true;
                            }
                            break;
                        case Qt.Key_Up:
                            event.accepted = true;
                            root.upPressed();
                            break;
                        case Qt.Key_Down:
                            event.accepted = true;
                            root.downPressed();
                            break;
                        case Qt.Key_Return:
                        case Qt.Key_Enter:
                            event.accepted = true;
                            root.enterPressed();
                            break;
                        case Qt.Key_Tab:
                            event.accepted = true;
                            root.tabPressed();
                            break;
                        }
                    }
                }
            }
        }
    }
}
