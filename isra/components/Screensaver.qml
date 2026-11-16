pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components.screensaver
import qs.services
import qs.style

Scope {
    id: root

    readonly property var cfg: Config.screensaver
    readonly property bool canRun: cfg.enabled && !LockscreenService.locked && !GameModeService.active
    property bool shown: false
    property bool closing: false
    property real fade: 0
    property bool preview: false

    Behavior on fade {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutCubic
        }
    }

    function show() {
        if (LockscreenService.locked) {
            if (cfg.enabled && !GameModeService.active && !LockscreenService.lockAnimating)
                LockscreenService.saverStart();
            return;
        }
        if (!canRun)
            return;
        hideTimer.stop();
        closing = false;
        shown = true;
        fade = 1;
    }

    signal clearAll()

    Connections {
        target: LockscreenService
        function onLockAnimatingChanged() {
            if (LockscreenService.lockAnimating && root.shown && !root.closing) {
                LockscreenService.fromSaver = true;
                root.clearAll();
            }
        }
    }

    function dismiss() {
        if (LockscreenService.locked && !shown) {
            LockscreenService.saverWake();
            return;
        }
        if (LockscreenService.lockAnimating)
            LockscreenService.fromSaver = false;
        closing = true;
        fade = 0;
        hideTimer.restart();
    }

    onCanRunChanged: if (!canRun) {
        hideTimer.stop();
        shown = false;
        fade = 0;
    }

    Timer {
        id: hideTimer
        interval: 450
        onTriggered: root.shown = false
    }

    IpcHandler {
        target: "screensaver"

        function start(): void {
            root.show();
        }

        function stop(): void {
            root.dismiss();
        }

        function window(): void {
            root.preview = !root.preview;
        }

        function toggle(): void {
            root.shown ? root.dismiss() : root.show();
        }
    }

    FloatingWindow {
        visible: root.preview
        implicitWidth: 1280
        implicitHeight: 720
        title: "Screensaver preview"
        color: "transparent"
        onVisibleChanged: if (!visible) root.preview = false

        SaverStage {
            id: previewStage
            anchors.fill: parent
            mode: root.cfg.mode
            speed: root.cfg.speed
            showClock: root.cfg.showClock
            monochrome: root.cfg.monochrome
            shuffleSec: root.cfg.shuffleMinutes * 60
        }

        Row {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 16
            spacing: 8

            Repeater {
                model: [
                    { label: "Shuffle", act: 0 },
                    { label: "Replay intro", act: 1 }
                ]

                Rectangle {
                    id: btn
                    required property var modelData
                    width: txt.implicitWidth + 28
                    height: 36
                    radius: 18
                    color: Colors.md3.primary

                    Text {
                        id: txt
                        anchors.centerIn: parent
                        text: btn.modelData.label
                        color: Colors.md3.on_primary
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: btn.modelData.act === 0 ? previewStage.shuffle() : previewStage.replay()
                    }
                }
            }
        }
    }

    Variants {
        model: root.shown ? Quickshell.screens : []

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            WlrLayershell.namespace: "quickshell:screensaver"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.closing ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            mask: root.closing ? passthrough : null
            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            Region { id: passthrough }

            Item {
                id: surface
                property bool armed: false
                property real homeX: -1
                property real homeY: -1

                anchors.fill: parent
                opacity: root.fade
                focus: true
                Keys.onPressed: if (surface.armed) root.dismiss()

                Timer {
                    running: true
                    interval: 500
                    onTriggered: surface.armed = true
                }

                SaverStage {
                    id: stage
                    anchors.fill: parent
                    mode: root.cfg.mode
                    speed: root.cfg.speed
                    showClock: root.cfg.showClock
                    monochrome: root.cfg.monochrome
                    shuffleSec: root.cfg.shuffleMinutes * 60
                }

                Connections {
                    target: root
                    function onClearAll() { stage.clear(); }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.BlankCursor
                    onPressed: if (surface.armed) root.dismiss()
                    onPositionChanged: mouse => {
                        if (surface.homeX < 0) {
                            surface.homeX = mouse.x;
                            surface.homeY = mouse.y;
                        } else if (surface.armed && Math.hypot(mouse.x - surface.homeX, mouse.y - surface.homeY) > 24) {
                            root.dismiss();
                        }
                    }
                }
            }
        }
    }
}
