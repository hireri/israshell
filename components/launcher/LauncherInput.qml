import QtQuick
import QtQuick.Layouts
import qs.style

Item {
    id: root
    implicitHeight: 56

    property string mode: "apps"

    signal queryChanged(string q)
    signal escapePressed
    signal upPressed
    signal downPressed
    signal enterPressed
    signal tabPressed

    function reset() {
        input.text = "";
    }

    function prefill(t) {
        input.text = t;
        input.cursorPosition = t.length;
    }

    function forceInputFocus() {
        input.forceActiveFocus();
    }

    readonly property var _modeIcon: ({
            "apps": "󱗼",
            "shell": "󰘳",
            "clipboard": "󰅍",
            "emoji": "󰱨",
            "translate": "󰗊"
        })
    readonly property var _modePlaceholder: ({
            "apps": "search applications...",
            "shell": "run a command...",
            "clipboard": "search clipboard...",
            "emoji": "search emoji...",
            "translate": "type to translate..."
        })

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Colors.md3.surface_container_high
        border.color: input.activeFocus ? Colors.md3.primary : Colors.md3.outline_variant
        border.width: 1

        Behavior on border.color {
            ColorAnimation {
                duration: 150
            }
        }

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 16
                rightMargin: 16
            }
            spacing: 12

            Rectangle {
                implicitWidth: 32
                implicitHeight: 32
                radius: 8
                color: root.mode === "apps" ? "transparent" : Colors.md3.primary_container
                Layout.alignment: Qt.AlignVCenter

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: root._modeIcon[root.mode] ?? "󱗼"
                    color: root.mode === "apps" ? Colors.md3.on_surface_variant : Colors.md3.on_primary_container
                    font.pixelSize: 18
                    font.family: Config.fontFamily

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }
            }

            TextInput {
                id: input
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                color: Colors.md3.on_surface
                font.pixelSize: 15
                font.family: Config.fontFamily
                clip: true
                focus: true

                onTextChanged: root.queryChanged(text)

                Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    text: root._modePlaceholder[root.mode] ?? ""
                    color: Colors.md3.on_surface_variant
                    font: parent.font
                    visible: !parent.text
                    opacity: 0.45
                }

                Keys.onEscapePressed: root.escapePressed()
                Keys.onPressed: event => {
                    switch (event.key) {
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
