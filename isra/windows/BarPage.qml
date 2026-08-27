pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import qs.style
import qs.icons
import qs.services
import qs.windows.components

PageBase {
    title: Localization.t("settingsWindow.bar")
    subtitle: Localization.t("barPage.layout_media_and_tray")

    Component {
        id: huggingIconComp
        MaterialIcon {
            name: "hugging-bar"
            iconSize: 16
        }
    }
    Component {
        id: straightIconComp
        MaterialIcon {
            name: "straight-bar"
            iconSize: 16
        }
    }
    Component {
        id: floatingIconComp
        MaterialIcon {
            name: "floating-bar"
            iconSize: 16
        }
    }
    Component {
        id: chromeOsIconComp
        MaterialIcon {
            name: "chromeos-bar"
            iconSize: 16
        }
    }
    Component {
        id: albumIconComp
        MaterialIcon {
            name: "album"
            iconSize: 16
        }
    }
    Component {
        id: queueMusicIconComp
        MaterialIcon {
            name: "queue-music"
            iconSize: 16
        }
    }
    Component {
        id: menuIconComp
        MaterialIcon {
            name: "menu"
            iconSize: 16
        }
    }
    Component {
        id: arrowUpwardComp
        MaterialIcon {
            name: "arrow-upward"
            iconSize: 16
        }
    }
    Component {
        id: arrowDownwardComp
        MaterialIcon {
            name: "arrow-downward"
            iconSize: 16
        }
    }

    SectionCard {
        label: Localization.t("backgroundPage.layout")
        Layout.fillWidth: true

        SettingChips {
            label: Localization.t("barPage.bar_mode")
            sublabel: {
                switch (currentValue) {
                case 0:
                    return Localization.t("barPage.hugging_screen_edge");
                case 1:
                    return Localization.t("barPage.attached_to_screen_edge");
                case 2:
                    return Localization.t("barPage.floating_detached");
                case 3:
                    return Localization.t("barPage.chromebook_corners");
                default:
                    return "";
                }
            }
            options: [
                {
                    label: "",
                    value: 0,
                    icon: huggingIconComp
                },
                {
                    label: "",
                    value: 1,
                    icon: straightIconComp
                },
                {
                    label: "",
                    value: 3,
                    icon: chromeOsIconComp
                },
                {
                    label: "",
                    value: 2,
                    icon: floatingIconComp
                }
            ]
            currentValue: Config.bar.mode 
            onSelected: v => Config.update({
                bar: Object.assign({}, Config.bar, {
                    mode: v
                })
            })
        }
        SettingChips {
            label: Localization.t("backgroundPage.position")
            options: [
                {
                    label: Localization.t("backgroundPage.top"),
                    value: 0,
                    icon: arrowUpwardComp
                },
                {
                    label: Localization.t("backgroundPage.bottom"),
                    value: 1,
                    icon: arrowDownwardComp
                }
            ]
            currentValue: Config.bar.position
            onSelected: v => Config.update({
                bar: Object.assign({}, Config.bar, {
                    position: v
                })
            })
        }

        SettingChips {
            label: Localization.t("barPage.transparency")
            sublabel: Localization.t("barPage.background_opacity_level")
            options: [
                {
                    label: Localization.t("backgroundPage.tinted"),
                    value: 1
                },
                {
                    label: Localization.t("barPage.full"),
                    value: 2
                }
            ]
            currentValue: Config.bar.transparency
            onSelected: v => Config.update({
                bar: Object.assign({}, Config.bar, {
                    transparency: v
                })
            })
        }

        SettingSwitch {
            label: Localization.t("barPage.transparent_pills")
            sublabel: Localization.t("barPage.remove_pills_background")
            checked: Config.bar.transparentPills
            onToggled: v => Config.update({
                bar: Object.assign({}, Config.bar, {
                    transparentPills: v
                })
            })
        }

        SettingSwitch {
            label: Localization.t("barPage.stacked_sliders")
            sublabel: Localization.t("barPage.volume_and_brightness_sliders_arranged")
            checked: Config.verticalQSSliders
            onToggled: v => Config.update({ verticalQSSliders: v })
        }
    }

    SectionCard {
        label: Localization.t("barPage.status_icons")
        Layout.fillWidth: true

        SettingSwitch {
            label: Localization.t("barPage.outline_icons")
            sublabel: Localization.t("barPage.outline_style_instead_of_filled")
            checked: Config.quicksettings.outline
            onToggled: v => Config.update({
                quicksettings: Object.assign({}, Config.quicksettings, {
                    outline: v
                })
            })
        }

        SettingRow {
            isLast: true
            label: Localization.t("barPage.status_icons")
            sublabel: Localization.t("barPage.toggle_individual_status_icons")

            Flow {
                width: 220
                spacing: 6

                readonly property var actions: [
                    { key: "wifi", label: Localization.t("qsTileService.wifi") },
                    { key: "bluetooth", label: Localization.t("qsTileService.bluetooth") },
                    { key: "sound", label: Localization.t("barPage.sound") },
                    { key: "caffeine", label: Localization.t("qsTileService.caffeine") },
                    { key: "nightlight", label: Localization.t("qsTileService.night_light") },
                    { key: "dnd", label: Localization.t("barPage.dnd") },
                    { key: "recording", label: Localization.t("barPage.recording") },
                    { key: "vpn", label: Localization.t("barPage.vpn") },
                    { key: "mic", label: Localization.t("qsTileService.microphone") },
                    { key: "screenshare", label: Localization.t("barPage.screenshare") },
                    { key: "traffic", label: Localization.t("barPage.traffic") },
                    { key: "dns", label: Localization.t("qsTileService.dns") },
                    { key: "gamemode", label: Localization.t("qsTileService.game_mode") },
                    { key: "powerprofile", label: Localization.t("qsTileService.power_profile") }
                ]

                Repeater {
                    model: parent.actions

                    FilterChip {
                        required property var modelData
                        label: modelData.label
                        active: Config.quicksettings.icons.includes(modelData.key)
                        onToggled: isActive => {
                            const key = modelData.key;
                            const icons = Config.quicksettings.icons;
                            const updated = isActive ? icons.concat([key]) : icons.filter(x => x !== key);
                            Config.update({
                                quicksettings: Object.assign({}, Config.quicksettings, {
                                    icons: updated
                                })
                            });
                        }
                    }
                }
            }
        }
    }

    SectionCard {
        label: Localization.t("widgetService.workspaces")
        Layout.fillWidth: true

        SettingSwitch {
            label: Localization.t("barPage.compact_workspaces")
            sublabel: Localization.t("barPage.shrink_workspaces_to_hide_empty")
            checked: Config.workspaces.compact
            onToggled: v => Config.update({
                workspaces: Object.assign({}, Config.workspaces, {
                    compact: v
                })
            })
        }

        SettingSwitch {
            label: Localization.t("barPage.use_icons")
            sublabel: Localization.t("barPage.show_application_icons_for_workspaces")
            checked: Config.workspaces.useIcons
            onToggled: v => Config.update({
                workspaces: Object.assign({}, Config.workspaces, {
                    useIcons: v
                })
            })
        }

        SettingChips {
            isLast: true
            label: Localization.t("barPage.workspace_style")
            sublabel: {
                switch (currentValue) {
                case 0:
                    return Localization.t("barPage.numbers_123");
                case 1:
                    return Localization.t("barPage.roman_numerals");
                case 2:
                    return Localization.t("barPage.kanji_numerals");
                default:
                    return "";
                }
            }
            options: [
                {
                    label: "6",
                    value: 0
                },
                {
                    label: Localization.t("barPage.vi"),
                    value: 1
                },
                {
                    label: "六",
                    value: 2
                }
            ]
            currentValue: Config.workspaces.style
            onSelected: v => Config.update({
                workspaces: Object.assign({}, Config.workspaces, {
                    style: v
                })
            })
        }
        SettingSwitch {
            label: Localization.t("barPage.always_show_numbers")
            sublabel: Localization.t("barPage.stop_hiding_numbers_while_not")
            checked: Config.workspaces.alwaysShowNumbers
            onToggled: v => Config.update({
                workspaces: Object.assign({}, Config.workspaces, {
                    alwaysShowNumbers: v
                })
            })
        }
    }

    SectionCard {
        label: Localization.t("barPage.widget_order")
        Layout.fillWidth: true

        SettingChips {
            label: Localization.t("barPage.center_layout_mode")
            sublabel: currentValue === "auto" ? Localization.t("barPage.automatically_fills_center_space") : Localization.t("barPage.pins_space_around_a_selected")
            options: [
                {
                    label: Localization.t("barPage.auto"),
                    value: "auto"
                },
                {
                    label: Localization.t("barPage.anchor"),
                    value: "anchor"
                }
            ]
            currentValue: Config.bar.center?.mode || "auto"
            onSelected: v => Config.update({
                bar: Object.assign({}, Config.bar, {
                    center: Object.assign({}, Config.bar.center, {
                        mode: v
                    })
                })
            })
        }

        WidgetOrderEditor {
            width: parent.width
            leftIds: Config.bar.left
            centerData: Config.bar.center
            rightIds: Config.bar.right
            disabledIds: Config.bar.disabled
            onOrderChanged: (newLeft, newCenter, newRight, newDisabled) => Config.update({
                bar: Object.assign({}, Config.bar, {
                    left: newLeft, center: newCenter, right: newRight, disabled: newDisabled
                })
            })
        }
    }

    SectionCard {
        label: Localization.t("widgetService.media_player")
        Layout.fillWidth: true

        SettingChips {
            label: Localization.t("barPage.player_mode")
            sublabel: {
                switch (currentValue) {
                case 0:
                    return Localization.t("barPage.cover_and_title");
                case 1:
                    return Localization.t("barPage.cover_only");
                case 2:
                    return Localization.t("barPage.title_only");
                default:
                    return "";
                }
            }
            options: [
                {
                    label: Localization.t("barPage.both"),
                    value: 0,
                    icon: queueMusicIconComp
                },
                {
                    label: Localization.t("barPage.cover"),
                    value: 1,
                    icon: albumIconComp
                },
                {
                    label: Localization.t("barPage.title"),
                    value: 2,
                    icon: menuIconComp
                }
            ]
            currentValue: Config.bar.playerMode
            onSelected: v => Config.update({
                bar: Object.assign({}, Config.bar, {
                    playerMode: v
                })
            })
        }

        SettingSwitch {
            label: Localization.t("barPage.spinning_cover")
            sublabel: Localization.t("barPage.rotate_album_art_while_playing")
            checked: Config.bar.spinningCover
            onToggled: v => Config.update({
                bar: Object.assign({}, Config.bar, {
                    spinningCover: v
                })
            })
        }

        SettingSwitch {
            label: Localization.t("barPage.progress_ring")
            sublabel: Localization.t("barPage.circular_progress_indicator_around_the")
            checked: Config.bar.playerRing
            onToggled: v => Config.update({
                bar: Object.assign({}, Config.bar, {
                    playerRing: v
                })
            })
        }

        SettingSlider {
            isLast: true
            label: Localization.t("barPage.scroll_speed")
            sublabel: Localization.t("barPage.media_title_carousel")
            from: 10
            to: 100
            stepSize: 5
            unit: ""
            value: Config.bar.carouselSpeed
            onMoved: v => Config.update({
                bar: Object.assign({}, Config.bar, {
                    carouselSpeed: v
                })
            })
        }
    }

    SectionCard {
        label: Localization.t("widgetService.system_monitor")
        Layout.fillWidth: true

        SettingChips {
            label: Localization.t("barPage.style")
            sublabel: {
                switch (currentValue) {
                case 1:
                    return Localization.t("barPage.circular_pie_charts");
                case 2:
                    return Localization.t("barPage.horizontal_progress_bars");
                default:
                    return Localization.t("barPage.minimal_icons_with_text");
                }
            }
            options: [
                {
                    label: Localization.t("barPage.icons"),
                    value: 0
                },
                {
                    label: Localization.t("barPage.pie"),
                    value: 1
                },
                {
                    label: Localization.t("settingsWindow.bar"),
                    value: 2
                }
            ]
            currentValue: Config.sysMonitor?.style ?? 0
            onSelected: v => Config.update({
                sysMonitor: Object.assign({}, Config.sysMonitor, {
                    style: v
                })
            })
        }

        SettingSwitch {
            label: Localization.t("barPage.unified_pill")
            sublabel: Localization.t("barPage.group_all_metrics_into_a")
            checked: Config.sysMonitor?.unifiedPill ?? false
            onToggled: v => Config.update({
                sysMonitor: Object.assign({}, Config.sysMonitor, {
                    unifiedPill: v
                })
            })
        }

        SettingSwitch {
            label: Localization.t("barPage.show_percentages")
            sublabel: (Config.sysMonitor?.style ?? 0) === 0 ? "Always enabled for standard icon style" : "Display numerical values next to indicators"
            enabled: (Config.sysMonitor?.style ?? 0) !== 0
            opacity: Config.sysMonitor?.style == 0 ? 0.6 : 1
            checked: (Config.sysMonitor?.style ?? 0) === 0 ? true : (Config.sysMonitor?.showPercent ?? true)
            onToggled: v => Config.update({
                sysMonitor: Object.assign({}, Config.sysMonitor, {
                    showPercent: v
                })
            })
        }

        SettingSwitch {
            isLast: true
            label: Localization.t("barPage.colored_metrics")
            sublabel: Localization.t("barPage.use_distinct_colors_for_each")
            checked: Config.sysMonitor?.colored ?? true
            onToggled: v => Config.update({
                sysMonitor: Object.assign({}, Config.sysMonitor, {
                    colored: v
                })
            })
        }
        SettingRow {
            isLast: true
            label: Localization.t("barPage.glance_metrics")
            sublabel: Localization.t("barPage.toggle_individual_metrics_on_the")

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }

            Flow {
                width: 220
                spacing: 6

                readonly property var actions: [
                    {
                        key: "cpu",
                        label: Localization.t("sysMonitor.cpu")
                    },
                    {
                        key: "ram",
                        label: Localization.t("sysMonitor.ram")
                    },
                    {
                        key: "gpu",
                        label: Localization.t("sysMonitor.gpu")
                    },
                    {
                        key: "temp",
                        label: Localization.t("barPage.temperature")
                    },
                    {
                        key: "swap",
                        label: Localization.t("sysMonitor.swap")
                    }
                ]

                Repeater {
                    model: parent.actions

                    FilterChip {
                        required property var modelData
                        label: modelData.label
                        active: Config.sysMonitor.metrics.includes(modelData.key)
                        onToggled: isActive => {
                            const key = modelData.key;
                            const metricsList = Config.sysMonitor.metrics;
                            const updated = isActive ? metricsList.concat([key]) : metricsList.filter(x => x !== key);
                            
                            Config.update({
                                sysMonitor: Object.assign({}, Config.sysMonitor, {
                                    metrics: updated
                                })
                            });
                        }
                    }
                }
            }
        }

        SettingSwitch {
            label: Localization.t("barPage.smooth_graphs")
            sublabel: Localization.t("barPage.scrolls_the_performance_graphs_smoothly")
            checked: (Config.sysMonitor?.style ?? 0) === 0 ? true : (Config.sysMonitor?.smooth ?? true)
            onToggled: v => Config.update({
                sysMonitor: Object.assign({}, Config.sysMonitor, {
                    smooth: v
                })
            })
        }
    }

    SectionCard {
        label: Localization.t("widgetService.tray")
        Layout.fillWidth: true

        SettingRow {
            isLast: true
            label: Localization.t("barPage.blacklist")
            sublabel: Localization.t("barPage.hidden_from_tray")

            Flow {
                width: 220
                spacing: 6

                Repeater {
                    model: Config.bar.trayBlacklist

                    InputChip {
                        required property string modelData
                        label: modelData
                        onRemoved: {
                            const updated = Config.bar.trayBlacklist.filter(x => x !== modelData);
                            Config.update({
                                bar: Object.assign({}, Config.bar, {
                                    trayBlacklist: updated
                                })
                            });
                        }
                    }
                }

                ChipAdd {
                    placeholder: Localization.t("barPage.app_name")
                    onCommitted: v => {
                        if (!Config.bar.trayBlacklist.includes(v)) {
                            Config.update({
                                bar: Object.assign({}, Config.bar, {
                                    trayBlacklist: [...Config.bar.trayBlacklist, v]
                                })
                            });
                        }
                    }
                }
            }
        }
    }

    SectionCard {
        label: Localization.t("widgetService.toolbar")
        Layout.fillWidth: true

        SettingRow {
            isLast: true
            label: Localization.t("barPage.actions")
            sublabel: Localization.t("barPage.toggle_individual_toolbar_actions")

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }

            Flow {
                width: 220
                spacing: 6

                readonly property var actions: [
                    {
                        key: "screenshot",
                        label: Localization.t("qsTileService.screenshot")
                    },
                    {
                        key: "record",
                        label: Localization.t("qsTileService.record")
                    },
                    {
                        key: "cts",
                        label: Localization.t("barPage.circle_to_search")
                    },
                    {
                        key: "ocr",
                        label: Localization.t("barPage.ocr")
                    },
                    ...(CompositorService.backendName === "hyprland" ? [{
                        key: "colorpicker",
                        label: Localization.t("qsTileService.color_picker")
                    }] : []),
                    {
                        key: "songrec",
                        label: Localization.t("barPage.recognize_music")
                    },
                    {
                        key: "wallpaper",
                        label: Localization.t("barPage.wallpaper_picker")
                    },
                    {
                        key: "localsend",
                        label: Localization.t("qsTileService.localsend")
                    }
                ]

                Repeater {
                    model: parent.actions

                    FilterChip {
                        required property var modelData
                        label: modelData.label
                        active: !Config.screencap.blacklist.includes(modelData.key)
                        onToggled: isActive => {
                            const key = modelData.key;
                            const bl = Config.screencap.blacklist;
                            const updated = isActive ? bl.filter(x => x !== key) : bl.concat([key]);
                            Config.update({
                                screencap: Object.assign({}, Config.screencap, {
                                    blacklist: updated
                                })
                            });
                        }
                    }
                }
            }
        }
    }
}