pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.style
import qs.services
import qs.icons
import qs.windows.components
import qs.components
import Quickshell.Widgets

PageBase {
    title: Localization.t("settingsWindow.visuals_display")
    subtitle: Localization.t("settingsWindow.night_light_blur")

    HeroCard {
        Layout.fillWidth: true
        title: Localization.t("displayPage.night_light")
        subtitle: NightLightService.active ? Localization.t("backgroundPage.active_k").arg(Config.nightLight.nightTemp) : Localization.t("displayPage.off_k_during_day").arg(Config.nightLight.dayTemp)
        iconBg: Colors.md3.tertiary_container
        cardColor: Colors.md3.surface_container
        checked: NightLightService.active
        onToggled: v => NightLightService.toggle()
        MaterialIcon { name: "nightlight" }
    }


    SectionCard {
        label: Localization.t("barPage.temperature")
        Layout.fillWidth: true

        SettingRow {
            label: Localization.t("displayPage.night")
            sublabel: Localization.t("displayPage.applied_when_night_light_is")
            TempStrip {
                from: 1000
                to: 10000
                stepSize: 100
                value: Config.nightLight.nightTemp
                onMoved: v => NightLightService.setNightTemp(Math.round(v))
            }
        }

        SettingRow {
            isLast: true
            label: Localization.t("displayPage.day")
            sublabel: Localization.t("displayPage.applied_during_the_day")
            TempStrip {
                from: 1000
                to: 10000
                stepSize: 100
                value: Config.nightLight.dayTemp
                onMoved: v => NightLightService.setDayTemp(Math.round(v))
            }
        }
    }

    SectionCard {
        label: Localization.t("displayPage.schedule")
        Layout.fillWidth: true

        SettingSwitch {
            label: Localization.t("displayPage.auto_night_light")
            sublabel: Localization.t("displayPage.apply_temperature_on_schedule")
            checked: Config.nightLight.scheduleEnabled
            onToggled: v => Config.update({
                    nightLight: Object.assign({}, Config.nightLight, {
                        scheduleEnabled: v
                    })
                })
        }

        SettingSwitch {
            label: Localization.t("displayPage.auto_dark_mode")
            sublabel: Localization.t("displayPage.switch_theme_at_sunrise_and")
            checked: Config.nightLight.autoDarkMode
            onToggled: v => Config.update({
                    nightLight: Object.assign({}, Config.nightLight, {
                        autoDarkMode: v
                    })
                })
        }

        SettingSwitch {
            label: Localization.t("displayPage.attach_bedtime")
            sublabel: Localization.t("displayPage.attach_bedtime_sub")
            checked: Config.nightLight.attachBedtime
            onToggled: v => Config.update({
                    nightLight: Object.assign({}, Config.nightLight, {
                        attachBedtime: v
                    })
                })
        }

        SettingSwitch {
            label: Localization.t("displayPage.auto_sun_times")
            sublabel: Localization.t("displayPage.auto_sun_times_sub")
            checked: Config.nightLight.autoSunTimes
            onToggled: v => Config.update({
                    nightLight: Object.assign({}, Config.nightLight, {
                        autoSunTimes: v
                    })
                })
        }

        TimeInput {
            enabled: !Config.nightLight.autoSunTimes
            opacity: enabled ? 1.0 : 0.4
            label: Localization.t("displayPage.sunrise")
            sublabel: Localization.t("displayPage.night_light_off_light_mode")
            value: Config.nightLight.sunrise
            onCommitted: v => NightLightService.setSunrise(v)
        }

        TimeInput {
            enabled: !Config.nightLight.autoSunTimes
            opacity: enabled ? 1.0 : 0.4
            label: Localization.t("displayPage.sunset")
            sublabel: Localization.t("displayPage.night_light_on_dark_mode")
            value: Config.nightLight.sunset
            onCommitted: v => NightLightService.setSunset(v)
        }
    }

    HeroCard {
        Layout.fillWidth: true
        title: Localization.t("displayPage.bedtime")
        subtitle: BedtimeService.active ? Localization.t("displayPage.bedtime_on") : Localization.t("displayPage.bedtime_off")
        iconBg: Colors.md3.primary_container
        cardColor: Colors.md3.surface_container
        checked: BedtimeService.active
        onToggled: v => BedtimeService.toggle()
        MaterialIcon { name: "moon-stars" }
    }

    SectionCard {
        label: Localization.t("displayPage.bedtime")
        Layout.fillWidth: true

        SettingSwitch {
            label: Localization.t("displayPage.bedtime_dim")
            sublabel: Localization.t("displayPage.bedtime_dim_sub")
            checked: Config.bedtime.dimWallpaper
            onToggled: v => Config.update({
                    bedtime: Object.assign({}, Config.bedtime, {
                        dimWallpaper: v
                    })
                })
        }

        SettingSlider {
            label: Localization.t("displayPage.bedtime_dim_amount")
            sublabel: Localization.t("displayPage.bedtime_dim_amount_sub")
            enabled: Config.bedtime.dimWallpaper
            opacity: enabled ? 1.0 : 0.4
            from: 0
            to: 1
            stepSize: 0.05
            decimals: 2
            value: Config.bedtime.dimAmount
            onMoved: v => Config.update({
                    bedtime: Object.assign({}, Config.bedtime, {
                        dimAmount: v
                    })
                })
        }

        SettingSwitch {
            label: Localization.t("displayPage.bedtime_grayscale")
            sublabel: Localization.t("displayPage.bedtime_grayscale_sub")
            checked: Config.bedtime.grayscaleWallpaper
            onToggled: v => Config.update({
                    bedtime: Object.assign({}, Config.bedtime, {
                        grayscaleWallpaper: v
                    })
                })
        }

        SettingSwitch {
            label: Localization.t("displayPage.bedtime_grayscale_theme")
            sublabel: Localization.t("displayPage.bedtime_grayscale_theme_sub")
            checked: Config.bedtime.grayscaleTheme
            onToggled: v => Config.update({
                    bedtime: Object.assign({}, Config.bedtime, {
                        grayscaleTheme: v
                    })
                })
        }

        SettingSwitch {
            label: Localization.t("displayPage.bedtime_stop_video")
            sublabel: Localization.t("displayPage.bedtime_stop_video_sub")
            checked: Config.bedtime.stopVideo
            onToggled: v => Config.update({
                    bedtime: Object.assign({}, Config.bedtime, {
                        stopVideo: v
                    })
                })
        }

        SettingSwitch {
            isLast: true
            label: Localization.t("displayPage.bedtime_mute_sounds")
            sublabel: Localization.t("displayPage.bedtime_mute_sounds_sub")
            checked: Config.bedtime.muteSounds
            onToggled: v => Config.update({
                    bedtime: Object.assign({}, Config.bedtime, {
                        muteSounds: v
                    })
                })
        }
    }

    SectionCard {
        label: Localization.t("displayPage.brightness")
        Layout.fillWidth: true

        SettingSwitch {
            isLast: true
            label: Localization.t("displayPage.link_monitor_brightness")
            sublabel: Localization.t("displayPage.link_monitor_brightness_sub")
            checked: Config.linkMonitorBrightness
            onToggled: v => Config.update({
                linkMonitorBrightness: v
            })
        }
    }

    SectionCard {
        label: Localization.t("displayPage.blur_transparency")
        Layout.fillWidth: true

        SettingSwitch {
            id: blurSwitch
            label: Localization.t("displayPage.background_blur")
            sublabel: Localization.t("displayPage.apply_blur_effect_to_panels")
            checked: Config.blurEffects
            onToggled: v => Config.update({
                    blurEffects: v
                })
        }

        SettingSlider {
            label: Localization.t("displayPage.panel_opacity")
            sublabel: Localization.t("displayPage.overlay_opacity_of_panels_and")
            from: 0.1
            to: 1.0
            stepSize: 0.05
            decimals: 2
            value: Config.blurOpacity
            onMoved: v => Config.update({
                    blurOpacity: v
                })
        }

        SettingSwitch {
            label: Localization.t("displayPage.desktop_widget_blur")
            sublabel: Localization.t("displayPage.apply_blur_effect_to_desktop_widgets")
            enabled: Config.blurEffects
            opacity: enabled ? 1.0 : 0.4
            checked: Config.desktopWidgetsBlur
            onToggled: v => Config.update({
                    desktopWidgetsBlur: v
                })
            isLast: true
        }
    }

    SectionCard {
        label: Localization.t("barPage.icons")
        Layout.fillWidth: true

        SettingSwitch {
            label: Localization.t("displayPage.icon_tint")
            sublabel: Localization.t("displayPage.colorize_tray_dock_and_workspace")
            checked: Config.tintIcons
            onToggled: v => Config.update({
                tintIcons: v
            })
        }

        SettingSwitch {
            isLast: true
            label: Localization.t("displayPage.generic_launcher_icon")
            sublabel: Localization.t("displayPage.use_a_generic_icon_instead")
            checked: Config.genericLauncherIcon
            onToggled: v => Config.update({
                genericLauncherIcon: v
            })
        }
    }

    SectionCard {
        label: Localization.t("barPage.osd")
        Layout.fillWidth: true

        SettingSwitch {
            label: Localization.t("displayPage.follow_bar_position")
            sublabel: Localization.t("displayPage.snap_osd_to_the_same_edge")
            checked: Config.osdFollowBar
            onToggled: v => Config.update({
                osdFollowBar: v
            })
        }

        SettingChips {
            isLast: true
            label: Localization.t("backgroundPage.position")
            enabled: !Config.osdFollowBar
            opacity: enabled ? 1.0 : 0.4
            options: [
                {
                    label: Localization.t("backgroundPage.center"),
                    value: 0
                },
                {
                    label: Localization.t("backgroundPage.top"),
                    value: 1
                },
                {
                    label: Localization.t("backgroundPage.bottom"),
                    value: 3
                },
                {
                    label: Localization.t("barPage.left"),
                    value: 4
                },
                {
                    label: Localization.t("barPage.right"),
                    value: 2
                }
            ]
            currentValue: Config.osdPosition
            onSelected: v => Config.update({
                osdPosition: v
            })
        }
    }
}