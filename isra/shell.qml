//@ pragma ShellId israshell
//@ pragma AppId israshell
//@ pragma Env QS_NO_RELOAD_POPUP = 1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma DefaultEnv QT_LOGGING_RULES = quickshell.dbus.properties=false
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=7500

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick

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
    AiAssistant {}

    property var wallpaperPanels: ({})
    property var quickSettingsPanels: ({})

    IpcHandlers {
        settingsLoader: settingsLoader
        wallpaperPanels: rootShell.wallpaperPanels
        quickSettingsPanels: rootShell.quickSettingsPanels
    }

    readonly property var _updater: Updater

    Loader {
        id: settingsLoader
        active: false
        sourceComponent: SettingsWindow {}

        Connections {
            target: settingsLoader.item
            enabled: settingsLoader.item !== null
            function onVisibleChanged() {
                if (!settingsLoader.item.visible) {
                    settingsLoader.active = false;
                }
            }
        }
    }

    Logout {}

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
                readonly property bool isOpen: slotLoader.item && (slotLoader.item.isOpen === true || slotLoader.item.popupWindowVisible === true)

                Row {
                    id: row
                    spacing: spacing

                    Loader {
                        id: slotLoader
                        sourceComponent: zone.registry[delegateRoot.modelData] || null

                        onStatusChanged: {
                            if (status === Loader.Error) {
                                console.log("[BarZone Error] Failed loading component:", delegateRoot.modelData);
                            }
                        }
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
                            color: Qt.alpha(Colors.md3.outline, 0.85)
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

            readonly property int barMode: {
                if (Config.bar.transparency === 2) {
                    return Config.bar.mode === 2 ? 2 : 0;
                }
                return Config.bar.mode;
            }

            Background {
                id: wallpaperBackgroundItem
                modelData: screenScope.modelData
            }

            Loader {
                active: Config.neko.enabled && Config.neko.onTop
                    && !(LockscreenService.locked || LockscreenService.lockAnimating || LockscreenService.lockVisualActive || LockscreenService.unlockAnimating)
                    && CompositorService.hasCapability("cursorPosition")
                sourceComponent: NekoOverlay {
                    modelData: screenScope.modelData
                }
            }

            WallpaperPicker {
                panelWindow: window
                registry: rootShell.wallpaperPanels
            }

            Loader {
                active: Config.floatingDock.enabled
                sourceComponent: FloatingDock { modelData: screenScope.modelData }
            }

            Component { id: workspacesComponent; Workspaces { panelWindow: window } }
            Component { id: mediaComponent; MediaPlayer { panelScreen: screenScope.modelData } }
            Component { id: clockComponent; BarClock { panelWindow: window } }
            Component { id: screencapComponent; ScreencapControls { panelWindow: window } }
            Component { id: trayComponent; TrayWidget { panelWindow: window } }
            Component { id: quicksettingsComponent; QuickSettings { panelWindow: window; registry: rootShell.quickSettingsPanels } }
            Component { id: sysMonitorComponent; SysMonitor { panelWindow: window } }

            readonly property var barWidgetComponents: Object.assign({}, WidgetService.componentMap, {
                    workspaces: workspacesComponent,
                    media: mediaComponent,
                    clock: clockComponent,
                    screencap: screencapComponent,
                    tray: trayComponent,
                    quicksettings: quicksettingsComponent,
                    sysMonitor: sysMonitorComponent
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
                           blacklist.includes("record") &&
                           blacklist.includes("localsend") &&
                           blacklist.includes("wallpaper") &&
                           blacklist.includes("colorpicker");
                }

                return false;
            }

            readonly property int barExclusiveZone: ((barMode === 2) ? 56 : Config.bar.transparency === 2 & !GameModeService.active ? 34 : 44)

            readonly property var visibleBarLeft: Config.bar.left.filter(id => !isWidgetDisabled(id))
            readonly property var visibleBarRight: Config.bar.right.filter(id => !isWidgetDisabled(id))
            readonly property var visibleBarCenterItems: Config.bar.center.items.filter(id => !isWidgetDisabled(id))

            PanelWindow {
                id: window
                property var modelData: screenScope.modelData
                screen: modelData

                property bool isMenuOpen: (leftZone.anyMenuOpen || rightZone.anyMenuOpen || centerAutoZone.anyMenuOpen || centerBeforeZone.anyMenuOpen || centerAfterZone.anyMenuOpen || (centerAnchorLoader.item && centerAnchorLoader.item.isOpen === true) || (PanelService.current !== null && PanelService.current.excludeFromBarOverlay !== true && (PanelService.currentScreen === null || PanelService.currentScreen === modelData)) || PanelService.currentMode !== null) || false

                property bool shouldHide: LockscreenService.lockAnimating || LockscreenService.locked

                WlrLayershell.namespace: "quickshell:bar"
                WlrLayershell.layer: isMenuOpen ? WlrLayer.Overlay : WlrLayer.Top

                readonly property bool blurEnabled: Config.blurAllowed() && (Config.bar.transparency === 1 || (Config.bar.transparency === 2 && !Config.bar.transparentPills))
                BackgroundEffect.blurRegion: blurEnabled ? barBlurRegion : null

                Region {
                    id: barBlurRegion
                    item: barContainer
                }

                anchors.top: Config.bar.position === 0
                anchors.bottom: Config.bar.position === 1
                anchors.left: true
                anchors.right: true

                implicitHeight: ((screenScope.barMode === 2) ? 56 : 44)
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                visible: true

                Item {
                    id: visualContent
                    anchors.fill: parent
                    anchors.leftMargin: (screenScope.barMode === 2) ? 12 : 0
                    anchors.rightMargin: (screenScope.barMode === 2) ? 12 : 0
                    anchors.topMargin: (screenScope.barMode === 2) && Config.bar.position === 0 ? 10 : 0
                    anchors.bottomMargin: (screenScope.barMode === 2) && Config.bar.position === 1 ? 10 : 0
                    clip: screenScope.barMode === 3

                    opacity: window.shouldHide ? 0 : 1

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.InOutCubic
                        }
                    }

                    Rectangle {
                        id: barContainer
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: (screenScope.barMode === 3) ? parent.height * 2 : parent.height
                        y: (screenScope.barMode === 3 && Config.bar.position === 0) ? -parent.height : 0

                        radius: (screenScope.barMode === 3) ? 0 : (screenScope.barMode === 2) ? 22 : 0
                        bottomLeftRadius: (screenScope.barMode === 3 && Config.bar.position === 0) ? height / 4 : radius
                        bottomRightRadius: (screenScope.barMode === 3 && Config.bar.position === 0) ? height / 4 : radius
                        topLeftRadius: (screenScope.barMode === 3 && Config.bar.position === 1) ? height / 4 : radius
                        topRightRadius: (screenScope.barMode === 3 && Config.bar.position === 1) ? height / 4 : radius

                        border.width: (screenScope.barMode === 2) ? 1 : 0
                        border.color: Qt.alpha(Colors.md3.outline_variant, 0.5)
                        Behavior on border.color {
                            ColorAnimation { duration: 200; easing.type: Easing.InOutCubic }
                        }

                        readonly property real dimAlpha: Config.blurOpacity

                        function edgeFade(isTopStop) {
                            if (Config.bar.transparency !== 2)
                                return Qt.alpha(Colors.md3.surface_container, dimAlpha);
                            if (screenScope.barMode !== 2)
                                return Qt.alpha(Colors.md3.background, 0);
                            const fadeAtTop = Config.bar.position === 0;
                            return isTopStop === fadeAtTop ? Qt.alpha(Colors.md3.background, 0.5) : Qt.alpha(Colors.md3.background, 0);
                        }
                        property color topColor: edgeFade(true)
                        property color bottomColor: edgeFade(false)

                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop {
                                position: 0.0
                                color: barContainer.topColor
                                Behavior on color {
                                    ColorAnimation { duration: 200; easing.type: Easing.InOutCubic }
                                }
                            }
                            GradientStop {
                                position: 1.0
                                color: barContainer.bottomColor
                                Behavior on color {
                                    ColorAnimation { duration: 200; easing.type: Easing.InOutCubic }
                                }
                            }
                        }

                        Item {
                            anchors.fill: parent
                            
                            anchors.topMargin: (screenScope.barMode === 3 && Config.bar.position === 0) ? parent.height / 2 : 0
                            anchors.bottomMargin: (screenScope.barMode === 3 && Config.bar.position === 1) ? parent.height / 2 : 0
                            
                            anchors.rightMargin: (screenScope.barMode === 3) ? 5 : 8
                            anchors.leftMargin: (screenScope.barMode === 3) ? 5 : 6

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
                id: barSpacer
                screen: screenScope.modelData

                WlrLayershell.namespace: "quickshell:barSpacer"
                WlrLayershell.layer: WlrLayer.Bottom

                anchors.top: Config.bar.position === 0
                anchors.bottom: Config.bar.position === 1
                anchors.left: true
                anchors.right: true

                implicitHeight: screenScope.barExclusiveZone
                exclusionMode: ExclusionMode.Normal
                exclusiveZone: screenScope.barExclusiveZone

                color: "transparent"
                mask: Region {}
                visible: true
            }

            PanelWindow {
                id: huggingWindow
                screen: modelData

                visible: screenScope.barMode === 0 && Config.bar.transparency !== 2

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

                property string barColor: Qt.alpha(Colors.md3.surface_container, Config.blurOpacity)

                readonly property bool blurEnabled: Config.blurAllowed(huggingWindow.visible)
                BackgroundEffect.blurRegion: blurEnabled ? huggingBlurRegion : null

                Region {
                    id: huggingBlurRegion
                    Region { item: leftCorner }
                    Region { item: rightCorner }
                }

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: parent.height

                    opacity: window.shouldHide ? 0 : 1
                    Behavior on opacity {
                        NumberAnimation { duration: 200; easing.type: Easing.InOutCubic }
                    }

                    HuggingCornerBlock {
                        id: leftCorner
                        type: 0
                        anchors.left: parent.left
                        anchors.top: parent.top
                        cornerColor: huggingWindow.barColor
                        radiusSize: huggingWindow.cornerRadius
                        panelScreen: screenScope.modelData
                        windowHeight: window.implicitHeight
                    }

                    HuggingCornerBlock {
                        id: rightCorner
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