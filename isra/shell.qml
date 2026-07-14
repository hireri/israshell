//@ pragma ShellId israshell
//@ pragma AppId israshell
//@ pragma Env QS_NO_RELOAD_POPUP = 1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma DefaultEnv QT_LOGGING_RULES = quickshell.dbus.properties=false
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=7500

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

import qs.components
import qs.style
import qs.windows
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
                "locale": 6,
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

    // Renders a list of named bar widgets in order, resolved against a
    // name -> Component registry. `separators` draws a dot between adjacent
    // items (used for the right zone); it hides itself around a widget that
    // hides itself (e.g. the tray with no icons).
    component BarZone: Row {
        id: zone
        property var itemNames: []
        property var registry
        property bool separators: false
        spacing: separators ? 0 : 12

        // NOTE: relies on widgets that have a menu (WallpaperPicker,
        // QuickSettings) exposing an `isOpen` property. Widgets without one
        // just read as undefined/false here.
        readonly property bool anyMenuOpen: {
            for (let i = 0; i < rep.count; i++) {
                const slot = rep.itemAt(i);
                if (slot && slot.isOpen)
                    return true;
            }
            return false;
        }

        Repeater {
            id: rep
            model: zone.itemNames

            delegate: Item {
                id: delegateRoot
                required property string modelData
                required property int index
                implicitWidth: row.implicitWidth
                implicitHeight: row.implicitHeight
                readonly property bool isOpen: slotLoader.item && slotLoader.item.isOpen === true

                Row {
                    id: row
                    spacing: spacing

                    Loader {
                        id: slotLoader
                        sourceComponent: zone.registry[delegateRoot.modelData] || null
                    }

                    Item {
                        implicitHeight: 32
                        implicitWidth: Config.bar.transparentPills ? 18 : 12
                        visible: zone.separators && delegateRoot.index < zone.itemNames.length - 1 && slotLoader.item && slotLoader.item.visible !== false
                        Behavior on implicitWidth {
                            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: 4
                            height: 4
                            radius: 2
                            color: Config.bar.transparency ? Qt.alpha(Colors.md3.outline, 0.85) : Colors.md3.outline
                            opacity: Config.bar.transparentPills ? 1 : 0
                            Behavior on opacity {
                                NumberAnimation { duration: 250 }
                            }
                        }
                    }
                }
            }
        }
    }

    component HuggingCornerBlock: Item {
        id: block
        property int type: 0
        property string cornerColor
        property int radiusSize: 16
        property bool flipped: Config.bar.position === 1

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

            Background {
                modelData: screenScope.modelData
            }

            // name -> Component registry for bar widgets. Add new widgets
            // here; `Config.bar.left/center.items/right` reference them by
            // these string keys.
            readonly property var barWidgetComponents: ({
                    activeWindow: activeWindowComponent,
                    workspaces: workspacesComponent,
                    media: mediaComponent,
                    clock: clockComponent,
                    wallpaper: wallpaperComponent,
                    screencap: screencapComponent,
                    tray: trayComponent,
                    quicksettings: quicksettingsComponent
                })

            Component { id: activeWindowComponent; ActiveWindow {} }
            Component { id: workspacesComponent; Workspaces { panelWindow: window } }
            Component { id: mediaComponent; MediaPlayer { panelScreen: screenScope.modelData } }
            Component { id: clockComponent; BarClock { panelWindow: window } }
            Component { id: wallpaperComponent; WallpaperPicker { panelWindow: window } }
            Component { id: screencapComponent; ScreencapControls {} }
            Component { id: trayComponent; TrayWidget { panelWindow: window } }
            Component { id: quicksettingsComponent; QuickSettings { panelWindow: window } }

            PanelWindow {
                id: window
                property var modelData: screenScope.modelData
                screen: modelData

                property bool isMenuOpen: (leftZone.anyMenuOpen || rightZone.anyMenuOpen || centerAutoZone.anyMenuOpen || centerBeforeZone.anyMenuOpen || centerAfterZone.anyMenuOpen || (centerAnchorLoader.item && centerAnchorLoader.item.isOpen === true)) || false

                property bool shouldHide: LockscreenService.lockAnimating || LockscreenService.locked

                WlrLayershell.namespace: "quickshell:bar"
                WlrLayershell.layer: isMenuOpen ? WlrLayer.Overlay : WlrLayer.Top

                anchors.top: Config.bar.position === 0
                anchors.bottom: Config.bar.position === 1
                anchors.left: true
                anchors.right: true

                implicitHeight: ((Config.bar.mode === 2) ? 56 : 44)
                color: "transparent"
                exclusiveZone: ((Config.bar.mode === 2) ? 56 : Config.bar.transparency === 2 & !GameModeService.active ? 34 : 44)
                visible: true

                Item {
                    id: visualContent
                    anchors.fill: parent
                    anchors.leftMargin: (Config.bar.mode === 2) ? 12 : 0
                    anchors.rightMargin: (Config.bar.mode === 2) ? 12 : 0
                    anchors.topMargin: (Config.bar.mode === 2) && Config.bar.position === 0 ? 10 : 0
                    anchors.bottomMargin: (Config.bar.mode === 2) && Config.bar.position === 1 ? 10 : 0

                    opacity: window.shouldHide ? 0 : 1

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.InOutCubic
                        }
                    }

                    Rectangle {
                        id: barContainer
                        anchors.fill: parent
                        radius: (Config.bar.mode === 2) ? 22 : 0

                        border.width: (Config.bar.mode === 2) ? 1 : 0
                        border.color: Config.bar.transparency ? Qt.alpha(Colors.md3.outline_variant, 0.5) : Colors.md3.outline_variant
                        Behavior on border.color {
                            ColorAnimation { duration: 200; easing.type: Easing.InOutCubic }
                        }
                        color: "transparent"

                        Rectangle {
                            id: barFadeGradient
                            anchors.fill: parent
                            radius: parent.radius

                            property color topColor: {
                                const solid = Config.bar.transparency ? Qt.alpha(Colors.md3.surface_container, 0.85) : Colors.md3.surface_container;
                                const fadeAtTop = Config.bar.position === 0;
                                if (Config.bar.transparency === 2) {
                                    if (!(Config.bar.mode === 2))
                                        return Qt.alpha(Colors.md3.background, 0);
                                    return fadeAtTop ? Qt.alpha(Colors.md3.background, 0.5) : Qt.alpha(Colors.md3.background, 0);
                                }
                                return solid;
                            }
                            property color bottomColor: {
                                const solid = Config.bar.transparency ? Qt.alpha(Colors.md3.surface_container, 0.85) : Colors.md3.surface_container;
                                const fadeAtTop = Config.bar.position === 0;
                                if (Config.bar.transparency === 2) {
                                    if (!(Config.bar.mode === 2))
                                        return Qt.alpha(Colors.md3.background, 0);
                                    return fadeAtTop ? Qt.alpha(Colors.md3.background, 0) : Qt.alpha(Colors.md3.background, 0.5);
                                }
                                return solid;
                            }

                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop {
                                    position: 0.0
                                    color: barFadeGradient.topColor
                                    Behavior on color {
                                        ColorAnimation { duration: 200; easing.type: Easing.InOutCubic }
                                    }
                                }
                                GradientStop {
                                    position: 1.0
                                    color: barFadeGradient.bottomColor
                                    Behavior on color {
                                        ColorAnimation { duration: 200; easing.type: Easing.InOutCubic }
                                    }
                                }
                            }
                        }

                        Item {
                            anchors.fill: parent
                            anchors.rightMargin: 8
                            anchors.leftMargin: 6

                            BarMenu {
                                id: barContextMenu
                                panelWindow: window
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.RightButton
                                onClicked: mouse => {
                                    var globalPos = mapToGlobal(mouse.x, mouse.y);
                                    barContextMenu.open(globalPos);
                                }
                            }

                            BarZone {
                                id: leftZone
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                registry: barWidgetComponents
                                itemNames: Config.bar.left
                            }

                            Item {
                                anchors.fill: parent

                                readonly property int centerAnchorIndex: Config.bar.center.items.indexOf(Config.bar.center.anchor)
                                readonly property bool centerUseAnchor: Config.bar.center.mode === "anchor" && centerAnchorIndex !== -1

                                // mode: "auto" (or "anchor" with a missing/renamed anchor widget)
                                BarZone {
                                    id: centerAutoZone
                                    anchors.centerIn: parent
                                    visible: !parent.centerUseAnchor
                                    registry: barWidgetComponents
                                    itemNames: !parent.centerUseAnchor ? Config.bar.center.items : []
                                }

                                // mode: "anchor" - one widget pinned dead-center, the rest
                                // gather to its left/right in config order.
                                Loader {
                                    id: centerAnchorLoader
                                    anchors.centerIn: parent
                                    active: parent.centerUseAnchor
                                    sourceComponent: parent.centerUseAnchor ? barWidgetComponents[Config.bar.center.anchor] : null
                                }

                                BarZone {
                                    id: centerBeforeZone
                                    anchors.right: centerAnchorLoader.left
                                    anchors.rightMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: parent.centerUseAnchor
                                    registry: barWidgetComponents
                                    itemNames: parent.centerUseAnchor ? Config.bar.center.items.slice(0, parent.centerAnchorIndex) : []
                                }

                                BarZone {
                                    id: centerAfterZone
                                    anchors.left: centerAnchorLoader.right
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: parent.centerUseAnchor
                                    registry: barWidgetComponents
                                    itemNames: parent.centerUseAnchor ? Config.bar.center.items.slice(parent.centerAnchorIndex + 1) : []
                                }
                            }

                            BarZone {
                                id: rightZone
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                registry: barWidgetComponents
                                itemNames: Config.bar.right
                                separators: true
                            }
                        }
                    }
                }
            }

            PanelWindow {
                id: huggingWindow
                screen: modelData

                visible: Config.bar.mode === 0 && Config.bar.transparency !== 2

                anchors.top: Config.bar.position === 0
                anchors.bottom: Config.bar.position === 1
                anchors.left: true
                anchors.right: true

                margins.top: Config.bar.position === 0 ? window.implicitHeight : 0
                margins.bottom: Config.bar.position === 1 ? window.implicitHeight : 0

                property int cornerRadius: 26
                implicitHeight: cornerRadius

                color: "transparent"
                exclusionMode: ExclusionMode.Ignore

                WlrLayershell.namespace: "quickshell:huggingCorners"
                WlrLayershell.layer: window.isMenuOpen ? WlrLayer.Overlay : WlrLayer.Top

                mask: Region {}

                property string barColor: Config.bar.transparency ? Qt.alpha(Colors.md3.surface_container, 0.85) : Colors.md3.surface_container

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: parent.height

                    opacity: window.shouldHide ? 0 : 1
                    Behavior on opacity {
                        NumberAnimation { duration: 200; easing.type: Easing.InOutCubic }
                    }

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
}
