pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import qs.style
import qs.icons
import qs.services
import qs.windows.components

PageBase {
    pageId: "sound"
    title: Localization.t("soundPage.sound_notifications")
    subtitle: Localization.t("soundPage.audio_output_and_interruption_settings")

    onActiveChanged: active ? AudioService.startMicMeter() : AudioService.stopMicMeter()

    component SoundSwitch: SettingSwitch {
        id: sw
        property string key
        enabled: Config.sounds.enabled
        opacity: enabled ? 1.0 : 0.4
        checked: Config.sounds[sw.key]
        onToggled: v => {
            const patch = {};
            patch[sw.key] = v;
            Config.update({
                sounds: Object.assign({}, Config.sounds, patch)
            });
        }
    }

    SectionCard {
        label: Localization.t("soundPage.output")
        Layout.fillWidth: true

        Rectangle {
            height: 6
            width: 1
            color: "transparent"
        }

        AudioDeviceList {
            sink: true
        }

        VolumeRow {
            muted: AudioService.muted
            volume: AudioService.volume
            onMuteToggled: AudioService.toggleMute()
            onVolumeMoved: v => AudioService.setVolume(v)
        }

        Rectangle {
            height: 4
            width: 1
            color: "transparent"
        }
    }

    SectionCard {
        label: Localization.t("soundPage.input")
        Layout.fillWidth: true

        Rectangle {
            height: 6
            width: 1
            color: "transparent"
        }

        AudioDeviceList {
            sink: false
        }

        VolumeRow {
            glyph: "󰍬"
            mutedGlyph: "󰍭"
            muted: AudioService.sourceMuted
            volume: AudioService.sourceVolume
            onMuteToggled: AudioService.toggleSourceMute()
            onVolumeMoved: v => AudioService.setSourceVolume(v)
        }

        Item {
            implicitWidth: parent?.width ?? 0
            implicitHeight: 10

            Item {
                id: micTrack
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 12
                    rightMargin: 12
                }
                height: 6

                property real gap: 4
                property real level: AudioService.micLevel
                property real effectiveGap: (level <= 0 || level >= 1) ? 0 : gap
                property real fillW: Math.max(0, width * level - effectiveGap)
                property color fillColor: {
                    if (AudioService.sourceMuted)
                        return Colors.md3.outline;
                    if (AudioService.micLevel > 0.85)
                        return Colors.md3.error;
                    if (AudioService.micLevel > 0.6)
                        return Colors.md3.tertiary;
                    return Colors.md3.primary;
                }

                Behavior on fillW {
                    NumberAnimation {
                        duration: 10
                    }
                }
                Behavior on fillColor {
                    ColorAnimation {
                        duration: 5
                    }
                }

                Rectangle {
                    id: micBarLeft
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    width: micTrack.fillW
                    height: micTrack.height
                    radius: height / 2
                    color: micTrack.fillColor
                }

                Rectangle {
                    anchors {
                        left: micBarLeft.right
                        leftMargin: micTrack.effectiveGap
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    height: micTrack.height
                    radius: height / 2
                    color: Colors.md3.surface_variant
                }
            }
        }

        Rectangle {
            height: 12
            width: 1
            color: "transparent"
        }
    }

    SectionCard {
        label: Localization.t("soundPage.apps")
        Layout.fillWidth: true

        Item {
            visible: streamRepeater.count === 0
            implicitWidth: parent?.width ?? 0
            implicitHeight: 56

            Text {
                anchors.centerIn: parent
                text: Localization.t("soundPage.no_apps_playing_audio")
                font.family: Config.fontFamily
                font.pixelSize: 13
                color: Colors.md3.outline
            }
        }

        Repeater {
            id: streamRepeater
            model: AudioService.nodes.filter(n => n.audio && n.isStream && n.isSink && n.name !== "quickshell")

            delegate: Item {
                id: streamRow
                required property var modelData
                required property int index

                PwObjectTracker {
                    objects: [streamRow.modelData]
                }

                implicitWidth: parent?.width ?? 0
                implicitHeight: 56

                VolumeRow {
                    anchors.fill: parent
                    mutedGlyph: "󰸈"
                    buttonSize: 32
                    accent: Colors.md3.secondary
                    label: AudioService.appNodeDisplayName(streamRow.modelData)
                    sublabel: streamRow.modelData.properties["media.name"] ?? ""
                    muted: streamRow.modelData.audio?.muted ?? false
                    volume: streamRow.modelData.audio?.volume ?? 0
                    onMuteToggled: {
                        if (streamRow.modelData.audio)
                            streamRow.modelData.audio.muted = !streamRow.modelData.audio.muted;
                    }
                    onVolumeMoved: v => {
                        if (streamRow.modelData.audio)
                            streamRow.modelData.audio.volume = v;
                    }
                }

                Rectangle {
                    visible: streamRow.index < streamRepeater.count - 1
                    anchors {
                        bottom: parent.bottom
                        left: parent.left
                        leftMargin: 18
                        right: parent.right
                        rightMargin: 18
                    }
                    height: 1
                    color: Colors.md3.outline_variant
                    opacity: 0.5
                }
            }
        }
    }

    SectionCard {
        label: Localization.t("soundPage.sounds")
        Layout.fillWidth: true

        SettingSwitch {
            label: Localization.t("soundPage.enable_sounds")
            sublabel: Localization.t("soundPage.master_toggle_for_ui_sound_effects")
            iconBg: Colors.md3.secondary_container
            checked: Config.sounds.enabled
            onToggled: v => Config.update({
                    sounds: Object.assign({}, Config.sounds, {
                        enabled: v
                    })
                })
        }
        SoundSwitch {
            label: Localization.t("soundPage.mute_during_media")
            sublabel: Localization.t("soundPage.silence_system_sounds_while_media_plays")
            key: "muteDuringMedia"
        }
        SettingSelect {
            label: Localization.t("soundPage.sound_theme")
            sublabel: Localization.t("soundPage.which_installed_sound_theme_to_use")
            enabled: Config.sounds.enabled
            opacity: enabled ? 1.0 : 0.4
            options: SoundService.availableThemes.map(name => ({
                    label: name.charAt(0).toUpperCase() + name.slice(1),
                    value: name
                }))
            currentValue: Config.sounds.theme
            onSelected: v => Config.update({
                    sounds: Object.assign({}, Config.sounds, {
                        theme: v
                    })
                })
            onAboutToOpen: SoundService.rescanThemes()
        }
        SettingSlider {
            label: Localization.t("soundPage.sound_volume")
            enabled: Config.sounds.enabled
            opacity: enabled ? 1.0 : 0.4
            from: 0
            to: 100
            stepSize: 1
            unit: "%"
            value: Config.sounds.volume * 100
            onMoved: v => Config.update({
                    sounds: Object.assign({}, Config.sounds, {
                        volume: v / 100
                    })
                })
        }
        SoundSwitch {
            label: Localization.t("soundPage.notification_sound")
            key: "notifications"
        }
        SoundSwitch {
            label: Localization.t("soundPage.volume_sound")
            key: "volumeChange"
        }
        SoundSwitch {
            label: Localization.t("soundPage.screenshot_sound")
            key: "screenshot"
        }
        SoundSwitch {
            label: Localization.t("soundPage.unlock_sound")
            key: "unlock"
        }
        SoundSwitch {
            label: Localization.t("soundPage.startup_sound")
            key: "startup"
        }
        SoundSwitch {
            label: Localization.t("soundPage.lock_sound")
            key: "lock"
        }
        SoundSwitch {
            label: Localization.t("soundPage.charger_sound")
            key: "chargerPlug"
        }
        SoundSwitch {
            label: Localization.t("soundPage.battery_low_sound")
            key: "batteryLow"
        }
        SoundSwitch {
            label: Localization.t("soundPage.localsend_sound")
            key: "localsend"
        }
        SoundSwitch {
            label: Localization.t("soundPage.bluetooth_sound")
            key: "bluetooth"
        }
        SettingRow {
            isLast: true
            label: Localization.t("soundPage.silenced_apps")
            sublabel: Localization.t("soundPage.dont_play_a_sound_for_these_apps")
            enabled: Config.sounds.enabled
            opacity: enabled ? 1.0 : 0.4

            Flow {
                width: 220
                spacing: 6

                Repeater {
                    model: Config.sounds.silentApps

                    InputChip {
                        required property string modelData
                        label: modelData
                        onRemoved: {
                            const updated = Config.sounds.silentApps.filter(x => x !== modelData);
                            Config.update({
                                sounds: Object.assign({}, Config.sounds, {
                                    silentApps: updated
                                })
                            });
                        }
                    }
                }

                ChipAdd {
                    placeholder: Localization.t("soundPage.app_name")
                    onCommitted: v => {
                        if (!Config.sounds.silentApps.includes(v)) {
                            Config.update({
                                sounds: Object.assign({}, Config.sounds, {
                                    silentApps: [...Config.sounds.silentApps, v]
                                })
                            });
                        }
                    }
                }
            }
        }
    }

    SectionCard {
        label: Localization.t("soundPage.notifications")
        Layout.fillWidth: true

        SettingSwitch {
            isLast: true
            label: Localization.t("soundPage.show_on_all_monitors")
            sublabel: Localization.t("soundPage.mirror_popups_across_every_screen")
            iconBg: Colors.md3.secondary_container
            checked: Config.notifications.showAllMonitors ?? false
            onToggled: v => Config.update({
                    notifications: Object.assign({}, Config.notifications, {
                        showAllMonitors: v
                    })
                })
        }
        SettingSelect {
            label: Localization.t("soundPage.popup_timeout")
            sublabel: Localization.t("soundPage.how_long_popups_stay_visible")
            iconBg: Colors.md3.secondary_container
            options: [
                {
                    label: Localization.t("soundPage.3_seconds"),
                    value: 3
                },
                {
                    label: Localization.t("soundPage.5_seconds"),
                    value: 5
                },
                {
                    label: Localization.t("soundPage.8_seconds"),
                    value: 8
                },
                {
                    label: Localization.t("soundPage.never"),
                    value: 0
                }
            ]
            currentValue: Config.notifications.popupTimeout ?? 5
            onSelected: v => Config.update({
                    notifications: Object.assign({}, Config.notifications, {
                        popupTimeout: v
                    })
                })
        }
        SettingSwitch {
            label: Localization.t("soundPage.follow_bar_position")
            sublabel: Localization.t("soundPage.snap_popups_to_the_same_edge")
            checked: Config.notifications.popupFollowBar ?? true
            onToggled: v => Config.update({
                    notifications: Object.assign({}, Config.notifications, {
                        popupFollowBar: v
                    })
                })
        }
        SettingSwitch {
            label: Localization.t("soundPage.network_notifications")
            sublabel: Localization.t("soundPage.notify_on_wifi_and_ethernet_changes")
            checked: Config.notifications.network ?? true
            onToggled: v => Config.update({
                    notifications: Object.assign({}, Config.notifications, {
                        network: v
                    })
                })
        }
        SettingSwitch {
            label: Localization.t("soundPage.bluetooth_notifications")
            sublabel: Localization.t("soundPage.notify_on_bluetooth_device_changes")
            checked: Config.notifications.bluetooth ?? true
            onToggled: v => Config.update({
                    notifications: Object.assign({}, Config.notifications, {
                        bluetooth: v
                    })
                })
        }
        SettingChips {
            isLast: true
            label: Localization.t("backgroundPage.position")
            enabled: !(Config.notifications.popupFollowBar ?? true)
            opacity: enabled ? 1.0 : 0.4
            options: [
                {
                    label: Localization.t("soundPage.always_top"),
                    value: 1
                },
                {
                    label: Localization.t("soundPage.always_bottom"),
                    value: 2
                }
            ]
            currentValue: Config.notifications.popupPosition ?? 1
            onSelected: v => Config.update({
                    notifications: Object.assign({}, Config.notifications, {
                        popupPosition: v
                    })
                })
        }
    }
}
