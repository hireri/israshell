import QtQuick
import QtQuick.Window
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

    WlrLayershell.namespace: "quickshell:desktopwidgets"
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

    readonly property var _overlay: EditModeService.active ? editModeOverlayLoader.item : null
    readonly property bool _anyBlurTarget: backgroundContextMenu.visible || root._overlay !== null || widgetContextMenu.visible || widgetInspector.visible
    readonly property bool blurEnabled: Config.blurAllowed(root._anyBlurTarget)
    BackgroundEffect.blurRegion: blurEnabled ? activeBlurRegion : null

    component ScaledCutout: Region {
        id: cutout
        required property Item source
        required property bool sourceVisible
        property real originX: 0
        property real originY: 0
        intersection: Intersection.Combine

        readonly property real _scale: cutout.source.scale

        x: cutout.source.x + cutout.originX * cutout.source.width * (1 - cutout._scale)
        y: cutout.source.y + cutout.originY * cutout.source.height * (1 - cutout._scale)
        width: cutout.sourceVisible ? cutout.source.width * cutout._scale : 0
        height: cutout.sourceVisible ? cutout.source.height * cutout._scale : 0
        radius: cutout.source.radius * cutout._scale
    }

    Region {
        id: activeBlurRegion

        ScaledCutout {
            source: backgroundContextMenu.cardItem
            sourceVisible: backgroundContextMenu.visible
            originX: backgroundContextMenu.cardOriginX
            originY: backgroundContextMenu.cardOriginY
        }

        Region {
            intersection: Intersection.Combine
            x: root._overlay?.toolbarRect.x ?? 0
            y: root._overlay?.toolbarRect.y ?? 0
            width: root._overlay ? root._overlay.toolbarRect.width : 0
            height: root._overlay ? root._overlay.toolbarRect.height : 0
            radius: root._overlay?.toolbarRadius ?? 0
        }

        ScaledCutout {
            source: widgetContextMenu.cardItem
            sourceVisible: widgetContextMenu.visible
            originX: widgetContextMenu.cardOriginX
            originY: widgetContextMenu.cardOriginY
        }

        ScaledCutout {
            source: widgetInspector.cardItem
            sourceVisible: widgetInspector.visible
            originX: widgetInspector.cardOriginX
            originY: widgetInspector.cardOriginY
        }
    }

    MouseArea {
        id: backgroundContextCatcher
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
        model: DesktopWidgetService.entryModel

        Loader {
            id: desktopWidgetLoader
            anchors.fill: parent
            z: 4
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
        z: 4

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
        z: 5
        sourceComponent: ClockWidget { modelData: root.modelData }
    }

    ContextMenu {
        id: widgetContextMenu
        hostScreen: root.modelData
        z: 45
    }

    WidgetInspector {
        id: widgetInspector
        hostScreen: root.modelData
        z: 44
        onClosed: escapeHandler.forceActiveFocus()
    }

    CavaVisualizer {
        id: cavaVisualizer
        anchors.fill: parent
        z: 3
        pause: LockscreenService.locked || LockscreenService.lockVisualActive || GameModeService.active
        visible: Config.cava.enabled
    }

    BackgroundMenu {
        id: backgroundContextMenu
        hostScreen: root.modelData
        widgetDrawer: editModeOverlayLoader.item?.widgetDrawerItem ?? null
        z: 20
    }

    Loader {
        id: editModeOverlayLoader
        anchors.fill: parent
        active: EditModeService.active
        z: 20
        sourceComponent: EditModeOverlay {
            hostScreen: root.modelData
        }
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
