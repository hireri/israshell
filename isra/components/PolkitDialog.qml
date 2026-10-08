pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Polkit
import qs.style
import qs.services
import qs.icons

Scope {
    id: root

    readonly property var flow: agent.flow

    property bool alive: false
    property real shown: 0
    Behavior on shown {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }
    property var targetScreen: null
    property string draft: ""
    property bool wrong: false
    signal failed

    readonly property bool busy: !(root.flow?.isResponseRequired ?? false)

    property string message: ""
    property string supplementary: ""
    property bool supplementaryIsError: false
    readonly property bool lockedOut: /left to unlock/i.test(root.supplementary)
    property var idNames: []
    property int selIdx: 0

    function _idNames() {
        const out = [];
        for (const i of root.flow.identities)
            out.push(i.displayName);
        return out;
    }

    function _selIdx() {
        const l = root.flow.identities;
        for (let i = 0; i < l.length; i++)
            if (l[i] === root.flow.selectedIdentity)
                return i;
        return 0;
    }

    function submit(text) {
        if (!busy && text.length > 0)
            root.flow.submit(text);
    }

    Binding { target: root; property: "message"; value: root.flow?.message ?? ""; when: root.flow !== null; restoreMode: Binding.RestoreNone }
    Binding { target: root; property: "supplementary"; value: root.flow?.supplementaryMessage ?? ""; when: root.flow !== null; restoreMode: Binding.RestoreNone }
    Binding { target: root; property: "supplementaryIsError"; value: root.flow?.supplementaryIsError ?? false; when: root.flow !== null; restoreMode: Binding.RestoreNone }
    Binding { target: root; property: "idNames"; value: root.flow ? root._idNames() : []; when: root.flow !== null; restoreMode: Binding.RestoreNone }
    Binding { target: root; property: "selIdx"; value: root.flow ? root._selIdx() : 0; when: root.flow !== null; restoreMode: Binding.RestoreNone }

    Connections {
        target: agent
        function onFlowChanged() {
            root.draft = "";
            root.wrong = false;
        }
    }

    Connections {
        target: root.flow
        function onAuthenticationFailed() {
            root.draft = "";
            root.wrong = true;
            root.failed();
        }
    }

    function _focusedScreen() {
        return Quickshell.screens.find(s => s.name === CompositorService.focusedMonitor.name) ?? Quickshell.screens[0];
    }

    Timer {
        interval: 100
        repeat: true
        running: root.alive && agent.isActive
        onTriggered: if (!cursor.running)
            cursor.running = true
    }

    Process {
        id: cursor
        command: ["hyprctl", "cursorpos", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let p;
                try {
                    p = JSON.parse(text);
                } catch (e) {
                    return;
                }
                const next = Quickshell.screens.find(s => p.x >= s.x && p.x < s.x + s.width && p.y >= s.y && p.y < s.y + s.height);
                if (!next || next === root.targetScreen)
                    return;
                root.targetScreen = next;
            }
        }
    }

    Timer {
        id: closeTimer
        interval: 200
        onTriggered: if (!agent.isActive)
            root.alive = false
    }

    PolkitAgent {
        id: agent

        onIsActiveChanged: {
            if (isActive) {
                closeTimer.stop();
                Qt.callLater(() => root.shown = 1);
                if (!root.alive) {
                    root.targetScreen = root._focusedScreen();
                    root.draft = "";
                    root.wrong = false;
                }
                root.alive = true;
                PanelService.closeAll(true);
            } else {
                root.shown = 0;
                closeTimer.restart();
            }
        }
    }

    LazyLoader {
        active: root.alive

        Variants {
            model: Quickshell.screens

            PanelWindow {
                id: w
                required property var modelData
                readonly property bool active: modelData === root.targetScreen
                property real presence: active ? 1 : 0
                Behavior on presence {
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }

                screen: modelData
                WlrLayershell.namespace: "quickshell:polkit"
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
                exclusionMode: ExclusionMode.Ignore
                color: "transparent"
                anchors {
                    top: true
                    left: true
                    right: true
                    bottom: true
                }

                onActiveChanged: if (active)
                    Qt.callLater(() => field.focusInput())

                readonly property bool blurEnabled: root.shown * presence > 0.5 && Config.blurAllowed(visible)
                BackgroundEffect.blurRegion: blurEnabled ? cardBlur : null

                Region {
                    id: cardBlur
                    readonly property real k: card.scale
                    x: card.x + card.width * (1 - k) / 2
                    y: card.y + card.height * (1 - k) / 2
                    width: card.width * k
                    height: card.height * k
                    radius: card.radius * k
                }

                Rectangle {
                    anchors.fill: parent
                    color: "#8C000000"
                    opacity: root.shown
                }

                Item {
                    id: scope
                    anchors.fill: parent
                    focus: true

                    Shortcut {
                        sequence: "Escape"
                        onActivated: root.flow?.cancelAuthenticationRequest()
                    }

                    readonly property real shown: root.shown

                    Connections {
                        target: root
                        function onFailed() {
                            field.shake();
                        }
                    }

                    Connections {
                        target: root.flow
                        function onIsResponseRequiredChanged() {
                            if (root.flow.isResponseRequired && w.active)
                                field.focusInput();
                        }
                    }

                    Binding {
                        target: field
                        property: "text"
                        value: root.draft
                    }

                    Rectangle {
                        id: card
                        anchors.centerIn: parent
                        width: 440
                        height: content.implicitHeight + 48
                        Behavior on height {
                            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                        }
                        radius: 28
                        color: Config.dim(Colors.md3.surface_container_high)
                        border.width: 1
                        border.color: Colors.md3.outline_variant
                        opacity: scope.shown * w.presence
                        scale: 0.96 + 0.04 * scope.shown * w.presence

                        ColumnLayout {
                            id: content
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: 24
                            }
                            spacing: 0

                            Item {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.bottomMargin: 14
                                implicitWidth: 64
                                implicitHeight: 64

                                MaterialShape {
                                    name: "cookie12"
                                    shapeSize: 64
                                    immediate: true
                                    color: root.wrong ? Colors.md3.error_container : Colors.md3.primary_container
                                    Behavior on color {
                                        ColorAnimation { duration: 200 }
                                    }
                                }

                                MaterialIcon {
                                    transitionType: "none"
                                    anchors.centerIn: parent
                                    name: root.wrong ? "error" : "lock"
                                    filled: true
                                    iconSize: 30
                                    color: root.wrong ? Colors.md3.on_error_container : Colors.md3.on_primary_container
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: Localization.t("polkit.title")
                                font.family: Config.fontFamily
                                font.pixelSize: 24
                                color: Colors.md3.on_surface
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.topMargin: 8
                                Layout.bottomMargin: 16
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.Wrap
                                text: root.message
                                font.family: Config.fontFamily
                                font.pixelSize: 14
                                color: Colors.md3.on_surface_variant
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.bottomMargin: 12
                                spacing: 6
                                visible: root.idNames.length > 1

                                Text {
                                    text: Localization.t("polkit.authenticate_as")
                                    font.family: Config.fontFamily
                                    font.pixelSize: 11
                                    color: Colors.md3.outline
                                }

                                Flow {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Repeater {
                                        model: root.idNames

                                        delegate: Rectangle {
                                            id: idChip
                                            required property string modelData
                                            required property int index
                                            readonly property bool selected: root.selIdx === index
                                            height: 32
                                            width: idTxt.implicitWidth + 28
                                            radius: 16
                                            color: selected ? Colors.md3.secondary_container : Colors.md3.surface_container_highest

                                            Text {
                                                id: idTxt
                                                anchors.centerIn: parent
                                                text: idChip.modelData
                                                font.family: Config.fontFamily
                                                font.pixelSize: 12
                                                font.weight: Font.Medium
                                                color: idChip.selected ? Colors.md3.on_secondary_container : Colors.md3.on_surface_variant
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.flow.selectedIdentity = root.flow.identities[idChip.index]
                                            }
                                        }
                                    }
                                }
                            }

                            PasswordField {
                                id: field
                                Layout.fillWidth: true
                                revealed: false
                                busy: root.busy
                                error: root.wrong
                                locked: root.lockedOut
                                placeholder: root.lockedOut ? root.supplementary.replace(/^\(|\)$/g, "") : Localization.t(root.wrong ? "lockSurface.incorrect_password" : "lockSurface.password")
                                onTextChanged: {
                                    root.wrong = false;
                                    root.draft = text;
                                }
                                onAccepted: root.submit(field.text)
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.topMargin: 6
                                Layout.leftMargin: 16
                                Layout.rightMargin: 16
                                visible: text !== "" && !root.lockedOut
                                wrapMode: Text.Wrap
                                text: root.supplementary
                                font.family: Config.fontFamily
                                font.pixelSize: 12
                                color: root.supplementaryIsError ? Colors.md3.error : Colors.md3.on_surface_variant
                            }

                            RowLayout {
                                Layout.alignment: Qt.AlignRight
                                Layout.topMargin: 18
                                spacing: 8

                                LockButton {
                                    size: 40
                                    label: Localization.t("lockSurface.cancel")
                                    onClicked: root.flow?.cancelAuthenticationRequest()
                                }

                                Rectangle {
                                    id: okBtn
                                    readonly property bool ready: field.hasText && !root.busy
                                    readonly property color content: ready ? Colors.md3.on_primary : Qt.alpha(Colors.md3.on_surface, 0.38)
                                    implicitWidth: okRow.implicitWidth + 32
                                    implicitHeight: 40
                                    Behavior on implicitWidth {
                                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                                    }
                                    radius: height / 2
                                    color: ready ? Colors.md3.primary : Qt.alpha(Colors.md3.on_surface, 0.12)
                                    Behavior on color {
                                        ColorAnimation { duration: 150 }
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: parent.radius
                                        color: okBtn.content
                                        opacity: okBtn.ready && okMa.containsMouse ? 0.08 : 0
                                        Behavior on opacity {
                                            NumberAnimation { duration: 120 }
                                        }
                                    }

                                    Row {
                                        id: okRow
                                        anchors.centerIn: parent
                                        spacing: 8

                                        LoadingSpinner {
                                            anchors.verticalCenter: parent.verticalCenter
                                            visible: root.busy && field.hasText
                                            running: visible
                                            size: 16
                                            color: okBtn.content
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: Localization.t(root.busy && field.hasText ? "polkit.verifying" : "polkit.authenticate")
                                            font.family: Config.fontFamily
                                            font.pixelSize: 13
                                            font.weight: Font.Medium
                                            color: okBtn.content
                                        }
                                    }

                                    MouseArea {
                                        id: okMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: okBtn.ready ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: root.submit(field.text)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
