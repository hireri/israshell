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
    Osd {}

    AppLauncher { id: appLauncher }
    Screenshot {}
    AiAssistant {}

    property var wallpaperPanels: ({})
    property var quickSettingsPanels: ({})
    readonly property var appLauncherController: appLauncher

    property var currentOwningWindow: null

    onCurrentOwningWindowChanged: {
        if (currentOwningWindow)
            CompositorService.grabPanelFocus([currentOwningWindow]);
        else
            CompositorService.releasePanelFocus();
    }

    Connections {
        target: CompositorService
        function onPanelFocusCleared() {
            if (PanelService.current)
                PanelService.current.close();
        }
    }

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

            WallpaperLayer {
                modelData: screenScope.modelData
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
                controllerRegistry: screenScope.panelControllers
            }

            Loader {
                id: floatingDockLoader
                active: Config.floatingDock.enabled
                sourceComponent: FloatingDock { modelData: screenScope.modelData }
            }

            Component { id: workspacesComponent; Workspaces { panelWindow: window } }
            Component { id: mediaComponent; MediaPlayer { panelScreen: screenScope.modelData; panelWindow: window; controllerRegistry: screenScope.panelControllers } }
            Component { id: clockComponent; BarClock { panelWindow: window; controllerRegistry: screenScope.panelControllers } }
            Component { id: screencapComponent; ScreencapControls { panelWindow: window; controllerRegistry: screenScope.panelControllers } }
            Component { id: trayComponent; TrayWidget { panelWindow: window; controllerRegistry: screenScope.panelControllers } }
            Component { id: quicksettingsComponent; QuickSettings { panelWindow: window; registry: rootShell.quickSettingsPanels; controllerRegistry: screenScope.panelControllers } }
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

            property var panelControllers: ({})

            Component { id: calendarContentComponent; CalendarContent {} }
            Component { id: quickSettingsContentComponent; QuickSettingsContent {} }
            Component { id: mediaContentComponent; MediaPlayerContent {} }
            Component { id: wallpaperContentComponent; WallpaperPickerContent {} }
            Component { id: localSendContentComponent; LocalSendContent {} }
            Component { id: barMenuContentComponent; BarMenuContent {} }
            Component { id: trayMenuContentComponent; TrayMenuContent {} }
            Component { id: appLauncherContentComponent; AppLauncherContent {} }

            readonly property var panelContentComponents: ({
                    calendar: calendarContentComponent,
                    quicksettings: quickSettingsContentComponent,
                    media: mediaContentComponent,
                    wallpaper: wallpaperContentComponent,
                    localsend: localSendContentComponent,
                    barMenu: barMenuContentComponent,
                    trayMenu: trayMenuContentComponent,
                    launcher: appLauncherContentComponent
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

            readonly property int floatingGap: 10
            readonly property int barExclusiveZone: ((barMode === 2) ? 56 : (Config.bar.transparency === 2 && !GameModeService.active) ? 34 : 44)

            readonly property var visibleBarLeft: Config.bar.left.filter(id => !isWidgetDisabled(id))
            readonly property var visibleBarRight: Config.bar.right.filter(id => !isWidgetDisabled(id))
            readonly property var visibleBarCenterItems: Config.bar.center.items.filter(id => !isWidgetDisabled(id))

            PanelWindow {
                id: window
                property var modelData: screenScope.modelData
                screen: modelData

                property bool isMenuOpen: (PanelService.current?.excludeFromBarOverlay === true ? false : (leftZone.anyMenuOpen || rightZone.anyMenuOpen || centerAutoZone.anyMenuOpen || centerBeforeZone.anyMenuOpen || centerAfterZone.anyMenuOpen || (centerAnchorLoader.item && centerAnchorLoader.item.isOpen === true) || (PanelService.current !== null && PanelService.current.excludeFromBarOverlay !== true && (anyMergedPanelOpen || PanelService.currentScreen === null || PanelService.currentScreen === modelData)) || PanelService.currentMode !== null)) || false

                property bool shouldHide: LockscreenService.lockAnimating || LockscreenService.locked

                readonly property bool huggingCornersVisible: screenScope.barMode === 0 && Config.bar.transparency !== 2

                readonly property string currentPanelType: ((PanelService.current?.panelType ?? "") !== "" && PanelService.currentScreen === modelData) ? PanelService.current.panelType : ""
                readonly property bool ownsOpenMergedPanel: currentPanelType !== ""
                readonly property bool anyMergedPanelOpen: (PanelService.current?.panelType ?? "") !== ""

                onOwnsOpenMergedPanelChanged: {
                    if (ownsOpenMergedPanel)
                        rootShell.currentOwningWindow = window;
                    else if (rootShell.currentOwningWindow === window)
                        rootShell.currentOwningWindow = null;
                }

                function _hasMountedType(type) {
                    for (let i = 0; i < mountedPanelTypes.count; i++) {
                        if (mountedPanelTypes.get(i).type === type)
                            return true;
                    }
                    return false;
                }

                function _syncMountedPanel() {
                    const t = window.currentPanelType;
                    if (t !== "" && !window._hasMountedType(t))
                        mountedPanelTypes.append({ type: t });
                }

                onCurrentPanelTypeChanged: Qt.callLater(window._syncMountedPanel)

                WlrLayershell.namespace: "quickshell:bar"
                WlrLayershell.layer: isMenuOpen ? WlrLayer.Overlay : WlrLayer.Top
                WlrLayershell.keyboardFocus: ownsOpenMergedPanel ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

                BackgroundEffect.blurRegion: Config.blurAllowed() ? fullBlurRegion : null

                Region {
                    id: fullBlurRegion
                    width: window.width
                    height: window.height
                }

                property rect dockHoverRect: Qt.rect(0, 0, 0, 0)

                Region {
                    id: barOnlyMask
                    x: visualContent.x + barContainer.x
                    y: visualContent.y + barContainer.y
                    width: barContainer.width
                    height: barContainer.height

                    Region {
                        x: window.dockHoverRect.x
                        y: window.dockHoverRect.y
                        width: window.dockHoverRect.width
                        height: window.dockHoverRect.height
                    }
                }
                mask: anyMergedPanelOpen ? null : barOnlyMask

                anchors.top: true
                anchors.bottom: true
                anchors.left: true
                anchors.right: true

                implicitHeight: (screenScope.barMode === 2) ? 56 : 44
                readonly property real barHeight: implicitHeight
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                visible: true

                IdleInhibitor {
                    enabled: CaffeineService.active
                    window: window
                }

                Item {
                    id: visualContent
                    z: 1
                    anchors.left: parent.left
                    anchors.right: parent.right
                    readonly property real edgeGap: (screenScope.barMode === 2) ? screenScope.floatingGap : 0
                    height: window.barHeight - edgeGap
                    anchors.leftMargin: (screenScope.barMode === 2) ? 12 : 0
                    anchors.rightMargin: (screenScope.barMode === 2) ? 12 : 0
                    clip: screenScope.barMode === 3

                    readonly property real topY: edgeGap
                    readonly property real bottomY: parent.height - height - edgeGap

                    function rebindY() {
                        const side = state;
                        y = Qt.binding(() => side === "top" ? visualContent.topY : visualContent.bottomY);
                    }

                    state: Config.bar.position === 0 ? "top" : "bottom"
                    states: [
                        State { name: "top"; PropertyChanges { visualContent.y: visualContent.topY } },
                        State { name: "bottom"; PropertyChanges { visualContent.y: visualContent.bottomY } }
                    ]
                    transitions: [
                        Transition {
                            from: "top"; to: "bottom"
                            SequentialAnimation {
                                ParallelAnimation {
                                    NumberAnimation { target: visualContent; property: "y"; to: -visualContent.height; duration: 150; easing.type: Easing.InCubic }
                                    NumberAnimation { target: huggingCornersWrapper; property: "swapMaskProgress"; to: -1; duration: 150; easing.type: Easing.InCubic }
                                }
                                PropertyAction { target: visualContent; property: "y"; value: window.height }
                                PropertyAction { target: huggingCornersWrapper; property: "activeSide"; value: 1 }
                                ParallelAnimation {
                                    NumberAnimation { target: visualContent; property: "y"; to: visualContent.bottomY; duration: 150; easing.type: Easing.OutCubic }
                                    NumberAnimation { target: huggingCornersWrapper; property: "swapMaskProgress"; to: 0; duration: 150; easing.type: Easing.OutCubic }
                                }
                                ScriptAction { script: Qt.callLater(visualContent.rebindY) }
                            }
                        },
                        Transition {
                            from: "bottom"; to: "top"
                            SequentialAnimation {
                                ParallelAnimation {
                                    NumberAnimation { target: visualContent; property: "y"; to: window.height; duration: 150; easing.type: Easing.InCubic }
                                    NumberAnimation { target: huggingCornersWrapper; property: "swapMaskProgress"; to: -1; duration: 150; easing.type: Easing.InCubic }
                                }
                                PropertyAction { target: visualContent; property: "y"; value: -visualContent.height }
                                PropertyAction { target: huggingCornersWrapper; property: "activeSide"; value: 0 }
                                ParallelAnimation {
                                    NumberAnimation { target: visualContent; property: "y"; to: visualContent.topY; duration: 150; easing.type: Easing.OutCubic }
                                    NumberAnimation { target: huggingCornersWrapper; property: "swapMaskProgress"; to: 0; duration: 150; easing.type: Easing.OutCubic }
                                }
                                ScriptAction { script: Qt.callLater(visualContent.rebindY) }
                            }
                        }
                    ]

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
                                controllerRegistry: screenScope.panelControllers
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

                Loader {
                    z: 2
                    anchors.fill: parent
                    active: true
                    sourceComponent: ScreenCorners { screen: screenScope.modelData }
                }

                Item {
                    id: overlayContent
                    anchors.fill: parent

                    MouseArea {
                        anchors.fill: parent
                        enabled: window.anyMergedPanelOpen
                        onClicked: {
                            if (PanelService.current)
                                PanelService.current.close();
                        }
                    }

                    Item {
                        id: huggingCornersWrapper
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: huggingCornerRadius

                        y: activeSide === 0
                            ? (visualContent.y + visualContent.height)
                            : (visualContent.y - huggingCornerRadius)

                        readonly property int huggingCornerRadius: 26

                        property real swapMaskProgress: 0
                        property real modeMaskProgress: window.huggingCornersVisible ? 0 : -1
                        Behavior on modeMaskProgress {
                            NumberAnimation { duration: 200; easing.type: Easing.InOutCubic }
                        }
                        readonly property real maskProgress: Math.max(-1, swapMaskProgress + modeMaskProgress)

                        property int activeSide: 0
                        Component.onCompleted: activeSide = Config.bar.position

                        property string barColor: GameModeService.active ? "transparent" : Qt.alpha(Colors.md3.surface_container, Config.blurOpacity)

                        opacity: window.shouldHide ? 0 : 1
                        Behavior on opacity {
                            NumberAnimation { duration: 200; easing.type: Easing.InOutCubic }
                        }

                        CornerBlock {
                            type: huggingCornersWrapper.activeSide === 1 ? 2 : 0
                            anchors.left: parent.left
                            anchors.top: parent.top
                            cornerColor: huggingCornersWrapper.barColor
                            cornerRadius: huggingCornersWrapper.huggingCornerRadius
                            maskProgress: huggingCornersWrapper.maskProgress
                        }

                        CornerBlock {
                            type: huggingCornersWrapper.activeSide === 1 ? 3 : 1
                            anchors.right: parent.right
                            anchors.top: parent.top
                            cornerColor: huggingCornersWrapper.barColor
                            cornerRadius: huggingCornersWrapper.huggingCornerRadius
                            maskProgress: huggingCornersWrapper.maskProgress
                        }
                    }

                    ListModel {
                        id: mountedPanelTypes
                    }

                    Repeater {
                        id: panelSlotRepeater
                        model: mountedPanelTypes

                        Loader {
                            id: panelSlotLoader
                            required property string type
                            anchors.fill: parent
                            active: true
                            sourceComponent: screenScope.panelContentComponents[type] ?? null

                            onLoaded: {
                                item.controller = (panelSlotLoader.type === "launcher" ? rootShell.appLauncherController : screenScope.panelControllers[panelSlotLoader.type]) ?? null;
                            }

                            readonly property bool owned: panelSlotLoader.type === window.currentPanelType
                            onOwnedChanged: {
                                if (panelSlotLoader.owned)
                                    unmountTimer.stop();
                                else
                                    unmountTimer.restart();
                            }
                            Component.onCompleted: {
                                if (!panelSlotLoader.owned)
                                    unmountTimer.restart();
                            }

                            Timer {
                                id: unmountTimer
                                interval: (panelSlotLoader.item && panelSlotLoader.item.controller === PanelService.current) ? 0 : 450
                                onTriggered: {
                                    for (let i = 0; i < mountedPanelTypes.count; i++) {
                                        if (mountedPanelTypes.get(i).type === panelSlotLoader.type) {
                                            mountedPanelTypes.remove(i);
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Loader {
                active: Config.floatingDock.exclusiveZone && (floatingDockLoader.item?.hasContent ?? false)
                sourceComponent: PanelWindow {
                    screen: screenScope.modelData

                    readonly property int dockEdge: Config.floatingDock.edge
                    readonly property bool sideEdge: dockEdge === 2 || dockEdge === 3
                    readonly property int thickness: Config.floatingDockThickness

                    WlrLayershell.namespace: "quickshell:floatingDockSpacer"
                    WlrLayershell.layer: WlrLayer.Bottom

                    anchors.top: dockEdge === 0 || sideEdge
                    anchors.bottom: dockEdge === 1 || sideEdge
                    anchors.left: dockEdge === 2 || !sideEdge
                    anchors.right: dockEdge === 3 || !sideEdge

                    implicitWidth: sideEdge ? thickness : 0
                    implicitHeight: sideEdge ? 0 : thickness

                    exclusionMode: ExclusionMode.Normal
                    exclusiveZone: thickness

                    color: "transparent"
                    mask: Region {}
                    visible: true
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
        }
    }
}