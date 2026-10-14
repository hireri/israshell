import QtQuick
import Quickshell

import qs.icons
import qs.services
import qs.style

Scope {
    id: root

    readonly property int effectivePosition: Config.osdFollowBar ? (Config.bar.position === 1 ? 3 : 1) : Config.osdPosition
    readonly property bool recording: VoiceService.phase === "recording"
    readonly property bool open: VoiceService.phase !== "idle" && !VoiceService.capture

    readonly property string liveLabel: {
        switch (VoiceService.phase) {
        case "recording":
            return Localization.t("voice.listening") + "  " + VoiceService.elapsed;
        case "transcribing":
            return Localization.t("voice.transcribing");
        default:
            return VoiceService.message;
        }
    }

    property string label: ""
    onLiveLabelChanged: if (open)
        label = liveLabel
    onOpenChanged: {
        if (open)
            label = liveLabel;
        else
            closeTimer.restart();
    }

    Timer {
        id: closeTimer
        interval: 220
    }

    LazyLoader {
        active: root.open || closeTimer.running

        PanelWindow {
            anchors.top: root.effectivePosition === 0 || root.effectivePosition === 1
            anchors.right: root.effectivePosition === 2
            anchors.bottom: root.effectivePosition === 3
            anchors.left: root.effectivePosition === 4

            margins.top: root.effectivePosition === 0 ? screen.height * 0.57 : (root.effectivePosition === 1 ? 24 : 0)
            margins.right: root.effectivePosition === 2 ? 24 : 0
            margins.bottom: root.effectivePosition === 3 ? 24 : 0
            margins.left: root.effectivePosition === 4 ? 24 : 0

            exclusiveZone: 0
            color: "transparent"

            implicitWidth: 360
            implicitHeight: 48

            Rectangle {
                id: pill

                property bool shown: false
                Component.onCompleted: Qt.callLater(() => pill.shown = true)

                anchors.centerIn: parent
                height: 48
                width: row.implicitWidth + 36
                radius: height / 2
                color: Colors.md3.surface_container
                border.width: 1
                border.color: Qt.alpha(Colors.md3.outline_variant, 0.5)

                opacity: root.open && shown ? 1 : 0
                scale: root.open && shown ? 1 : 0.88

                Behavior on width {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on opacity {
                    NumberAnimation {
                        duration: root.open ? 160 : 180
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: root.open ? 260 : 180
                        easing.type: Easing.OutCubic
                    }
                }

                Row {
                    id: row
                    anchors.centerIn: parent
                    spacing: 10

                    MaterialIcon {
                        id: mic
                        anchors.verticalCenter: parent.verticalCenter
                        name: "mic"
                        filled: true
                        iconSize: 22
                        color: VoiceService.phase === "error" || root.recording ? Colors.md3.error : Colors.md3.primary

                        SequentialAnimation on opacity {
                            running: root.recording
                            loops: Animation.Infinite
                            onRunningChanged: if (!running)
                                mic.opacity = 1
                            NumberAnimation {
                                to: 0.4
                                duration: 600
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                to: 1
                                duration: 600
                                easing.type: Easing.InOutSine
                            }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Config.fontFamily
                        font.pixelSize: 14
                        font.features: {
                            "tnum": 1
                        }
                        color: Colors.md3.on_surface
                        text: root.label
                    }
                }
            }
        }
    }
}
