import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets

import qs.icons
import qs.services
import qs.style

Scope {
    id: root
    property int fontSize: 24

    readonly property int effectivePosition: Config.osdFollowBar ? (Config.bar.position === 1 ? 3 : 1) : Config.osdPosition
    property bool isVertical: root.effectivePosition === 2 || root.effectivePosition === 4

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Connections {
        target: Pipewire.defaultAudioSink?.audio ?? null

        function onVolumeChanged() {
            SoundService.volumeChange();
            root.showVolumeOsd();
        }
        function onMutedChanged() {
            SoundService.volumeChange();
            root.showVolumeOsd();
        }
    }

    property bool shouldShowVolume: false
    function showVolumeOsd() {
        root.shouldShowVolume = true;
        volumeHideTimer.restart();
    }

    property bool isMuted: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio.muted : false

    property real rawVolume: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio.volume : 0
    property real volumePercent: root.rawVolume * 100
    property bool isVolumeOverLimit: volumePercent > 100

    property real animatedVolume: root.rawVolume
    Behavior on animatedVolume {
        enabled: root.shouldShowVolume
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    property real animatedVolumePercent: root.animatedVolume * 100
    property real volumeFillFraction: Math.min(animatedVolumePercent / 100, 1)
    property real volumeErrorFraction: Math.max(Math.min((animatedVolumePercent - 100) / 50, 1), 0)

    Timer {
        id: volumeHideTimer
        interval: 1200
        onTriggered: root.shouldShowVolume = false
    }

    property bool shouldShowBrightness: false
    function showBrightnessOsd() {
        root.shouldShowBrightness = true;
        brightnessHideTimer.restart();
    }

    Connections {
        target: BrightnessService
        function onValueChanged() {
            root.showBrightnessOsd();
        }
    }

    property real animatedBrightness: BrightnessService.value
    Behavior on animatedBrightness {
        enabled: root.shouldShowBrightness
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }
    property real brightnessPercent: root.animatedBrightness * 100
    property real brightnessFillFraction: Math.min(root.animatedBrightness, 1)

    Timer {
        id: brightnessHideTimer
        interval: 1200
        onTriggered: root.shouldShowBrightness = false
    }

    LazyLoader {
        active: root.shouldShowVolume || root.shouldShowBrightness

        PanelWindow {
            anchors.top: root.effectivePosition === 0 || root.effectivePosition === 1
            anchors.right: root.effectivePosition === 2
            anchors.bottom: root.effectivePosition === 3
            anchors.left: root.effectivePosition === 4

            margins.top: {
                if (root.effectivePosition === 0) {
                    return screen.height * 0.57;
                }
                return root.effectivePosition === 1 ? 24 : 0;
            }
            margins.right: root.effectivePosition === 2 ? 24 : 0
            margins.bottom: root.effectivePosition === 3 ? 24 : 0
            margins.left: root.effectivePosition === 4 ? 24 : 0

            exclusiveZone: 0
            color: "transparent"

            implicitWidth: stack.implicitWidth
            implicitHeight: stack.implicitHeight

            Grid {
                id: stack
                anchors.centerIn: parent
                columns: root.isVertical ? 2 : 1
                spacing: 12

                OsdCard {
                    width: root.isVertical ? 48 : 280
                    height: root.isVertical ? 280 : 48
                    visible: root.shouldShowVolume

                    effectivePosition: root.effectivePosition
                    vertical: root.isVertical
                    fontSize: root.fontSize
                    valueText: Math.round(root.volumePercent)
                    dimmed: root.isMuted
                    errorActive: root.isVolumeOverLimit
                    fillFraction: root.volumeFillFraction
                    errorFraction: root.volumeErrorFraction

                    icon: Component {
                        VolumeIcon {
                            muted: root.isMuted
                            volume: Math.round(root.volumePercent)
                            color: Colors.md3.on_surface_variant
                            iconSize: root.fontSize
                        }
                    }
                }

                OsdCard {
                    width: root.isVertical ? 48 : 280
                    height: root.isVertical ? 280 : 48
                    visible: root.shouldShowBrightness

                    effectivePosition: root.effectivePosition
                    vertical: root.isVertical
                    fontSize: root.fontSize
                    valueText: Math.round(root.brightnessPercent)
                    dimmed: false
                    errorActive: false
                    fillFraction: root.brightnessFillFraction
                    errorFraction: 0

                    icon: Component {
                        BrightnessIcon {
                            brightness: Math.round(root.brightnessPercent)
                            color: Colors.md3.on_surface_variant
                            iconSize: root.fontSize
                        }
                    }
                }
            }
        }
    }
}
