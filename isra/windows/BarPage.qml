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
        HuggingBarIcon {
            iconSize: 16
        }
    }
    Component {
        id: straightIconComp
        StraightBarIcon {
            iconSize: 16
        }
    }
    Component {
        id: floatingIconComp
        FloatingBarIcon {
            iconSize: 16
        }
    }
    Component {
        id: albumIconComp
        AlbumIcon {
            iconSize: 16
        }
    }
    Component {
        id: queueMusicIconComp
        QueueMusicIcon {
            iconSize: 16
        }
    }
    Component {
        id: menuIconComp
        MenuIcon {
            iconSize: 16
        }
    }
    Component {
        id: arrowUpwardComp
        ArrowUpwardIcon {
            iconSize: 16
        }
    }
    Component {
        id: arrowDownwardComp
        ArrowDownwardIcon {
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
            label: "Compact workspaces"
            sublabel: "Shrink workspaces to hide empty ones"
            checked: Config.bar.compactWorkspaces
            onToggled: v => Config.update({
                bar: Object.assign({}, Config.bar, {
                    compactWorkspaces: v
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
        label: "Screen capture"
        Layout.fillWidth: true

        SettingSwitch {
            label: "Enable screen capture"
            sublabel: "Expose capture actions in the bar"
            checked: Config.screencapEnabled
            onToggled: v => Config.update({
                screencapEnabled: v
            })
        }

        SettingRow {
            isLast: true
            label: "Actions"
            sublabel: "Toggle individual capture actions"
            enabled: Config.screencapEnabled
            opacity: Config.screencapEnabled ? 1 : 0.45

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