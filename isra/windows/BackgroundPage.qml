pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.style
import qs.services
import qs.icons
import qs.windows.components
import qs.components
import Quickshell.Widgets

PageBase {
    title: Localization.t("settingsWindow.background")
    subtitle: Localization.t("settingsWindow.effects_wallpaper_widgets")

    Component.onDestruction: if (gridHover.hovered) EditModeService.settingsPanelClosed()

    function titleCase(str) {
        return str.split(/[-_ ]+/).map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(" ");
    }

    Component {
        id: spritePreviewIcon
        Image {
            property var modelData: null
            width: 32
            height: 32
            smooth: false
            mipmap: false
            fillMode: Image.Stretch
            source: modelData ? ("file://" + Quickshell.shellDir + "/assets/sprites/" + modelData.value + ".gif") : ""
            sourceClipRect: Qt.rect(3 * 32, 3 * 32, 32, 32)
        }
    }

    SectionCard {
        id: gridCard
        label: Localization.t("backgroundPage.desktop_grid")
        Layout.fillWidth: true

        function updateGrid(patch) {
            Config.update({
                desktopGrid: Object.assign({}, Config.desktopGrid, patch)
            });
        }

        SettingSlider {
            label: Localization.t("backgroundPage.grid_cell_size")
            sublabel: Localization.t("backgroundPage.size_of_one_grid_cell")
            from: 30
            to: 100
            stepSize: 2
            unit: "px"
            value: Config.desktopGrid?.cellSize ?? 50
            onMoved: v => gridCard.updateGrid({ cellSize: Math.round(v) })
        }

        SettingSlider {
            label: Localization.t("backgroundPage.grid_gutter")
            sublabel: Localization.t("backgroundPage.gap_between_cells")
            from: 0
            to: 24
            stepSize: 1
            unit: "px"
            value: Config.desktopGrid?.gutter ?? 8
            onMoved: v => gridCard.updateGrid({ gutter: Math.round(v) })
        }

        SettingSlider {
            label: Localization.t("backgroundPage.grid_margin")
            sublabel: Localization.t("backgroundPage.space_around_the_edge_of")
            isLast: true
            from: 0
            to: 96
            stepSize: 2
            unit: "px"
            value: Config.desktopGrid?.margin ?? 24
            onMoved: v => gridCard.updateGrid({ margin: Math.round(v) })
        }

        HoverHandler {
            id: gridHover
            onHoveredChanged: gridHover.hovered ? EditModeService.settingsPanelOpened() : EditModeService.settingsPanelClosed()
        }
    }

    SectionCard {
        label: Localization.t("backgroundPage.wallpaper")
        Layout.fillWidth: true

        SettingSwitch {
            label: Localization.t("backgroundPage.use_awww")
            sublabel: Localization.t("backgroundPage.delegate_wallpaper_to_awww_instead")
            checked: Config.useAwww
            onToggled: v => Config.update({ useAwww: v })
        }

        SettingSelect {
            label: Localization.t("backgroundPage.transition")
            sublabel: Localization.t("backgroundPage.effect_used_when_switching_wallpapers")
            options: [
                { label: Localization.t("backgroundPage.crossfade"), value: "crossfade" },
                { label: Localization.t("backgroundPage.directional_wipe"), value: "wipe" },
                { label: Localization.t("backgroundPage.circle_reveal"), value: "circle" },
                { label: Localization.t("backgroundPage.random"), value: "random" }
            ]
            currentValue: Config.background.transitionType
            onSelected: v => Config.update({
                background: Object.assign({}, Config.background, { transitionType: v })
            })
        }

        SettingSlider {
            label: Localization.t("backgroundPage.transition_duration")
            sublabel: Localization.t("backgroundPage.how_long_the_wallpaper_transition")
            from: 150
            to: 2000
            stepSize: 50
            unit: "ms"
            value: Config.background.transitionDuration
            onMoved: v => Config.update({
                background: Object.assign({}, Config.background, { transitionDuration: Math.round(v) })
            })
        }

        SettingSlider {
            label: Localization.t("backgroundPage.transition_displacement")
            sublabel: Localization.t("backgroundPage.how_far_the_wallpapers_drift_or_grow")
            from: 0
            to: 100
            stepSize: 1
            unit: "%"
            value: Config.background.transitionDisplacement
            onMoved: v => Config.update({
                background: Object.assign({}, Config.background, { transitionDisplacement: Math.round(v) })
            })
        }

        SettingSlider {
            label: Localization.t("backgroundPage.wipe_direction")
            sublabel: Localization.t("backgroundPage.angle_both_wallpapers_move_during_a_wipe")
            enabled: Config.background.transitionType === "wipe" || Config.background.transitionType === "random"
            opacity: enabled ? 1.0 : 0.4
            from: 0
            to: 359
            stepSize: 1
            unit: "°"
            value: Config.background.wipeAngle
            onMoved: v => Config.update({
                background: Object.assign({}, Config.background, { wipeAngle: Math.round(v) })
            })
        }

        SettingSwitch {
            label: Localization.t("backgroundPage.reverse_circle_wipe")
            sublabel: Localization.t("backgroundPage.shrink_the_old_wallpaper_away_instead_of_growing_the_new_one_in")
            enabled: Config.background.transitionType === "circle" || Config.background.transitionType === "random"
            opacity: enabled ? 1.0 : 0.4
            checked: Config.background.circleReverse
            onToggled: v => Config.update({
                background: Object.assign({}, Config.background, { circleReverse: v })
            })
        }

        SettingSwitch {
            label: Localization.t("backgroundPage.allow_nsfw")
            sublabel: Localization.t("backgroundPage.allow_nsfw_sub")
            checked: Config.allowNsfw
            onToggled: v => Config.update({ allowNsfw: v })
        }

        SettingSwitch {
            label: Localization.t("backgroundPage.video_sound")
            sublabel: Localization.t("backgroundPage.video_sound_sub")
            checked: Config.background.videoSound
            onToggled: v => Config.update({
                background: Object.assign({}, Config.background, { videoSound: v })
            })
        }

        SettingSlider {
            label: Localization.t("backgroundPage.video_volume")
            sublabel: Localization.t("backgroundPage.video_volume_sub")
            enabled: Config.background.videoSound
            opacity: enabled ? 1.0 : 0.4
            from: 0
            to: 100
            stepSize: 5
            unit: "%"
            value: Math.round((Config.background.videoVolume ?? 0.5) * 100)
            onMoved: v => Config.update({
                background: Object.assign({}, Config.background, { videoVolume: Math.round(v) / 100 })
            })
        }

        SettingSwitch {
            isLast: true
            label: Localization.t("backgroundPage.mute_on_media")
            sublabel: Localization.t("backgroundPage.mute_on_media_sub")
            enabled: Config.background.videoSound
            opacity: enabled ? 1.0 : 0.4
            checked: Config.background.muteOnMedia
            onToggled: v => Config.update({
                background: Object.assign({}, Config.background, { muteOnMedia: v })
            })
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

    HeroCard {
        Layout.fillWidth: true
        title: Localization.t("backgroundPage.audio_visualizer")
        subtitle: Config.cava.enabled ? Localization.t("backgroundPage.active_bars").arg(Config.cava.bars) : Localization.t("networkPage.off")
        iconBg: Colors.md3.primary_container
        cardColor: Colors.md3.surface_container
        checked: Config.cava.enabled
        onToggled: v => Config.update({
                cava: Object.assign({}, Config.cava, {
                    enabled: v
                })
            })
        
        MaterialIcon {
            name: "equalizer"
            iconSize: 22
            color: Colors.md3.primary
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: layoutInner.implicitHeight + 32
        radius: 20
        color: (Config.dim(Colors.md3.surface_container))

        ColumnLayout {
            id: layoutInner
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                margins: 16
            }
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Rectangle {
                    id: btnCurve
                    Layout.fillWidth: true
                    height: 34
                    radius: 17
                    topRightRadius: active ? 17 : 8
                    bottomRightRadius: active ? 17 : 8

                    Behavior on topRightRadius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    Behavior on bottomRightRadius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                    readonly property bool active: Config.cava.renderType === "curve"
                    readonly property color contentColor: active
                        ? Colors.md3.on_primary
                        : (curveMouse.containsMouse ? Colors.md3.on_surface : Colors.md3.on_surface_variant)

                    color: active
                        ? Colors.md3.primary
                        : (curveMouse.containsMouse ? (Config.dim(Colors.md3.surface_container_highest)) : (Config.dim(Colors.md3.surface_container_high)))

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        topRightRadius: parent.topRightRadius
                        bottomRightRadius: parent.bottomRightRadius
                        color: curveMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                        visible: btnCurve.active
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 6

                        MaterialIcon {
                            name: "earthquake"
                            iconSize: 14
                            color: btnCurve.contentColor
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: Localization.t("backgroundPage.curve")
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: btnCurve.contentColor
                            Behavior on color { ColorAnimation { duration: 120 } }
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: curveMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: Config.update({
                                cava: Object.assign({}, Config.cava, { renderType: "curve" })
                            })
                    }
                }

                Rectangle {
                    id: btnBars
                    Layout.fillWidth: true
                    height: 34
                    radius: active ? 17 : 8

                    Behavior on radius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                    readonly property bool active: Config.cava.renderType === "bars"
                    readonly property color contentColor: active
                        ? Colors.md3.on_primary
                        : (barsMouse.containsMouse ? Colors.md3.on_surface : Colors.md3.on_surface_variant)

                    color: active
                        ? Colors.md3.primary
                        : (barsMouse.containsMouse ? (Config.dim(Colors.md3.surface_container_highest)) : (Config.dim(Colors.md3.surface_container_high)))

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: barsMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                        visible: btnBars.active
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 6

                        MaterialIcon {
                            name: "bar-chart"
                            iconSize: 14
                            color: btnBars.contentColor
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: Localization.t("backgroundPage.bars")
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: btnBars.contentColor
                            Behavior on color { ColorAnimation { duration: 120 } }
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: barsMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: Config.update({
                                cava: Object.assign({}, Config.cava, { renderType: "bars" })
                            })
                    }
                }

                Rectangle {
                    id: btnBlocks
                    Layout.fillWidth: true
                    height: 34
                    radius: 17
                    topLeftRadius: active ? 17 : 8
                    bottomLeftRadius: active ? 17 : 8

                    Behavior on topLeftRadius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    Behavior on bottomLeftRadius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                    readonly property bool active: Config.cava.renderType === "blocks"
                    readonly property color contentColor: active
                        ? Colors.md3.on_primary
                        : (blocksMouse.containsMouse ? Colors.md3.on_surface : Colors.md3.on_surface_variant)

                    color: active
                        ? Colors.md3.primary
                        : (blocksMouse.containsMouse ? (Config.dim(Colors.md3.surface_container_highest)) : (Config.dim(Colors.md3.surface_container_high)))

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        topLeftRadius: parent.topLeftRadius
                        bottomLeftRadius: parent.bottomLeftRadius
                        color: blocksMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                        visible: btnBlocks.active
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 6

                        MaterialIcon {
                            name: "grid-view"
                            iconSize: 14
                            color: btnBlocks.contentColor
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: Localization.t("backgroundPage.blocks")
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: btnBlocks.contentColor
                            Behavior on color { ColorAnimation { duration: 120 } }
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: blocksMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: Config.update({
                                cava: Object.assign({}, Config.cava, { renderType: "blocks" })
                            })
                    }
                }
            }

            ClippingRectangle {
                id: singlePreview
                Layout.fillWidth: true
                Layout.preferredHeight: 180
                color: (Config.dim(Colors.md3.surface_container_high))
                radius: 12

                Image {
                    id: wallView
                    source: WallpaperService.currentWall !== "" ? "file://" + WallpaperService.currentWallPreview : ""
                    asynchronous: true
                    smooth: true
                    mipmap: true
                    cache: true
                    fillMode: Image.PreserveAspectCrop
                    anchors.fill: parent
                    visible: source !== ""
                    sourceSize: Qt.size(480, 270)
                }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.alpha(Colors.md3.surface, 0.4)
                    visible: wallView.visible
                }

                CavaVisualizer {
                    id: previewVisualizer
                    anchors.fill: parent
                    overrideMaxHeight: 120
                    useMock: true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Colors.md3.outline_variant
                opacity: 0.15
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                ColorRoleStrip {
                    label: Localization.t("backgroundPage.main_color")
                    selected: Config.cava.color
                    onPicked: role => Config.update({
                            cava: Object.assign({}, Config.cava, { color: role })
                        })
                }

                ColorRoleStrip {
                    label: Localization.t("backgroundPage.accent_color")
                    selected: Config.cava.colorAlt
                    fallback: Colors.md3.error
                    onPicked: role => Config.update({
                            cava: Object.assign({}, Config.cava, { colorAlt: role })
                        })
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Colors.md3.outline_variant
                opacity: 0.15
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
                currentValue: Config.cava.position
                onSelected: v => Config.update({
                        cava: Object.assign({}, Config.cava, {
                            position: v
                        })
                    })
            }

            SettingChips {
                label: Localization.t("backgroundPage.layout")
                sublabel: Localization.t("backgroundPage.how_bars_are_arranged_across")
                options: [
                    {
                        label: Localization.t("backgroundPage.mono"),
                        value: "mono"
                    },
                    {
                        label: Localization.t("backgroundPage.edges"),
                        value: "edges"
                    },
                    {
                        label: Localization.t("backgroundPage.center"),
                        value: "center"
                    }
                ]
                currentValue: Config.cava.layout
                onSelected: v => Config.update({
                        cava: Object.assign({}, Config.cava, {
                            layout: v
                        })
                    })
            }

            SettingChips {
                label: Localization.t("backgroundPage.curve_type")
                sublabel: Config.cava.renderType === "curve" ? Localization.t("backgroundPage.smoothing_applied_to_the_curve") : Localization.t("backgroundPage.requires_curve_render_type")
                enabled: Config.cava.renderType === "curve"
                opacity: enabled ? 1.0 : 0.4
                options: [
                    {
                        label: Localization.t("backgroundPage.smooth"),
                        value: "smooth"
                    },
                    {
                        label: Localization.t("backgroundPage.sharp"),
                        value: "sharp"
                    }
                ]
                currentValue: Config.cava.curveType
                onSelected: v => Config.update({
                        cava: Object.assign({}, Config.cava, {
                            curveType: v
                        })
                    })
            }

            SettingSwitch {
                label: Localization.t("backgroundPage.fill")
                sublabel: Localization.t("backgroundPage.draw_a_filled_gradient_area")
                checked: Config.cava.drawFill
                onToggled: v => Config.update({
                        cava: Object.assign({}, Config.cava, {
                            drawFill: v
                        })
                    })
            }

            SettingSwitch {
                label: Localization.t("backgroundPage.stroke")
                sublabel: Localization.t("backgroundPage.draw_an_outline_along_the")
                checked: Config.cava.drawStroke
                onToggled: v => Config.update({
                        cava: Object.assign({}, Config.cava, {
                            drawStroke: v
                        })
                    })
            }

            SettingChips {
                label: Localization.t("backgroundPage.color_style")
                sublabel: Localization.t("backgroundPage.how_colors_are_applied_across")
                options: [
                    {
                        label: Localization.t("backgroundPage.solid"),
                        value: "solid"
                    },
                    {
                        label: Localization.t("backgroundPage.loudness"),
                        value: "loudness"
                    },
                    {
                        label: Localization.t("backgroundPage.gradient_v"),
                        value: "gradient-v"
                    },
                    {
                        label: Localization.t("backgroundPage.gradient_h"),
                        value: "gradient-h"
                    }
                ]
                currentValue: Config.cava.colorStyle
                onSelected: v => Config.update({
                        cava: Object.assign({}, Config.cava, {
                            colorStyle: v
                        })
                    })
            }

            SettingSlider {
                label: Localization.t("backgroundPage.bars")
                sublabel: Localization.t("backgroundPage.number_of_frequency_bars_rendered")
                from: 8
                to: 100
                stepSize: 2
                value: Config.cava.bars
                onMoved: v => Config.update({
                        cava: Object.assign({}, Config.cava, {
                            bars: Math.round(v)
                        })
                    })
            }

            SettingSlider {
                label: Localization.t("backgroundPage.height")
                sublabel: Localization.t("backgroundPage.height_of_the_visualizer_in")
                from: 40
                to: 1200
                unit: "px"
                value: Config.cava.height
                onMoved: v => Config.update({
                        cava: Object.assign({}, Config.cava, {
                            height: Math.round(v)
                        })
                    })
            }

            SettingSlider {
                label: Localization.t("backgroundPage.opacity")
                sublabel: Localization.t("backgroundPage.overlay_opacity_of_the_visualizer")
                from: 0.05
                to: 1.0
                stepSize: 0.05
                decimals: 2
                value: Config.cava.opacity
                onMoved: v => Config.update({
                        cava: Object.assign({}, Config.cava, {
                            opacity: v
                        })
                    })
                isLast: true
            }
        }
    }

    SectionCard {
        label: Localization.t("backgroundPage.neko")
        Layout.fillWidth: true

        SettingSwitch {
            label: Localization.t("backgroundPage.enable")
            sublabel: CompositorService.hasCapability("cursorPosition") ? "A cursor-chasing cat on your desktop" : "Requires Hyprland (cursor position isn't available on " + CompositorService.backendName + ")"
            enabled: CompositorService.hasCapability("cursorPosition")
            opacity: enabled ? 1.0 : 0.4
            checked: Config.neko.enabled
            onToggled: v => Config.update({
                    neko: Object.assign({}, Config.neko, {
                        enabled: v
                    })
                })
        }

        SettingSwitch {
            label: Localization.t("backgroundPage.sit_above_windows")
            sublabel: Localization.t("backgroundPage.render_on_top_of_windows")
            enabled: CompositorService.hasCapability("cursorPosition")
            opacity: enabled ? 1.0 : 0.4
            checked: Config.neko.onTop
            onToggled: v => Config.update({
                    neko: Object.assign({}, Config.neko, {
                        onTop: v
                    })
                })
        }

        SettingSelect {
            label: Localization.t("backgroundPage.sprite")
            sublabel: Localization.t("backgroundPage.appearance_of_the_cat")
            enabled: CompositorService.hasCapability("cursorPosition")
            opacity: enabled ? 1.0 : 0.4
            options: NekoService.spriteNames.map(name => ({
                label: titleCase(name),
                value: name,
                icon: spritePreviewIcon
            }))
            currentValue: Config.neko.sprite
            onSelected: v => Config.update({
                    neko: Object.assign({}, Config.neko, {
                        sprite: v
                    })
                })
        }

        SettingSlider {
            label: Localization.t("backgroundPage.size")
            sublabel: Localization.t("backgroundPage.rendered_size_of_the_sprite")
            from: 32
            to: 160
            stepSize: 4
            unit: "px"
            enabled: CompositorService.hasCapability("cursorPosition")
            opacity: enabled ? 1.0 : 0.4
            value: Config.neko.size
            onMoved: v => Config.update({
                    neko: Object.assign({}, Config.neko, {
                        size: Math.round(v)
                    })
                })
        }

        SettingSlider {
            label: Localization.t("backgroundPage.speed")
            sublabel: Localization.t("backgroundPage.how_fast_it_chases_the")
            from: 4
            to: 30
            stepSize: 1
            enabled: CompositorService.hasCapability("cursorPosition")
            opacity: enabled ? 1.0 : 0.4
            value: Config.neko.speed
            onMoved: v => Config.update({
                    neko: Object.assign({}, Config.neko, {
                        speed: Math.round(v)
                    })
                })
            isLast: true
        }
    }
}
