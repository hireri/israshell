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
import Qt5Compat.GraphicalEffects

import qs.components
import qs.style
import qs.windows
import qs.services

ShellRoot {
    id: rootShell
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

    component BarZone: Row {
        id: zone
        property var itemNames: []
        property var registry
        property bool separators: false
        spacing: separators ? 0 : 12

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

        property var panelScreen
        property int windowHeight: 44

        width: radiusSize
        height: radiusSize
        clip: true

        readonly property bool useBlur: Config.blurEffects && !GameModeService.active && Config.bar.transparency === 1

        Item {
            id: cornerMaskSource
            anchors.fill: parent
            visible: false
            Rectangle {
                width: block.radiusSize * 4
                height: block.radiusSize * 4
                radius: block.radiusSize * 2
                color: "transparent"

                border.width: block.radiusSize
                border.color: "black"

                x: (block.type === 1) ? -block.radiusSize * 2 : -block.radiusSize
                y: block.flipped ? -block.radiusSize * 2 : -block.radiusSize
            }
        }

        Loader {
            id: cornerBlurLoader
            anchors.fill: parent
            active: block.useBlur
            sourceComponent: Item {
                id: cornerContentContainer
                anchors.fill: parent

                layer.enabled: !GameModeService.active
                layer.effect: OpacityMask {
                    maskSource: cornerMaskSource
                }

                Image {
                    id: cornerBlurSrc
                    width: block.panelScreen ? block.panelScreen.width : 0
                    height: block.panelScreen ? block.panelScreen.height : 0
                    
                    x: (block.type === 0) ? 0 : -( (block.panelScreen ? block.panelScreen.width : 0) - block.radiusSize )
                    y: block.flipped 
                        ? -( (block.panelScreen ? block.panelScreen.height : 0) - block.windowHeight - block.radiusSize )
                        : -block.windowHeight
                    
                    source: (WallpaperService.currentWallPreview || WallpaperService.currentWall) 
                        ? ("file://" + (WallpaperService.currentWallPreview || WallpaperService.currentWall)) 
                        : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: false
                    asynchronous: true
                }

                FastBlur {
                    id: cornerBlurEffect
                    x: cornerBlurSrc.x
                    y: cornerBlurSrc.y
                    width: cornerBlurSrc.width
                    height: cornerBlurSrc.height
                    source: cornerBlurSrc
                    radius: Config.blurRadius
                }

                Rectangle {
                    anchors.fill: parent
                    color: block.cornerColor
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            visible: !block.useBlur
            color: GameModeService.active ? "transparent" : block.cornerColor
            
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: cornerMaskSource
            }
        }
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: screenScope
            required property var modelData

            Background {
                id: wallpaperBackgroundItem
                modelData: screenScope.modelData
            }

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

            function isWidgetDisabled(id) {
                if (Config.bar.disabled.includes(id))
                    return true;

                if (id === "screencap") {
                    const blacklist = Config.screencap.blacklist;
                    return blacklist.includes("screenshot") &&
                           blacklist.includes("cts") &&
                           blacklist.includes("ocr") &&
                           blacklist.includes("songrec") &&
                           blacklist.includes("record");
                }

                return false;
            }

            readonly property var visibleBarLeft: Config.bar.left.filter(id => !isWidgetDisabled(id))
            readonly property var visibleBarRight: Config.bar.right.filter(id => !isWidgetDisabled(id))
            readonly property var visibleBarCenterItems: Config.bar.center.items.filter(id => !isWidgetDisabled(id))

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

                        Loader {
                            id: barBlurLoader
                            anchors.fill: parent
                            active: Config.blurEffects && !GameModeService.active && (Config.bar.transparency === 1 || (Config.bar.transparency === 2 && Config.bar.mode === 2))
                            
                            sourceComponent: Item {
                                id: barBlurContainer
                                anchors.fill: parent
                                clip: true

                                Item {
                                    id: barMaskSource
                                    anchors.fill: parent
                                    visible: false
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: barContainer.radius
                                        color: "black"
                                    }
                                }

                                layer.enabled: barContainer.radius > 0
                                layer.effect: OpacityMask {
                                    maskSource: barMaskSource
                                }

                                Item {
                                    id: blurSource
                                    anchors.fill: parent
                                    clip: true
                                    visible: false

                                    Image {
                                        id: barBlurSrc
                                        width: screenScope.modelData ? screenScope.modelData.width : 0
                                        height: screenScope.modelData ? screenScope.modelData.height : 0
                                        
                                        readonly property int leftMargin: (Config.bar.mode === 2) ? 12 : 0
                                        readonly property int topMargin: (Config.bar.mode === 2) && Config.bar.position === 0 ? 10 : 0
                                        readonly property int bottomMargin: (Config.bar.mode === 2) && Config.bar.position === 1 ? 10 : 0

                                        x: -leftMargin
                                        y: (Config.bar.position === 0) 
                                            ? -topMargin 
                                            : -( (screenScope.modelData ? screenScope.modelData.height : 0) - barContainer.height - bottomMargin)
                                        
                                        sourceSize.width: screenScope.modelData ? screenScope.modelData.width / 4 : 0
                                        sourceSize.height: screenScope.modelData ? screenScope.modelData.height / 4 : 0

                                        source: (WallpaperService.currentWallPreview || WallpaperService.currentWall) 
                                            ? ("file://" + (WallpaperService.currentWallPreview || WallpaperService.currentWall)) 
                                            : ""
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                    }
                                }

                                FastBlur {
                                    id: barBlurEffect
                                    anchors.fill: parent
                                    source: blurSource
                                    radius: Config.blurRadius
                                }
                            }
                        }

                        Rectangle {
                            id: barFadeGradient
                            anchors.fill: parent
                            radius: parent.radius

                            readonly property bool blurActive: Config.blurEffects && !GameModeService.active && (Config.bar.transparency === 1 || (Config.bar.transparency === 2 && Config.bar.mode === 2))
                            readonly property real dimAlpha: Config.blurOpacity

                            property color topColor: {
                                const solid = Config.bar.transparency ? Qt.alpha(Colors.md3.surface_container, dimAlpha) : Colors.md3.surface_container;
                                const fadeAtTop = Config.bar.position === 0;
                                if (Config.bar.transparency === 2) {
                                    if (!(Config.bar.mode === 2))
                                        return Qt.alpha(Colors.md3.background, 0);
                                    return fadeAtTop ? Qt.alpha(Colors.md3.background, 0.5) : Qt.alpha(Colors.md3.background, 0);
                                }
                                return solid;
                            }
                            property color bottomColor: {
                                const solid = Config.bar.transparency ? Qt.alpha(Colors.md3.surface_container, dimAlpha) : Colors.md3.surface_container;
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
                                itemNames: screenScope.visibleBarLeft
                            }

                            Item {
                                anchors.fill: parent

                                readonly property int centerAnchorIndex: screenScope.visibleBarCenterItems.indexOf(Config.bar.center.anchor)
                                readonly property bool centerUseAnchor: Config.bar.center.mode === "anchor" && centerAnchorIndex !== -1

                                BarZone {
                                    id: centerAutoZone
                                    anchors.centerIn: parent
                                    visible: !parent.centerUseAnchor
                                    registry: barWidgetComponents
                                    itemNames: !parent.centerUseAnchor ? screenScope.visibleBarCenterItems : []
                                }

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
                                    itemNames: parent.centerUseAnchor ? screenScope.visibleBarCenterItems.slice(0, parent.centerAnchorIndex) : []
                                }

                                BarZone {
                                    id: centerAfterZone
                                    anchors.left: centerAnchorLoader.right
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: parent.centerUseAnchor
                                    registry: barWidgetComponents
                                    itemNames: parent.centerUseAnchor ? screenScope.visibleBarCenterItems.slice(parent.centerAnchorIndex + 1) : []
                                }
                            }

                            BarZone {
                                id: rightZone
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                registry: barWidgetComponents
                                itemNames: screenScope.visibleBarRight
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

                property string barColor: Config.bar.transparency ? Qt.alpha(Colors.md3.surface_container, Config.blurOpacity) : Colors.md3.surface_container

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
                        panelScreen: screenScope.modelData
                        windowHeight: window.implicitHeight
                    }

                    HuggingCornerBlock {
                        type: 1
                        anchors.right: parent.right
                        anchors.top: parent.top
                        cornerColor: huggingWindow.barColor
                        radiusSize: huggingWindow.cornerRadius
                        panelScreen: screenScope.modelData
                        windowHeight: window.implicitHeight
                    }
                }
            }
        }
    }
}