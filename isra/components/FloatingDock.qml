pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

import qs.style
import qs.services

PanelWindow {
    id: dockRoot

    required property var modelData
    screen: modelData

    property bool overlayLayer: false

    component DockSection: Loader {
        visible: active
        Layout.alignment: Qt.AlignCenter
    }

    component DockSeparator: Item {
        implicitWidth: dockRoot.isVerticalEdge ? dockRoot.itemCellSize : 1
        implicitHeight: dockRoot.isVerticalEdge ? 1 : dockRoot.itemCellSize

        Rectangle {
            anchors.centerIn: parent
            width: dockRoot.isVerticalEdge ? dockRoot.itemCellSize * 0.6 : 1
            height: dockRoot.isVerticalEdge ? 1 : dockRoot.itemCellSize * 0.6
            radius: 0.5
            color: Qt.alpha(Colors.md3.outline_variant, 0.6)
        }
    }

    readonly property int edge: Config.floatingDock.edge
    readonly property bool isVerticalEdge: edge === 2 || edge === 3
    readonly property int orientation: isVerticalEdge ? 1 : 0

    readonly property int itemGlyphSize: Config.floatingDock.iconSize
    readonly property int itemCellSize: itemGlyphSize + 12
    readonly property int itemSpacing: 8
    readonly property int pillPadding: 9
    readonly property int pillThickness: itemCellSize + pillPadding * 2
    
    readonly property int edgeMargin: 8
    readonly property int sensorThickness: 6
    readonly property int windowThickness: pillThickness + edgeMargin

    readonly property bool pinned: Config.floatingDock.exclusiveZone
    readonly property bool smartHide: Config.floatingDock.smartHide

    readonly property var monitorWorkspace: {
        const list = CompositorService.workspaces ?? [];
        const name = dockRoot.screen ? dockRoot.screen.name : "";
        return list.find(w => w.monitor === name && w.active) ?? null;
    }
    readonly property bool hasWindowsUnderneath: {
        const ws = monitorWorkspace;
        if (!ws)
            return false;
        const list = CompositorService.windows ?? [];
        return list.some(w => w.workspace === ws.id);
    }

    readonly property bool hovered: sensorHover.hovered || pillHover.hovered
    property bool hoverLatched: false

    property bool fileDragOverSensor: false

    onHoveredChanged: {
        if (hovered) {
            hideDelay.stop();
            hoverLatched = true;
        } else {
            hideDelay.restart();
        }
    }

    Timer {
        id: hideDelay
        interval: 400
        onTriggered: dockRoot.hoverLatched = false
    }

    readonly property bool interactionHold: dockModelImpl.draggingKey !== "" || hoverPopup.visible || trashBusy
        || fileDragOverSensor || trashFileHovering
    property bool trashBusy: false
    property bool trashFileHovering: false

    readonly property bool revealed: pinned || hoverLatched || interactionHold || (smartHide && !hasWindowsUnderneath)

    property bool blurHoldActive: revealed
    onRevealedChanged: {
        if (revealed) {
            blurCloseDelay.stop();
            blurHoldActive = true;
        } else {
            blurCloseDelay.restart();
        }
    }

    Timer {
        id: blurCloseDelay
        interval: 260
        onTriggered: dockRoot.blurHoldActive = false
    }

    DockModel {
        id: dockModelImpl
        orientation: dockRoot.orientation
        itemStride: dockRoot.itemCellSize + dockRoot.itemSpacing
    }
    readonly property DockModel dockModel: dockModelImpl
    readonly property var pinnedApps: dockModelImpl.pinnedApps
    function togglePinned(appId: string): void { dockModelImpl.togglePinned(appId); }
    function getDesktopEntry(appId: string): var { return dockModelImpl.getDesktopEntry(appId); }
    readonly property string draggingKey: dockModelImpl.draggingKey
    readonly property real dragPos: dockModelImpl.dragPos
    readonly property real dragClickOffset: dockModelImpl.dragClickOffset
    readonly property var displayModel: dockModelImpl.displayModel

    function beginDrag(key: string, pos: real): void { dockModelImpl.beginDrag(key, pos); }
    function updateDrag(key: string, pos: real): void { dockModelImpl.updateDrag(key, pos); }
    function endDrag(): void { dockModelImpl.endDrag(); }
    function updateDragPoint(p: point): void {
        if (!Config.floatingDock.showTrash || !trashLoader.item) return;
        dockModelImpl.trashHovered = trashLoader.item.containsScenePoint(p);
    }

    readonly property Item rowContainer: itemsView.contentItem

    onDisplayModelChanged: hoverPopup.syncWithModel()

    readonly property bool hasContent: Config.floatingDock.showLauncher
        || Config.floatingDock.showTrash
        || dockModelImpl.viewModel.count > 0

    visible: Config.floatingDock.enabled && hasContent
    color: "transparent"

    readonly property bool blurEnabled: Config.blurAllowed(blurHoldActive)
    BackgroundEffect.blurRegion: blurEnabled ? dockBlurRegion : null

    Region {
        id: dockBlurRegion
        item: pill
    }

    WlrLayershell.namespace: "quickshell:floatingDock"
    WlrLayershell.layer: overlayLayer ? WlrLayer.Overlay : WlrLayer.Top

    exclusionMode: (pinned && hasContent) ? ExclusionMode.Normal : ExclusionMode.Ignore
    exclusiveZone: (pinned && hasContent) ? windowThickness : 0

    anchors.top: edge === 0 || isVerticalEdge
    anchors.bottom: edge === 1 || isVerticalEdge
    anchors.left: edge === 2 || !isVerticalEdge
    anchors.right: edge === 3 || !isVerticalEdge

    implicitWidth: isVerticalEdge ? windowThickness : 0
    implicitHeight: isVerticalEdge ? 0 : windowThickness

    mask: revealed ? null : hiddenMask

    Region {
        id: hiddenMask
        item: sensorStrip
    }

    Item {
        id: contentRoot
        anchors.fill: parent

        Item {
            id: sensorStrip

            HoverHandler {
                id: sensorHover
            }

            DropArea {
                anchors.fill: parent
                keys: ["text/uri-list"]
                onEntered: dockRoot.fileDragOverSensor = true
                onExited: dockRoot.fileDragOverSensor = false
                onDropped: dockRoot.fileDragOverSensor = false
            }

            width: dockRoot.isVerticalEdge ? dockRoot.sensorThickness : pill.width
            height: dockRoot.isVerticalEdge ? pill.height : dockRoot.sensorThickness

            x: {
                if (!dockRoot.isVerticalEdge) return (parent.width - width) / 2;
                return dockRoot.edge === 2 ? 0 : parent.width - width;
            }
            y: {
                if (dockRoot.isVerticalEdge) return (parent.height - height) / 2;
                return dockRoot.edge === 0 ? 0 : parent.height - height;
            }
        }

        Rectangle {
            id: pill

            implicitWidth: dockRoot.isVerticalEdge ? dockRoot.pillThickness : contentLayout.implicitWidth + dockRoot.pillPadding * 2
            implicitHeight: dockRoot.isVerticalEdge ? contentLayout.implicitHeight + dockRoot.pillPadding * 2 : dockRoot.pillThickness
            width: implicitWidth
            height: implicitHeight
            radius: Math.min(width, height) / 2

            clip: true

            readonly property int slideSign: (dockRoot.edge === 0 || dockRoot.edge === 2) ? -1 : 1
            readonly property real hiddenOffset: dockRoot.windowThickness

            readonly property real restX: {
                if (!dockRoot.isVerticalEdge) return (parent.width - width) / 2;
                return dockRoot.edge === 2 ? dockRoot.edgeMargin : (parent.width - width - dockRoot.edgeMargin);
            }
            readonly property real restY: {
                if (dockRoot.isVerticalEdge) return (parent.height - height) / 2;
                return dockRoot.edge === 0 ? dockRoot.edgeMargin : (parent.height - height - dockRoot.edgeMargin);
            }

            property real slideOffset: dockRoot.revealed ? 0 : slideSign * hiddenOffset
            Behavior on slideOffset {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1]
                }
            }

            x: restX + (dockRoot.isVerticalEdge ? slideOffset : 0)
            y: restY + (dockRoot.isVerticalEdge ? 0 : slideOffset)

            color: Config.dim(Colors.md3.surface_container)
            border.width: 1
            border.color: Qt.alpha(Colors.md3.outline, 0.18)

            HoverHandler {
                id: pillHover
            }

            DropArea {
                anchors.fill: parent
                keys: ["text/uri-list"]
                onEntered: dockRoot.fileDragOverSensor = true
                onExited: dockRoot.fileDragOverSensor = false
                onDropped: dockRoot.fileDragOverSensor = false
            }

            readonly property Item rowContainer: dockRoot.rowContainer
            readonly property int orientation: dockRoot.orientation
            readonly property string draggingKey: dockRoot.draggingKey
            readonly property real dragPos: dockRoot.dragPos
            readonly property real dragClickOffset: dockRoot.dragClickOffset
            readonly property var pinnedApps: dockRoot.pinnedApps
            readonly property var displayModel: dockRoot.displayModel
            readonly property DockModel dockModel: dockRoot.dockModel
            readonly property int itemGlyphSize: dockRoot.itemGlyphSize
            readonly property int itemCellSize: dockRoot.itemCellSize
            function togglePinned(appId: string): void { dockRoot.togglePinned(appId); }
            function getDesktopEntry(appId: string): var { return dockRoot.getDesktopEntry(appId); }
            function beginDrag(key: string, pos: real): void { dockRoot.beginDrag(key, pos); }
            function updateDrag(key: string, pos: real): void { dockRoot.updateDrag(key, pos); }
            function endDrag(): void { dockRoot.endDrag(); }
            function updateDragPoint(p: point): void { dockRoot.updateDragPoint(p); }

            GridLayout {
                id: contentLayout
                anchors.centerIn: parent
                columns: dockRoot.isVerticalEdge ? 1 : -1
                rows: dockRoot.isVerticalEdge ? -1 : 1
                columnSpacing: dockRoot.itemSpacing
                rowSpacing: dockRoot.itemSpacing

                DockSection {
                    active: Config.floatingDock.showLauncher
                    sourceComponent: LauncherButton {
                        cellSize: dockRoot.itemCellSize
                        glyphSize: dockRoot.itemGlyphSize
                    }
                }

                Item {
                    Layout.alignment: Qt.AlignCenter
                    visible: dockModelImpl.viewModel.count > 0

                    implicitWidth: dockRoot.isVerticalEdge
                        ? dockRoot.itemCellSize
                        : Math.max(0, itemsView.contentWidth - dockRoot.itemSpacing)
                    implicitHeight: dockRoot.isVerticalEdge
                        ? Math.max(0, itemsView.contentHeight - dockRoot.itemSpacing)
                        : dockRoot.itemCellSize

                    ListView {
                        id: itemsView
                        x: dockRoot.isVerticalEdge ? 0 : -dockRoot.itemSpacing / 2
                        y: dockRoot.isVerticalEdge ? -dockRoot.itemSpacing / 2 : 0
                        width: dockRoot.isVerticalEdge ? dockRoot.itemCellSize : contentWidth
                        height: dockRoot.isVerticalEdge ? contentHeight : dockRoot.itemCellSize
                        orientation: dockRoot.isVerticalEdge ? ListView.Vertical : ListView.Horizontal
                        interactive: false
                        spacing: 0
                        clip: false
                        model: dockModelImpl.viewModel

                        moveDisplaced: Transition {
                            NumberAnimation { properties: "x,y"; duration: 220; easing.type: Easing.OutCubic }
                        }

                        delegate: Item {
                            id: delegateRoot
                            required property string _key
                            required property bool _exiting
                            required property bool _instant

                            readonly property var livePayload: {
                                let items = dockRoot.displayModel;
                                if (!items) return null;
                                for (let i = 0; i < items.length; i++) {
                                    if (items[i] && items[i].key === _key) return items[i];
                                }
                                return null;
                            }

                            property var payload: null
                            onLivePayloadChanged: if (livePayload) payload = livePayload

                            readonly property bool isSeparator: delegateRoot.payload ? !!delegateRoot.payload.isSeparator : false

                            readonly property int fullExtent: (isSeparator ? 1 : dockRoot.itemCellSize)
                                + dockRoot.itemSpacing

                            readonly property real targetExtent: _exiting ? 0 : fullExtent
                            property real extent: 0

                            property bool suppressInitialAnim: _instant
                            Behavior on extent {
                                enabled: !delegateRoot.suppressInitialAnim
                                NumberAnimation {
                                    duration: dockModelImpl.exitDuration
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1]
                                }
                            }
                            function applyExtent(): void { extent = targetExtent; }
                            onTargetExtentChanged: Qt.callLater(applyExtent)
                            Component.onCompleted: {
                                if (livePayload) payload = livePayload;
                                if (_instant) {
                                    extent = targetExtent;
                                    Qt.callLater(() => suppressInitialAnim = false);
                                } else {
                                    Qt.callLater(applyExtent);
                                }
                            }

                            width: dockRoot.isVerticalEdge ? dockRoot.itemCellSize : extent
                            height: dockRoot.isVerticalEdge ? extent : dockRoot.itemCellSize

                            z: dockRoot.draggingKey === delegateRoot.itemKey ? 100 : 0

                            readonly property real targetOffset: {
                                if (dockRoot.draggingKey === "") return 0;
                                if (dockRoot.draggingKey === delegateRoot.itemKey) {
                                    const stride = dockModelImpl.itemStride;
                                    const _rev = dockModelImpl.viewModelRevision;
                                    const layoutIndex = dockModelImpl.layoutIndexOf(delegateRoot.itemKey);
                                    let clampedPos = Math.max(0, Math.min((dockRoot.pinnedApps.length - 1) * stride, dockRoot.dragPos - dockRoot.dragClickOffset));
                                    return clampedPos - (layoutIndex * stride);
                                }
                                return 0;
                            }

                            property real visualOffset: targetOffset

                            Behavior on visualOffset {
                                enabled: dockModelImpl.isReleasing || (dockRoot.draggingKey !== delegateRoot.itemKey)
                                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                            }

                            Loader {
                                id: inner
                                width: dockRoot.isVerticalEdge || !delegateRoot.isSeparator ? dockRoot.itemCellSize : 1
                                height: !dockRoot.isVerticalEdge || !delegateRoot.isSeparator ? dockRoot.itemCellSize : 1
                                x: dockRoot.isVerticalEdge ? (delegateRoot.width - width) / 2 : ((delegateRoot.width - width) / 2) + delegateRoot.visualOffset
                                y: dockRoot.isVerticalEdge ? ((delegateRoot.height - height) / 2) + delegateRoot.visualOffset : (delegateRoot.height - height) / 2
                                transformOrigin: Item.Center
                                scale: delegateRoot.fullExtent > 0 ? delegateRoot.extent / delegateRoot.fullExtent : 0
                                sourceComponent: delegateRoot.isSeparator ? separatorComponent : dockItemComponent
                            }

                            Binding {
                                target: inner.item
                                property: "modelData"
                                value: delegateRoot.payload
                                when: inner.item !== null
                            }

                            readonly property string itemKey: _key
                            readonly property bool isPinned: delegateRoot.payload ? !!delegateRoot.payload.isPinned : false
                            readonly property string appId: delegateRoot.payload ? (delegateRoot.payload.appId ?? "") : ""
                            readonly property var toplevels: inner.item ? inner.item.toplevels : []
                        }
                    }
                }

                DockSection {
                    active: Config.floatingDock.showTrash
                    sourceComponent: DockSeparator {}
                }

                DockSection {
                    id: trashLoader
                    active: Config.floatingDock.showTrash
                    sourceComponent: DockTrashBin {
                        dockRoot: pill
                        onBusyChanged: dockRoot.trashBusy = busy
                        onFileHoveringChanged: dockRoot.trashFileHovering = fileHovering
                    }
                }
            }
        }
    }

    Component {
        id: separatorComponent

        Item {
            property var modelData
            readonly property var toplevels: []
            width: dockRoot.isVerticalEdge ? dockRoot.itemCellSize : 1
            height: dockRoot.isVerticalEdge ? 1 : dockRoot.itemCellSize

            Rectangle {
                anchors.centerIn: parent
                width: dockRoot.isVerticalEdge ? dockRoot.itemCellSize * 0.6 : 1
                height: dockRoot.isVerticalEdge ? 1 : dockRoot.itemCellSize * 0.6
                radius: 0.5
                color: Qt.alpha(Colors.md3.outline_variant, 0.6)
            }

            opacity: 0
            Component.onCompleted: opacity = 1
            Behavior on opacity {
                NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
            }
        }
    }

    Component {
        id: dockItemComponent

        DockItem {
            dockRoot: pill
            hoverPopup: hoverPopup
        }
    }

    DockHover {
        id: hoverPopup
        dockRoot: pill
        dockEdge: dockRoot.edge
        anchorToItem: true
    }
}
