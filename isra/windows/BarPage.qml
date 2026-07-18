pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import qs.style
import qs.icons
import qs.services
import qs.windows.components

PageBase {
    title: "Bar"
    subtitle: "Layout, media and tray"

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
        label: "Layout"
        Layout.fillWidth: true

        SettingChips {
            label: "Bar mode"
            sublabel: {
                switch (currentValue) {
                case 0:
                    return "Hugging screen edge";
                case 1:
                    return "Attached to screen edge";
                case 2:
                    return "Floating, detached";
                case 3:
                    return "Chromebook corners";
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
            label: "Position"
            options: [
                {
                    label: "Top",
                    value: 0,
                    icon: arrowUpwardComp
                },
                {
                    label: "Bottom",
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
            label: "Transparency"
            sublabel: "Background opacity level"
            options: [
                {
                    label: "Off",
                    value: 0
                },
                {
                    label: "Tinted",
                    value: 1
                },
                {
                    label: "Full",
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
            label: "Transparent pills"
            sublabel: "Remove pills background"
            checked: Config.bar.transparentPills
            onToggled: v => Config.update({
                bar: Object.assign({}, Config.bar, {
                    transparentPills: v
                })
            })
        }

        SettingSwitch {
            label: "Stacked sliders"
            sublabel: "Volume and brightness sliders arranged vertically"
            checked: Config.verticalQSSliders
            onToggled: v => Config.update({ verticalQSSliders: v })
        }
    }

    SectionCard {
        label: "Workspaces"
        Layout.fillWidth: true

        SettingSwitch {
            label: "Compact workspaces"
            sublabel: "Shrink workspaces to hide empty ones"
            checked: Config.workspaces.compact
            onToggled: v => Config.update({
                workspaces: Object.assign({}, Config.workspaces, {
                    compact: v
                })
            })
        }

        SettingSwitch {
            label: "Use icons"
            sublabel: "Show application icons for workspaces with active windows"
            checked: Config.workspaces.useIcons
            onToggled: v => Config.update({
                workspaces: Object.assign({}, Config.workspaces, {
                    useIcons: v
                })
            })
        }

        SettingChips {
            isLast: true
            label: "Workspace style"
            sublabel: {
                switch (currentValue) {
                case 0:
                    return "Numbers (1, 2, 3)";
                case 1:
                    return "Roman numerals (I, II, III)";
                case 2:
                    return "Kanji (一, 二, 三)";
                default:
                    return "";
                }
            }
            options: [
                {
                    label: "4",
                    value: 0
                },
                {
                    label: "IV",
                    value: 1
                },
                {
                    label: "四",
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
    }

    SectionCard {
        label: "Widget order"
        Layout.fillWidth: true

        WidgetOrderEditor {
            width: parent.width
            isLast: true
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
        label: "Media player"
        Layout.fillWidth: true

        SettingChips {
            label: "Player mode"
            sublabel: {
                switch (currentValue) {
                case 0:
                    return "Cover and title";
                case 1:
                    return "Cover only";
                case 2:
                    return "Title only";
                default:
                    return "";
                }
            }
            options: [
                {
                    label: "Both",
                    value: 0,
                    icon: queueMusicIconComp
                },
                {
                    label: "Cover",
                    value: 1,
                    icon: albumIconComp
                },
                {
                    label: "Title",
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
            label: "Spinning cover"
            sublabel: "Rotate album art while playing"
            checked: Config.bar.spinningCover
            onToggled: v => Config.update({
                bar: Object.assign({}, Config.bar, {
                    spinningCover: v
                })
            })
        }

        SettingSlider {
            isLast: true
            label: "Scroll speed"
            sublabel: "Media title carousel"
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
        label: "OSD"
        Layout.fillWidth: true

        SettingChips {
            isLast: true
            label: "Position"
            options: [
                {
                    label: "Center",
                    value: 0
                },
                {
                    label: "Top",
                    value: 1
                },
                {
                    label: "Bottom",
                    value: 3
                },
                {
                    label: "Left",
                    value: 4
                },
                {
                    label: "Right",
                    value: 2
                }
            ]
            currentValue: Config.osdPosition
            onSelected: v => Config.update({
                osdPosition: v
            })
        }
    }

    SectionCard {
        label: "Tray"
        Layout.fillWidth: true

        SettingSwitch {
            label: "Icon tint"
            sublabel: "Colorize tray icons with primary color"
            checked: Config.bar.tintTrayIcons
            onToggled: v => Config.update({
                bar: Object.assign({}, Config.bar, {
                    tintTrayIcons: v
                })
            })
        }

        SettingRow {
            isLast: true
            label: "Blacklist"
            sublabel: "Hidden from tray"

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
                    placeholder: "App name..."
                    onConfirmed: v => {
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
        label: "Toolbar"
        Layout.fillWidth: true

        SettingRow {
            isLast: true
            label: "Actions"
            sublabel: "Toggle individual toolbar actions"

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
                        label: "Screenshot"
                    },
                    {
                        key: "record",
                        label: "Record"
                    },
                    {
                        key: "cts",
                        label: "Circle To Search"
                    },
                    {
                        key: "ocr",
                        label: "OCR"
                    },
                    {
                        key: "songrec",
                        label: "Recognize Music"
                    },
                    {
                        key: "wallpaper",
                        label: "Wallpaper Picker"
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