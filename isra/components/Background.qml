import QtQuick
import QtQuick.Effects
import QtQuick.Window
import QtMultimedia
import Qt5Compat.GraphicalEffects
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

    WlrLayershell.namespace: "quickshell:background"
    WlrLayershell.layer: WlrLayer.Bottom
    anchors { top: true; bottom: true; left: true; right: true }

    readonly property bool wantsInput: (backgroundContextMenu.visible || EditModeService.active) && !LockscreenService.locked
    focusable: root.wantsInput

    function _syncKeyboardFocus(): void {
        WlrLayershell.keyboardFocus = root.wantsInput ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None;
    }
    function reclaimFocus(): void {
        if (!root.wantsInput || escapeHandler.Window.active)
            return;
        WlrLayershell.keyboardFocus = WlrKeyboardFocus.None;
        Qt.callLater(root._syncKeyboardFocus);
    }
    onWantsInputChanged: root._syncKeyboardFocus()
    Component.onCompleted: {
        root._syncKeyboardFocus();
        if (root.blurShouldShow)
            root.blurLoaderActive = true;
    }

    Connections {
        target: CompositorService
        function onActiveWindowChanged(): void {
            if (root.wantsInput && CompositorService.activeWindow.address === "")
                root.reclaimFocus();
        }
    }

    Connections {
        target: EditModeService
        function onSelectedIdChanged(): void {
            if (EditModeService.selectedId !== "")
                escapeHandler.forceActiveFocus();
        }
    }

    readonly property bool shouldBlur: LockscreenService.locked || LockscreenService.lockVisualActive

    readonly property bool anyPopupOpen: backgroundContextMenu.visible || widgetContextMenu.visible || widgetInspector.visible || EditModeService.active
    readonly property bool popupBlurNeeded: Config.blurAllowed(root.anyPopupOpen)

    readonly property bool desktopWidgetBlurEnabled: Config.desktopWidgetBlurAllowed(true)
    BackgroundEffect.blurRegion: root.desktopWidgetBlurEnabled ? desktopWidgetBlurRegion : null

    Region {
        id: desktopWidgetBlurRegion
        item: root.contentItem
    }

    MouseArea {
        id: backgroundContextCatcher
        z: 3
        anchors.fill: parent
        acceptedButtons: EditModeService.active ? (Qt.RightButton | Qt.LeftButton) : Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                EditModeService.clearSelection();
                editModeOverlayLoader.item?.widgetDrawerItem?.close();
                backgroundContextMenu.open(mouse.x, mouse.y);
            } else {
                EditModeService.clearSelection();
            }
        }
    }

    readonly property bool nekoForceBehind: LockscreenService.locked || LockscreenService.lockAnimating || LockscreenService.lockVisualActive || LockscreenService.unlockAnimating

    Loader {
        id: nekoLoader
        z: 3
        active: Config.neko.enabled && (!Config.neko.onTop || root.nekoForceBehind) && CompositorService.hasCapability("cursorPosition")

        sourceComponent: Neko {
            modelData: root.modelData
        }
    }

    Loader {
        id: activateLinuxLoader
        z: 3
        anchors.fill: parent
        active: Config.activateLinux

        sourceComponent: ActivateLinux {
            modelData: root.modelData
        }
    }

    PopupBlurBackdrop {
        id: popupBlurBackdrop
        z: 3
        hostScreen: root.modelData
        active: root.popupBlurNeeded
    }

    CavaVisualizer {
        id: cavaVisualizer
        z: 4
        anchors.fill: parent
        pause: LockscreenService.locked || LockscreenService.lockVisualActive || GameModeService.active
        visible: Config.cava.enabled
    }

    Repeater {
        model: DesktopWidgetService.entryModel

        Loader {
            id: desktopWidgetLoader
            anchors.fill: parent
            z: 5
            required property string widgetId

            readonly property string _type: DesktopWidgetService.entryFor(widgetId)?.type ?? ""
            active: _type !== ""
            sourceComponent: _type !== "" ? DesktopWidgetService.componentMap[_type] : null
            onLoaded: {
                item.entryId = desktopWidgetLoader.widgetId;
                item.hostScreen = root.modelData;
                item.widgetMenu = widgetContextMenu;
                item.widgetInspector = widgetInspector;
                item.widgetDrawer = Qt.binding(() => editModeOverlayLoader.item?.widgetDrawerItem ?? null);
            }
        }
    }

    readonly property bool blurShouldShow: LockscreenService.locked || LockscreenService.lockVisualActive
    property bool blurLoaderActive: false

    onBlurShouldShowChanged: {
        if (blurShouldShow)
            blurLoaderActive = true;
        else
            blurUnloadDelay.restart();
    }

    Timer {
        id: blurUnloadDelay
        interval: 420
        onTriggered: root.blurLoaderActive = false
    }

    Loader {
        id: blurLoader
        anchors.fill: parent
        active: root.blurLoaderActive
        z: 6

        onLoaded: item.targetActive = root.blurShouldShow

        sourceComponent: Item {
            id: blurRoot
            anchors.fill: parent

            property bool targetActive: false

            opacity: targetActive ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: 400; easing.type: Easing.InOutCubic }
            }

            Component.onCompleted: {
                Qt.callLater(() => {
                    targetActive = root.blurShouldShow;
                });
            }

            Image {
                id: blurSrcImg
                anchors.fill: parent
                source: (WallpaperService.currentWallPreview || WallpaperService.currentWall)
                    ? ("file://" + (WallpaperService.currentWallPreview || WallpaperService.currentWall))
                    : ""
                fillMode: Image.PreserveAspectCrop
                visible: false
                layer.enabled: true
                layer.textureSize: Qt.size(sourceSize.width, sourceSize.height)

                sourceSize.width: root.screen ? Math.max(1, Math.round(root.screen.width * root.screen.devicePixelRatio / (Config.blurEffects ? 4 : 1))) : 480
                sourceSize.height: root.screen ? Math.max(1, Math.round(root.screen.height * root.screen.devicePixelRatio / (Config.blurEffects ? 4 : 1))) : 270
            }

            FastBlur {
                anchors.fill: parent
                source: blurSrcImg
                radius: blurRoot.targetActive && Config.blurEffects ? 64 : 0

                Behavior on radius {
                    NumberAnimation { duration: 400; easing.type: Easing.InOutCubic }
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Colors.md3.surface_container, 0.65)
            }

            Connections {
                target: root
                function onBlurShouldShowChanged() {
                    blurRoot.targetActive = root.blurShouldShow;
                }
            }
        }
    }

    Loader {
        id: clockLoader
        anchors.fill: parent
        active: Config.desktopClock || loadedOnce
        property bool loadedOnce: false
        onLoaded: loadedOnce = true
        z: 7
        sourceComponent: ClockWidget { modelData: root.modelData }
    }

    BackgroundMenu {
        id: backgroundContextMenu
        hostScreen: root.modelData
        widgetDrawer: editModeOverlayLoader.item?.widgetDrawerItem ?? null
        blurSource: popupBlurBackdrop.texture
        z: 8
    }

    Loader {
        id: editModeOverlayLoader
        anchors.fill: parent
        active: EditModeService.active
        z: 9
        sourceComponent: EditModeOverlay {
            hostScreen: root.modelData
            blurSource: popupBlurBackdrop.texture
        }
    }

    WidgetInspector {
        id: widgetInspector
        hostScreen: root.modelData
        blurSource: popupBlurBackdrop.texture
        z: 10
        onClosed: escapeHandler.forceActiveFocus()
    }

    ContextMenu {
        id: widgetContextMenu
        hostScreen: root.modelData
        blurSource: popupBlurBackdrop.texture
        z: 11
    }

    Item {
        id: escapeHandler
        anchors.fill: parent
        focus: true

        HoverHandler {
            onHoveredChanged: if (hovered)
                root.reclaimFocus()
        }

        readonly property var _drawer: editModeOverlayLoader.item?.widgetDrawerItem ?? null

        Keys.onEscapePressed: event => {
            event.accepted = true;
            if (escapeHandler._drawer?.open) {
                escapeHandler._drawer.close();
            } else if (backgroundContextMenu.visible) {
                backgroundContextMenu.close();
            } else if (widgetContextMenu.visible) {
                widgetContextMenu.close();
            } else if (widgetInspector.visible) {
                widgetInspector.close();
            } else if (EditModeService.selectedId !== "") {
                EditModeService.clearSelection();
            } else if (EditModeService.active) {
                EditModeService.disable();
            } else {
                event.accepted = false;
            }
        }

        Keys.onPressed: event => {
            if (!EditModeService.active || EditModeService.selectedId === "")
                return;

            const step = (event.modifiers & Qt.ShiftModifier) ? 10 : 1;
            switch (event.key) {
            case Qt.Key_Left:
                EditModeService.nudgeRequested(-step, 0);
                break;
            case Qt.Key_Right:
                EditModeService.nudgeRequested(step, 0);
                break;
            case Qt.Key_Up:
                EditModeService.nudgeRequested(0, -step);
                break;
            case Qt.Key_Down:
                EditModeService.nudgeRequested(0, step);
                break;
            case Qt.Key_Delete:
            case Qt.Key_Backspace:
                EditModeService.deleteRequested();
                break;
            default:
                return;
            }
            event.accepted = true;
        }
    }
}
