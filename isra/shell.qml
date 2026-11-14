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
import QtQuick.Shapes

import qs.components
import qs.style
import "services/meltPath.js" as MeltPath
import qs.windows
import qs.services

ShellRoot {
    id: rootShell

    LazyLoader {
        loading: LockscreenService.locked
        Lockscreen {}
    }

    NotificationPopup { barWindows: rootShell.barWindows }
    Osd {}

    AppLauncher { id: appLauncher }
    Overview { id: overview }
    WindowSwitcher { id: windowSwitcher }
    Screenshot {}
    AiAssistant {}

    property var barWindows: ({})
    property var wallpaperPanels: ({})
    property var quickSettingsPanels: ({})
    readonly property var appLauncherController: appLauncher
    readonly property var overviewController: overview
    readonly property var globalPanelControllers: ({ launcher: appLauncher, overview: overview, switcher: windowSwitcher })

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
        systemLoader: systemLoader
        wallpaperPanels: rootShell.wallpaperPanels
        quickSettingsPanels: rootShell.quickSettingsPanels
    }

    readonly property int frameThickness: Config.bar.mode === 4 && Config.bar.transparency !== 2 ? 10 : 0
    Component.onCompleted: SettingsRegistry.init(SettingsPages.pages)

    readonly property var _updater: Updater
    readonly property var _fedd: FeddService
    readonly property var _calendarReminders: CalendarReminders
    readonly property var _screenTime: ScreenTimeService

    Loader {
        id: settingsLoader
        active: false
        sourceComponent: SettingsWindow {}

        Connections {
            target: settingsLoader.item
            enabled: settingsLoader.item !== null
            function onVisibleChanged() {
                if (!settingsLoader.item.visible) {
                    Qt.callLater(() => settingsLoader.active = false);
                }
            }
        }
    }

    Loader {
        id: systemLoader
        active: false
        sourceComponent: SystemWindow {}

        Connections {
            target: systemLoader.item
            enabled: systemLoader.item !== null
            function onVisibleChanged() {
                if (!systemLoader.item.visible) {
                    Qt.callLater(() => systemLoader.active = false);
                }
            }
        }
    }

    Logout {}
    PolkitDialog {}
    GameOverlay {}
    VoiceIndicator {}

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
                visible: slotLoader.item?.wantsSpace !== false
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

            CavaWindow {
                modelData: screenScope.modelData
            }

            WallpaperPicker {
                panelWindow: window
                registry: rootShell.wallpaperPanels
                controllerRegistry: screenScope.panelControllers
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
            Component { id: overviewContentComponent; OverviewContent {} }
            Component { id: switcherContentComponent; WindowSwitcherContent {} }

            readonly property var panelContentComponents: ({
                    calendar: calendarContentComponent,
                    quicksettings: quickSettingsContentComponent,
                    media: mediaContentComponent,
                    wallpaper: wallpaperContentComponent,
                    localsend: localSendContentComponent,
                    barMenu: barMenuContentComponent,
                    trayMenu: trayMenuContentComponent,
                    launcher: appLauncherContentComponent,
                    overview: overviewContentComponent,
                    switcher: switcherContentComponent
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
                           blacklist.includes("voice") &&
                           blacklist.includes("record") &&
                           blacklist.includes("localsend") &&
                           blacklist.includes("wallpaper") &&
                           blacklist.includes("colorpicker");
                }

                return false;
            }

            readonly property int floatingGap: 10
            readonly property int frameThickness: rootShell.frameThickness
            readonly property int barExclusiveZone: ((barMode === 2) ? 56 : (Config.bar.transparency === 2 && !GameModeService.active) ? 34 : 44)

            readonly property var visibleBarLeft: Config.bar.left.filter(id => !isWidgetDisabled(id))
            readonly property var visibleBarRight: Config.bar.right.filter(id => !isWidgetDisabled(id))
            readonly property var visibleBarCenterItems: Config.bar.center.items.filter(id => !isWidgetDisabled(id))

            PanelWindow {
                id: window
                property var modelData: screenScope.modelData
                screen: modelData
                Component.onCompleted: rootShell.barWindows[modelData.name] = window
                Component.onDestruction: delete rootShell.barWindows[modelData.name]

                property bool isMenuOpen: (PanelService.current?.excludeFromBarOverlay === true ? false : (leftZone.anyMenuOpen || rightZone.anyMenuOpen || centerAutoZone.anyMenuOpen || centerBeforeZone.anyMenuOpen || centerAfterZone.anyMenuOpen || (centerAnchorLoader.item && centerAnchorLoader.item.isOpen === true) || (PanelService.current !== null && PanelService.current.excludeFromBarOverlay !== true && (anyMergedPanelOpen || PanelService.currentScreen === null || PanelService.currentScreen === modelData)) || PanelService.currentMode !== null)) || false

                property bool shouldHide: LockscreenService.lockAnimating || LockscreenService.locked

                readonly property real outlineAlpha: Config.bar.transparency === 2 ? 0 : Config.blurOpacity * (typeof Config.bar.outline === "number" ? Config.bar.outline : (Config.bar.outline === false ? 0 : 1))
                readonly property color outlineColor: Qt.alpha(Colors.md3.outline_variant, outlineAlpha)

                readonly property bool huggingCornersVisible: (screenScope.barMode === 0 || screenScope.barMode === 4) && Config.bar.transparency !== 2

                readonly property bool meltActive: Config.bar.meltPanels && huggingCornersVisible
                readonly property bool dockMeltActive: Config.floatingDock.enabled
                        && (Config.floatingDock.melt === 1 || (Config.floatingDock.melt !== 2 && Config.bar.meltPanels))
                        && (screenScope.frameThickness > 0 || huggingCornersVisible)
                readonly property bool ringActive: screenScope.frameThickness > 0 || meltActive || dockMeltActive
                readonly property real frameInset: screenScope.frameThickness
                readonly property real panelGap: 12
                readonly property real meltRadius: 18
                readonly property bool notifMelt: meltActive
                        && (Config.notifications.showAllMonitors || CompositorService.focusedMonitor?.name === modelData.name)
                property var meltMap: ({})
                function setMelt(key, r) {
                    const m = Object.assign({}, meltMap);
                    if (r)
                        m[key] = r;
                    else
                        delete m[key];
                    meltMap = m;
                }

                readonly property string currentPanelType: ((PanelService.current?.panelType ?? "") !== "" && PanelService.currentScreen === modelData) ? PanelService.current.panelType : ""
                readonly property bool ownsOpenMergedPanel: currentPanelType !== "" || dockMenuOpen
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

                readonly property real barAvail: barContent.width
                readonly property real barNeed: {
                    const gap = 12;
                    const half = centerAnchorLoader.active ? (centerAnchorLoader.item?.width ?? 0) / 2 + gap + Math.max(centerBeforeZone.width, centerAfterZone.width) : centerAutoZone.width / 2;
                    if (half === 0)
                        return leftZone.width + rightZone.width + gap;
                    return 2 * (Math.max(leftZone.width, rightZone.width) + gap + half);
                }
                property bool barTight: false
                property real _tightFullNeed: 0

                function _updateTight(): void {
                    if (!barTight && barNeed > barAvail) {
                        _tightFullNeed = barNeed;
                        barTight = true;
                    } else if (barTight && barAvail >= _tightFullNeed + 24) {
                        barTight = false;
                    }
                }
                onBarNeedChanged: _updateTight()
                onBarAvailChanged: _updateTight()

                property rect dockHoverRect: Qt.rect(0, 0, 0, 0)
                property int dockMenuCount: 0
                readonly property bool dockMenuOpen: dockMenuCount > 0

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

                    Region {
                        item: floatingDockLoader.item?.pillItem ?? null
                    }
                    Region {
                        item: floatingDockLoader.item?.sensorStripItem ?? null
                    }
                    Region {
                        item: recordRegionIndicator.chipShown ? recordRegionIndicator.chipItem : null
                    }
                    Region {
                        item: notifMeltLoader.item?.box ?? null
                    }
                }
                mask: (anyMergedPanelOpen || dockMenuOpen) ? null : barOnlyMask

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

                RecordRegionIndicator {
                    id: recordRegionIndicator
                    anchors.fill: parent
                    z: 2
                    screen: window.modelData
                    visible: !window.shouldHide
                }

                Item {
                    id: visualContent
                    z: 1
                    anchors.left: parent.left
                    anchors.right: parent.right
                    property real floatProgress: screenScope.barMode === 2 ? 1 : 0
                    property real dropProgress: screenScope.barMode === 3 ? 1 : 0
                    property real cornerShape: window.huggingCornersVisible ? -1 : screenScope.barMode >= 2 ? 1 : 0
                    Behavior on floatProgress {
                        NumberAnimation { duration: 280; easing.type: Easing.InOutCubic }
                    }
                    Behavior on dropProgress {
                        NumberAnimation { duration: 280; easing.type: Easing.InOutCubic }
                    }
                    Behavior on cornerShape {
                        NumberAnimation { duration: 280; easing.type: Easing.InOutCubic }
                    }
                    readonly property real edgeGap: screenScope.floatingGap * floatProgress
                    height: 44 + 2 * floatProgress
                    anchors.leftMargin: 12 * floatProgress
                    anchors.rightMargin: 12 * floatProgress
                    clip: dropProgress > 0

                    readonly property real topY: edgeGap
                    readonly property real bottomY: parent.height - height - edgeGap
                    readonly property int pillHeight: 32
                    readonly property real pillInset: (height - pillHeight) / 2

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

                    readonly property real lockSlideDistance: height + edgeGap + 20
                    property real lockSlideProgress: window.shouldHide ? 1 : 0
                    Behavior on lockSlideProgress {
                        NumberAnimation {
                            duration: 260
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1]
                        }
                    }

                    transform: Translate {
                        y: (visualContent.state === "top" ? -1 : 1) * visualContent.lockSlideDistance * visualContent.lockSlideProgress
                    }

                    Rectangle {
                        id: barContainer
                        opacity: window.ringActive ? 0 : 1
                        readonly property real edgeK: 1 - visualContent.floatProgress
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: -edgeK
                        anchors.rightMargin: -edgeK
                        height: parent.height * (1 + visualContent.dropProgress) + edgeK
                        y: (Config.bar.position === 0 ? -parent.height * visualContent.dropProgress - edgeK : 0)

                        readonly property bool atTop: Config.bar.position === 0
                        readonly property real innerRadius: 22 * Math.max(0, visualContent.cornerShape)
                        readonly property real outerRadius: 22 * visualContent.floatProgress
                        topLeftRadius: atTop ? outerRadius : innerRadius
                        topRightRadius: atTop ? outerRadius : innerRadius
                        bottomLeftRadius: atTop ? innerRadius : outerRadius
                        bottomRightRadius: atTop ? innerRadius : outerRadius

                        border.width: 1
                        border.color: Qt.alpha(Colors.md3.outline_variant, window.outlineAlpha * Math.max(0, Math.min(1, 1 + visualContent.cornerShape)))
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
                    }

                    Rectangle {
                        z: 1
                        visible: !window.ringActive
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: huggingCornersWrapper.huggingCornerRadius + screenScope.frameThickness
                        anchors.rightMargin: huggingCornersWrapper.huggingCornerRadius + screenScope.frameThickness
                        height: 1
                        y: Config.bar.position === 0 ? parent.height : -1
                        color: window.outlineColor
                        opacity: Math.max(0, Math.min(1, -visualContent.cornerShape))
                    }

                    Item {
                        id: barContent
                        anchors.fill: parent
                        anchors.leftMargin: visualContent.pillInset
                        anchors.rightMargin: visualContent.pillInset

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

                Loader {
                    z: 2
                    anchors.fill: parent
                    active: true
                    sourceComponent: ScreenCorners { screen: screenScope.modelData }
                }

                Loader {
                    id: floatingDockLoader
                    z: 3
                    anchors.fill: parent
                    active: Config.floatingDock.enabled
                    sourceComponent: FloatingDock { modelData: screenScope.modelData }
                }

                Loader {
                    z: 4
                    active: Config.neko.enabled && Config.neko.onTop
                        && !(LockscreenService.locked || LockscreenService.lockAnimating || LockscreenService.lockVisualActive || LockscreenService.unlockAnimating)
                        && CompositorService.hasCapability("cursorPosition")
                    sourceComponent: Neko { modelData: screenScope.modelData }
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
                        id: frameRing
                        anchors.fill: parent
                        visible: window.ringActive
                        readonly property real t: screenScope.frameThickness
                        readonly property real r: huggingCornersWrapper.huggingCornerRadius
                        readonly property bool atTop: Config.bar.position === 0
                        readonly property bool framed: t > 0
                        readonly property real farInset: framed ? t : -1
                        readonly property real rt: (atTop || framed) ? r : 0
                        readonly property real rb: (!atTop || framed) ? r : 0
                        property real topInset: atTop ? screenScope.barExclusiveZone : farInset
                        property real bottomInset: atTop ? farInset : screenScope.barExclusiveZone
                        Behavior on topInset { NumberAnimation { duration: 300; easing.type: Easing.InOutCubic } }
                        Behavior on bottomInset { NumberAnimation { duration: 300; easing.type: Easing.InOutCubic } }
                        readonly property real x1: farInset
                        readonly property real x2: width - farInset
                        readonly property real y1: topInset
                        readonly property real y2: height - bottomInset
                        readonly property var meltEdges: {
                            const e = [[], [], [], []];
                            for (const m of Object.values(window.meltMap)) {
                                const edge = m.edge >= 0 ? m.edge : Config.bar.position;
                                const h = m.depth >= 0 ? m.depth : m.height;
                                e[edge].push(edge < 2 ? { p: m.x, w: m.width, h: h } : { p: m.y, w: m.height, h: h });
                            }
                            return e;
                        }
                        function pathFor(inset) {
                            return MeltPath.holePath({
                                x1: x1, x2: x2, y1: y1, y2: y2, rt: rt, rb: rb, barEdge: Config.bar.position,
                                top: meltEdges[0], bottom: meltEdges[1], left: meltEdges[2], right: meltEdges[3],
                                f: r, c: window.meltRadius, inset: inset
                            });
                        }
                        readonly property string holeD: pathFor(0)
                        readonly property string strokeD: pathFor(0.5)

                        Shape {
                            anchors.fill: parent
                            preferredRendererType: Shape.CurveRenderer

                            ShapePath {
                                fillColor: huggingCornersWrapper.barColor
                                strokeColor: "transparent"
                                fillRule: ShapePath.OddEvenFill
                                PathSvg { path: "M-10 -10 H" + (frameRing.width + 10) + " V" + (frameRing.height + 10) + " H-10 Z " + frameRing.holeD }
                            }
                            ShapePath {
                                fillColor: "transparent"
                                strokeColor: window.outlineColor
                                strokeWidth: 1
                                PathSvg { path: frameRing.strokeD }
                            }
                        }
                    }

                    Item {
                        id: huggingCornersWrapper
                        visible: !window.ringActive
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: screenScope.frameThickness
                        anchors.rightMargin: screenScope.frameThickness
                        height: huggingCornerRadius

                        y: activeSide === 0
                            ? (visualContent.y + visualContent.height)
                            : (visualContent.y - huggingCornerRadius)

                        readonly property int huggingCornerRadius: 26

                        property real swapMaskProgress: 0
                        readonly property real maskProgress: Math.max(-1, swapMaskProgress - 1 - visualContent.cornerShape)

                        property int activeSide: 0
                        Component.onCompleted: activeSide = Config.bar.position

                        property string barColor: GameModeService.active ? "transparent" : Qt.alpha(Colors.md3.surface_container, Config.blurOpacity)

                        transform: Translate {
                            y: (visualContent.state === "top" ? -1 : 1) * visualContent.lockSlideDistance * visualContent.lockSlideProgress
                        }

                        CornerBlock {
                            type: huggingCornersWrapper.activeSide === 1 ? 2 : 0
                            anchors.left: parent.left
                            anchors.top: parent.top
                            cornerColor: huggingCornersWrapper.barColor
                            cornerRadius: huggingCornersWrapper.huggingCornerRadius
                            maskProgress: huggingCornersWrapper.maskProgress
                            outlineColor: window.outlineColor
                        }

                        CornerBlock {
                            type: huggingCornersWrapper.activeSide === 1 ? 3 : 1
                            anchors.right: parent.right
                            anchors.top: parent.top
                            cornerColor: huggingCornersWrapper.barColor
                            cornerRadius: huggingCornersWrapper.huggingCornerRadius
                            maskProgress: huggingCornersWrapper.maskProgress
                            outlineColor: window.outlineColor
                        }
                    }

                    Loader {
                        id: notifMeltLoader
                        anchors.fill: parent
                        active: window.notifMelt
                        sourceComponent: NotificationMeltStack { win: window }
                    }

                    ListModel {
                        id: mountedPanelTypes
                    }

                    Timer {
                        interval: 4000
                        running: true
                        onTriggered: {
                            if (!window._hasMountedType("launcher"))
                                mountedPanelTypes.append({ type: "launcher" });
                        }
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
                                item.controller = (rootShell.globalPanelControllers[panelSlotLoader.type] ?? screenScope.panelControllers[panelSlotLoader.type]) ?? null;
                                if (panelSlotLoader.type === "launcher")
                                    item.shellWindow = window;
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
                                    if (panelSlotLoader.type === "launcher")
                                        return;
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

            Variants {
                model: screenScope.frameThickness > 0 ? [2, 3, 1 - Config.bar.position] : []
                PanelWindow {
                    required property int modelData
                    screen: screenScope.modelData
                    WlrLayershell.namespace: "quickshell:frameSpacer"
                    WlrLayershell.layer: WlrLayer.Bottom
                    readonly property bool side: modelData >= 2
                    anchors.top: modelData === 0 || side
                    anchors.bottom: modelData === 1 || side
                    anchors.left: modelData === 2 || !side
                    anchors.right: modelData === 3 || !side
                    implicitWidth: side ? screenScope.frameThickness : 0
                    implicitHeight: side ? 0 : screenScope.frameThickness
                    exclusionMode: ExclusionMode.Normal
                    exclusiveZone: screenScope.frameThickness
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
