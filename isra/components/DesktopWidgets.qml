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

    focusable: ((Config.clock.manualPos ?? false) || backgroundContextMenu.visible || EditModeService.active) && !LockscreenService.locked

    readonly property Item _activeBlurItem: backgroundContextMenu.visible
        ? backgroundContextMenu.cardItem
        : (EditModeService.active ? editModeOverlayLoader.item?.toolbarItem ?? null : null)
    readonly property bool blurEnabled: Config.blurAllowed(root._activeBlurItem !== null)
    BackgroundEffect.blurRegion: blurEnabled ? activeBlurRegion : null

    Region {
        id: activeBlurRegion
        item: root._activeBlurItem
    }

    MouseArea {
        id: backgroundContextCatcher
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: mouse => {
            backgroundContextMenu.open(mouse.x, mouse.y);
        }
    }

    BackgroundMenu {
        id: backgroundContextMenu
        hostScreen: root.modelData
        z: 20
    }

    Item {
        id: escapeHandler
        anchors.fill: parent
        focus: true
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

    Loader {
        id: editModeOverlayLoader
        anchors.fill: parent
        active: EditModeService.active
        z: 20
        sourceComponent: EditModeOverlay {}
    }
}
