pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.components.gameoverlay
import qs.icons
import qs.services
import qs.style
import qs.windows.components
import "../components/gameoverlay/crosshair.js" as Crosshair

PageBase {
    id: page

    pageId: "gameoverlay"
    title: Localization.t("gameOverlayPage.title")
    subtitle: Localization.t("gameOverlayPage.subtitle")

    readonly property var xh: GameOverlayService.crosshair

    Component.onDestruction: GameOverlayService.previewReset()

    component PreviewHover: HoverHandler {
        onHoveredChanged: hovered ? GameOverlayService.previewOpened() : GameOverlayService.previewClosed()
    }

    component LineSection: SectionCard {
        id: section

        property string kind
        readonly property var line: GameOverlayService.crosshair[section.kind]

        Layout.fillWidth: true

        PreviewHover {}

        SettingSwitch {
            label: Localization.t("gameOverlayPage.show_lines")
            checked: section.line.on
            onToggled: v => GameOverlayService.editCrosshair(s => s[section.kind].on = v)
        }

        SettingSlider {
            label: Localization.t("gameOverlayPage.length")
            from: 0
            to: 30
            stepSize: 1
            unit: "px"
            value: section.line.length
            onMoved: v => GameOverlayService.editCrosshair(s => s[section.kind].length = v)
        }

        SettingSwitch {
            label: Localization.t("gameOverlayPage.separate_vertical")
            sublabel: Localization.t("gameOverlayPage.separate_vertical_sub")
            checked: section.line.unbind
            onToggled: v => GameOverlayService.editCrosshair(s => s[section.kind].unbind = v)
        }

        SettingSlider {
            visible: section.line.unbind
            label: Localization.t("gameOverlayPage.vertical_length")
            from: 0
            to: 30
            stepSize: 1
            unit: "px"
            value: section.line.vlength
            onMoved: v => GameOverlayService.editCrosshair(s => s[section.kind].vlength = v)
        }

        SettingSlider {
            label: Localization.t("gameOverlayPage.thickness")
            from: 0
            to: 10
            stepSize: 1
            unit: "px"
            value: section.line.thickness
            onMoved: v => GameOverlayService.editCrosshair(s => s[section.kind].thickness = v)
        }

        SettingSlider {
            label: Localization.t("gameOverlayPage.offset")
            sublabel: Localization.t("gameOverlayPage.offset_sub")
            from: 0
            to: 30
            stepSize: 1
            unit: "px"
            value: section.line.offset
            onMoved: v => GameOverlayService.editCrosshair(s => s[section.kind].offset = v)
        }

        SettingSlider {
            isLast: true
            label: Localization.t("gameOverlayPage.opacity")
            from: 0
            to: 1
            stepSize: 0.05
            decimals: 2
            value: section.line.opacity
            onMoved: v => GameOverlayService.editCrosshair(s => s[section.kind].opacity = v)
        }
    }

    SectionCard {
        label: Localization.t("gameOverlayPage.general")
        Layout.fillWidth: true

        SettingSwitch {
            label: Localization.t("gameOverlayPage.zoom_animation")
            sublabel: Localization.t("gameOverlayPage.zoom_animation_sub")
            checked: Config.gameOverlay.zoomAnimation
            onToggled: v => GameOverlayService.setOption("zoomAnimation", v)
        }

        SettingSwitch {
            label: Localization.t("gameOverlayPage.darken_screen")
            sublabel: Localization.t("gameOverlayPage.darken_screen_sub")
            checked: Config.gameOverlay.darkenScreen
            onToggled: v => GameOverlayService.setOption("darkenScreen", v)
        }

        SettingSlider {
            isLast: true
            label: Localization.t("gameOverlayPage.pinned_opacity")
            sublabel: Localization.t("gameOverlayPage.pinned_opacity_sub")
            from: 0.2
            to: 1
            stepSize: 0.05
            decimals: 2
            value: Config.gameOverlay.clickthroughOpacity
            onMoved: v => GameOverlayService.setOption("clickthroughOpacity", v)
        }
    }

    SectionCard {
        label: Localization.t("gameOverlayPage.crosshair")
        Layout.fillWidth: true

        PreviewHover {}

        SettingActions {
            label: Localization.t("gameOverlayPage.code")
            sublabel: Localization.t("gameOverlayPage.code_sub")

            ActionButton {
                icon: "copy"
                label: Localization.t("gameOverlayPage.copy_code")
                onClicked: Quickshell.execDetached(["wl-copy", "--", Config.gameOverlay.crosshairCode])
            }

            ActionButton {
                label: Localization.t("gameOverlayPage.paste_code")
                onClicked: pasteProc.running = true
            }

            ActionButton {
                icon: "restart"
                label: Localization.t("gameOverlayPage.reset")
                onClicked: GameOverlayService.setCrosshair(Crosshair.serialize(Crosshair.defaults()))
            }
        }

        Process {
            id: pasteProc
            command: ["wl-paste", "--no-newline"]
            stdout: StdioCollector {
                onStreamFinished: if (text.trim() !== "")
                    GameOverlayService.setCrosshair(text.trim())
            }
        }

        SettingSwatches {
            label: Localization.t("gameOverlayPage.color")
            swatches: Crosshair.presets
            custom: true
            current: page.xh.colorIndex
            onPicked: i => GameOverlayService.editCrosshair(s => s.colorIndex = i)
        }

        SettingInput {
            isLast: true
            visible: page.xh.colorIndex === 8
            label: Localization.t("gameOverlayPage.custom_color")
            sublabel: Localization.t("gameOverlayPage.custom_color_sub")
            fieldWidth: 110
            value: page.xh.custom
            onCommitted: v => {
                const hex = v.trim().replace(/^#/, "");
                if (/^[0-9a-fA-F]{6}$/.test(hex))
                    GameOverlayService.editCrosshair(s => s.custom = hex);
            }
        }
    }

    SectionCard {
        label: Localization.t("gameOverlayPage.outline")
        Layout.fillWidth: true

        PreviewHover {}

        SettingSwitch {
            label: Localization.t("gameOverlayPage.outline_on")
            sublabel: Localization.t("gameOverlayPage.outline_on_sub")
            checked: page.xh.outline.on
            onToggled: v => GameOverlayService.editCrosshair(s => s.outline.on = v)
        }

        SettingSlider {
            label: Localization.t("gameOverlayPage.thickness")
            from: 0
            to: 6
            stepSize: 1
            unit: "px"
            value: page.xh.outline.thickness
            onMoved: v => GameOverlayService.editCrosshair(s => s.outline.thickness = v)
        }

        SettingSlider {
            isLast: true
            label: Localization.t("gameOverlayPage.opacity")
            from: 0
            to: 1
            stepSize: 0.05
            decimals: 2
            value: page.xh.outline.opacity
            onMoved: v => GameOverlayService.editCrosshair(s => s.outline.opacity = v)
        }
    }

    SectionCard {
        label: Localization.t("gameOverlayPage.center_dot")
        Layout.fillWidth: true

        PreviewHover {}

        SettingSwitch {
            label: Localization.t("gameOverlayPage.dot_on")
            checked: page.xh.dot.on
            onToggled: v => GameOverlayService.editCrosshair(s => s.dot.on = v)
        }

        SettingSlider {
            label: Localization.t("gameOverlayPage.size")
            from: 0
            to: 12
            stepSize: 1
            unit: "px"
            value: page.xh.dot.size
            onMoved: v => GameOverlayService.editCrosshair(s => s.dot.size = v)
        }

        SettingSlider {
            isLast: true
            label: Localization.t("gameOverlayPage.opacity")
            from: 0
            to: 1
            stepSize: 0.05
            decimals: 2
            value: page.xh.dot.opacity
            onMoved: v => GameOverlayService.editCrosshair(s => s.dot.opacity = v)
        }
    }

    LineSection {
        label: Localization.t("gameOverlayPage.inner_lines")
        kind: "inner"
    }

    LineSection {
        label: Localization.t("gameOverlayPage.outer_lines")
        kind: "outer"
    }
}
