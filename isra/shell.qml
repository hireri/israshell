import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

import qs.components
import qs.style
import qs.settings
import qs.services

ShellRoot {
    LazyLoader {
        loading: LockscreenService.locked
        Lockscreen {}
    }

    NotificationPopup {}
    VolumeOSD {}
    AppLauncher {}
    Screenshot {}

    readonly property var _updater: Updater

    Loader {
        id: settingsLoader
        active: false
        sourceComponent: SettingsWindow {}

        Connections {
            target: settingsLoader.item
            enabled: settingsLoader.item !== null
            function onVisibleChanged() {
                if (!settingsLoader.item.visible)
                    settingsLoader.active = false;
            }
        }
    }

    IpcHandler {
        target: "settings"
        function open(page: string): void {
            const map = {
                "overview": 0,
                "network": 1,
                "bar": 2,
                "clock": 3,
                "display": 4,
                "sound": 5,
                "immeria": 6,
                "system": 7
            };
            settingsLoader.active = true;
            settingsLoader.item.visible = true;
            const p = map[page];
            if (p !== undefined)
                settingsLoader.item.currentPage = p;
        }
    }

    IpcHandler {
        target: "gamemode"
        function toggle(): void {
            GameModeService.toggle();
        }
    }

    Logout {
        LogoutButton {
            command: "loginctl lock-session"
            keybind: Qt.Key_L
            text: "Lock"
            icon: "󰌾"
            containerColor: Colors.md3.primary_container
            contentColor: Colors.md3.on_primary_container
        }
        LogoutButton {
            command: "loginctl terminate-user $USER"
            keybind: Qt.Key_E
            text: "Logout"
            icon: "󰗽"
            containerColor: Colors.md3.primary_container
            contentColor: Colors.md3.on_primary_container
        }
        LogoutButton {
            command: "systemctl suspend | loginctl suspend"
            keybind: Qt.Key_S
            text: "Suspend"
            icon: "󰒲"
            containerColor: Colors.md3.primary_container
            contentColor: Colors.md3.on_primary_container
        }
        LogoutButton {
            command: "systemctl hibernate | loginctl hibernate"
            keybind: Qt.Key_H
            text: "Hibernate"
            icon: "󰜗"
            containerColor: Colors.md3.primary_container
            contentColor: Colors.md3.on_primary_container
        }
        LogoutButton {
            command: "systemctl poweroff | loginctl poweroff"
            keybind: Qt.Key_P
            text: "Shutdown"
            icon: "󰐥"
            containerColor: Colors.md3.primary
            contentColor: Colors.md3.on_primary
        }
        LogoutButton {
            command: "systemctl reboot | loginctl reboot"
            keybind: Qt.Key_R
            text: "Reboot"
            icon: "󰑐"
            containerColor: Colors.md3.primary
            contentColor: Colors.md3.on_primary
        }
    }

    GlobalShortcut {
        name: "openPowerMenu"
        description: "Toggle power menu overlay"
        onPressed: PowerMenuState.toggle()
    }

    Loader {
        active: Config.screenCorners
        sourceComponent: ScreenCorners {}
    }

    component HuggingCornerBlock: Item {
        id: block
        property int type: 0
        property string cornerColor
        property int radiusSize: 16
        property bool flipped: Config.barPosition === 1

        width: radiusSize
        height: radiusSize
        clip: true

        Rectangle {
            width: block.radiusSize * 4
            height: block.radiusSize * 4
            radius: block.radiusSize * 2
            color: "transparent"

            border.width: block.radiusSize
            border.color: GameModeService.active ? "transparent" : block.cornerColor

            x: (block.type === 1) ? -block.radiusSize * 2 : -block.radiusSize
            y: block.flipped ? -block.radiusSize * 2 : -block.radiusSize
        }
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: screenScope
            required property var modelData

            LazyLoader {
                activeAsync: Config.desktopClock

                Background {
                    modelData: screenScope.modelData
                }
            }

            PanelWindow {
                id: window
                property var modelData: screenScope.modelData
                screen: modelData

                property bool isMenuOpen: qsWidget.isOpen || wpWidget.isOpen || false

                WlrLayershell.namespace: "quickshell:bar"
                WlrLayershell.layer: isMenuOpen ? WlrLayer.Overlay : WlrLayer.Top

                anchors.top: Config.barPosition === 0
                anchors.bottom: Config.barPosition === 1
                anchors.left: true
                anchors.right: true

                implicitHeight: (Config.floatingBar ? 56 : 44)

                color: "transparent"

                exclusiveZone: Config.floatingBar ? 56 : 44

                Item {
                    anchors.fill: parent
                    anchors.leftMargin: Config.floatingBar ? 12 : 0
                    anchors.rightMargin: Config.floatingBar ? 12 : 0
                    anchors.topMargin: Config.floatingBar && Config.barPosition === 0 ? 10 : 0
                    anchors.bottomMargin: Config.floatingBar && Config.barPosition === 1 ? 10 : 0

                    Rectangle {
                        id: barContainer
                        anchors.fill: parent

                        radius: Config.floatingBar ? 22 : 0
                        color: Config.transparentBar ? Qt.alpha(Colors.md3.surface_container, 0.85) : Colors.md3.surface_container
                        border.width: Config.floatingBar ? 1 : 0
                        border.color: Config.transparentBar ? Qt.alpha(Colors.md3.outline_variant, 0.5) : Colors.md3.outline_variant

                        Item {
                            anchors.fill: parent
                            anchors.rightMargin: 8
                            anchors.leftMargin: 6

                            ActiveWindow {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Row {
                                anchors.centerIn: parent
                                spacing: 12

                                MediaPlayer {
                                    panelScreen: screenScope.modelData
                                }
                                Workspaces {
                                    panelWindow: window
                                }
                                BarClock {
                                    panelWindow: window
                                }

                                WallpaperPicker {
                                    id: wpWidget
                                    panelWindow: window
                                }
                            }

                            Row {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 12

                                ScreencapControls {}

                                TrayWidget {
                                    panelWindow: window
                                }
                                QuickSettings {
                                    id: qsWidget
                                    panelWindow: window
                                }
                            }
                        }
                    }
                }
            }

            PanelWindow {
                id: huggingWindow
                screen: modelData

                visible: !Config.floatingBar && Config.huggingBar

                anchors.top: Config.barPosition === 0
                anchors.bottom: Config.barPosition === 1
                anchors.left: true
                anchors.right: true

                margins.top: Config.barPosition === 0 ? window.implicitHeight : 0
                margins.bottom: Config.barPosition === 1 ? window.implicitHeight : 0

                property int cornerRadius: 26
                implicitHeight: cornerRadius

                color: "transparent"
                exclusionMode: ExclusionMode.Ignore

                WlrLayershell.namespace: "quickshell:huggingCorners"
                WlrLayershell.layer: window.isMenuOpen ? WlrLayer.Overlay : WlrLayer.Top

                mask: Region {}

                property string barColor: Config.transparentBar ? Qt.alpha(Colors.md3.surface_container, 0.85) : Colors.md3.surface_container

                HuggingCornerBlock {
                    type: 0
                    anchors.left: parent.left
                    anchors.top: parent.top
                    cornerColor: huggingWindow.barColor
                    radiusSize: huggingWindow.cornerRadius
                }

                HuggingCornerBlock {
                    type: 1
                    anchors.right: parent.right
                    anchors.top: parent.top
                    cornerColor: huggingWindow.barColor
                    radiusSize: huggingWindow.cornerRadius
                }
            }
        }
    }
}
