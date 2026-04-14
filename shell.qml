//@ pragma UseQApplication
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

import qs.components
import qs.style
import qs.services

ShellRoot {

    NotificationPopup {}
    VolumeOSD {}
    AppLauncher {}

    Variants {
        model: Quickshell.screens
        WallpaperClock {}
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
            command: "systemctl suspend"
            keybind: Qt.Key_S
            text: "Suspend"
            icon: "󰒲"
            containerColor: Colors.md3.primary_container
            contentColor: Colors.md3.on_primary_container
        }
        LogoutButton {
            command: "systemctl hibernate"
            keybind: Qt.Key_H
            text: "Hibernate"
            icon: "󰜗"
            containerColor: Colors.md3.primary_container
            contentColor: Colors.md3.on_primary_container
        }
        LogoutButton {
            command: "systemctl poweroff"
            keybind: Qt.Key_P
            text: "Shutdown"
            icon: "󰐥"
            containerColor: Colors.md3.primary
            contentColor: Colors.md3.on_primary
        }
        LogoutButton {
            command: "systemctl reboot"
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

        width: radiusSize
        height: radiusSize
        clip: true

        Rectangle {
            width: block.radiusSize * 4
            height: block.radiusSize * 4
            radius: block.radiusSize * 2
            color: "transparent"

            border.width: block.radiusSize
            border.color: block.cornerColor

            x: (block.type === 1) ? -block.radiusSize * 2 : -block.radiusSize
            y: -block.radiusSize
        }
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: screenScope
            required property var modelData

            PanelWindow {
                id: window
                property var modelData: screenScope.modelData
                screen: modelData

                property bool isMenuOpen: qsWidget.isOpen || wpWidget.isOpen || false

                WlrLayershell.namespace: "quickshell:bar"
                WlrLayershell.layer: isMenuOpen ? WlrLayer.Overlay : WlrLayer.Top

                anchors.top: true
                anchors.left: true
                anchors.right: true

                implicitHeight: (Config.floatingBar ? 56 : 44)

                color: "transparent"

                exclusiveZone: Config.floatingBar ? 56 : 44

                Item {
                    anchors.fill: parent
                    anchors.leftMargin: Config.floatingBar ? 12 : 0
                    anchors.rightMargin: Config.floatingBar ? 12 : 0
                    anchors.topMargin: Config.floatingBar ? 10 : 0

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
                                BarClock {}

                                WallpaperPicker {
                                    id: wpWidget
                                    panelWindow: window
                                }
                            }

                            Row {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 12

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

                anchors.top: true
                anchors.left: true
                anchors.right: true
                margins.top: window.implicitHeight

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
