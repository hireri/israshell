import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.style

PanelWindow {
    id: root
    required property var modelData
    screen: modelData
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.namespace: "quickshell:desktopwidgets"
    WlrLayershell.layer: WlrLayer.Bottom
    anchors { top: true; bottom: true; left: true; right: true }

    readonly property bool wantsInput: (backgroundContextMenu.visible || EditModeService.active) && !LockscreenService.locked
    focusable: ((Config.clock.manualPos ?? false) || root.wantsInput) && !LockscreenService.locked

    function _syncKeyboardFocus(): void {
        WlrLayershell.keyboardFocus = root.wantsInput ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None;
    }
    function reclaimFocus(): void {
        if (!root.wantsInput)
            return;
        WlrLayershell.keyboardFocus = WlrKeyboardFocus.None;
        Qt.callLater(root._syncKeyboardFocus);
    }
    onWantsInputChanged: root._syncKeyboardFocus()
    Component.onCompleted: root._syncKeyboardFocus()

    Connections {
        target: CompositorService
        function onActiveWindowChanged(): void {
            if (root.wantsInput && CompositorService.activeWindow.address === "")
                root.reclaimFocus();
        }
    }

    readonly property Item _activeBlurItem: backgroundContextMenu.visible
        ? backgroundContextMenu.cardItem
        : (EditModeService.active ? editModeOverlayLoader.item?.toolbarItem ?? null : null)
    readonly property bool blurEnabled: Config.blurAllowed(root._activeBlurItem !== null)
    BackgroundEffect.blurRegion: blurEnabled ? activeBlurRegion : null

    Region {
        id: activeBlurRegion
        item: root._activeBlurItem

        Region {
            item: EditModeService.active ? editModeOverlayLoader.item?.drawerCardItem ?? null : null
            intersection: Intersection.Combine
        }
    }

    MouseArea {
        id: backgroundContextCatcher
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: mouse => {
            BackgroundMenuService.open(root.modelData, mouse.x, mouse.y);
        }
    }

    Loader {
        id: weyesLoader
        anchors.fill: parent
        active: Config.weyes.enabled && CompositorService.hasCapability("cursorPosition")

        sourceComponent: Weyes {
            modelData: root.modelData
        }
    }

    readonly property bool nekoForceBehind: LockscreenService.locked || LockscreenService.lockAnimating || LockscreenService.lockVisualActive || LockscreenService.unlockAnimating

    Loader {
        id: nekoLoader
        active: Config.neko.enabled && (!Config.neko.onTop || root.nekoForceBehind) && CompositorService.hasCapability("cursorPosition")

        sourceComponent: Neko {
            modelData: root.modelData
        }
    }

    Loader {
        id: activateLinuxLoader
        anchors.fill: parent
        active: Config.activateLinux

        sourceComponent: ActivateLinux {
            modelData: root.modelData
        }
    }

    Repeater {
        model: DesktopWidgetService.enabledIds
        z: 1

        Loader {
            id: desktopWidgetLoader
            anchors.fill: parent
            required property string modelData
            readonly property var _entry: DesktopWidgetService.entryFor(modelData)
            active: _entry !== null
            sourceComponent: _entry ? DesktopWidgetService.componentMap[_entry.type] : null
            onLoaded: {
                item.entryId = desktopWidgetLoader.modelData;
                item.hostScreen = root.modelData;
            }
        }
    }

    CavaVisualizer {
        id: cavaVisualizer
        anchors.fill: parent
        z: 3
        pause: LockscreenService.locked || LockscreenService.lockVisualActive || GameModeService.active
        visible: Config.cava.enabled
    }

    Loader {
        id: clockLoader
        anchors.fill: parent
        active: Config.desktopClock || loadedOnce
        property bool loadedOnce: false
        onLoaded: loadedOnce = true
        z: 4
        sourceComponent: ClockWidget { modelData: root.modelData }
    }

    BackgroundMenu {
        id: backgroundContextMenu
        hostScreen: root.modelData
        z: 20
    }

    Loader {
        id: editModeOverlayLoader
        anchors.fill: parent
        active: EditModeService.active
        z: 20
        sourceComponent: EditModeOverlay {}
    }

    Item {
        id: escapeHandler
        anchors.fill: parent
        focus: true

        HoverHandler {
            onHoveredChanged: if (hovered)
                root.reclaimFocus()
        }

        Keys.onEscapePressed: event => {
            if (backgroundContextMenu.visible) {
                event.accepted = true;
                backgroundContextMenu.close();
            } else if (EditModeService.active) {
                event.accepted = true;
                EditModeService.disable();
            }
        }
    }
}
