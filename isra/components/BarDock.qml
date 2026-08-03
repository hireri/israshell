pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQml.Models
import QtQuick.Layouts

import qs.style

Rectangle {
    id: dockRoot

    readonly property int orientation: 0

    readonly property int itemGlyphSize: 18
    readonly property int itemCellSize: 28
    readonly property int itemSpacing: 6

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
    readonly property int dragTargetIndex: dockModelImpl.dragTargetIndex
    readonly property real dragPos: dockModelImpl.dragPos
    readonly property real dragClickOffset: dockModelImpl.dragClickOffset

    readonly property var displayModel: dockModelImpl.displayModel

    function beginDrag(key: string, startPos: real): void { dockModelImpl.beginDrag(key, startPos); }
    function updateDrag(key: string, scenePos: real): void { dockModelImpl.updateDrag(key, scenePos); }
    function endDrag(): void { dockModelImpl.endDrag(); }

    readonly property Item rowContainer: dockListView.contentItem

    function findDockItemByKey(key: string): var {
        let children = dockListView.contentItem.children;
        for (let i = 0; i < children.length; i++) {
            let child = children[i];
            if (child && child.itemKey === key) return child;
        }
        return null;
    }

    onDisplayModelChanged: hoverPopup.syncWithModel()

    implicitWidth: listContainer.implicitWidth + leftPad + rightPad
    implicitHeight: 32

    readonly property int leftPad: 3
    readonly property int rightPad: 3

    color: Config.bar.transparentPills
        ? Qt.alpha(Colors.md3.secondary_container, 0)
        : Qt.alpha(Colors.md3.surface_container_high, 0.8)

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    radius: 20

    width: implicitWidth
    height: implicitHeight

    Item {
        id: listContainer
        anchors.left: parent.left
        anchors.leftMargin: dockRoot.leftPad
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: Math.max(0, dockListView.contentWidth - dockRoot.itemSpacing)
        width: implicitWidth
        height: 32
        clip: false

        ListView {
            id: dockListView
            x: -dockRoot.itemSpacing / 2
            width: contentWidth
            height: 32
            orientation: ListView.Horizontal
            interactive: false
            spacing: 0
            clip: false

            model: dockModelImpl.viewModel
            cacheBuffer: 0

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

                readonly property int fullExtent: isSeparator
                    ? 1 + dockRoot.itemSpacing
                    : dockModelImpl.itemStride

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

                width: extent
                height: 32

                z: dockRoot.draggingKey === delegateRoot.itemKey ? 100 : 0

                readonly property real targetXOffset: {
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

                property real visualOffset: targetXOffset

                Behavior on visualOffset {
                    enabled: dockModelImpl.isReleasing || (dockRoot.draggingKey !== delegateRoot.itemKey)
                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }

                Loader {
                    id: inner

                    width: delegateRoot.isSeparator ? 1 : dockRoot.itemCellSize
                    height: delegateRoot.isSeparator ? 32 : dockRoot.itemCellSize
                    x: ((delegateRoot.width - width) / 2) + delegateRoot.visualOffset
                    y: (delegateRoot.height - height) / 2
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

    Component {
        id: separatorComponent

        Item {
            property var modelData
            readonly property var toplevels: []
            width: 1
            height: 32

            Rectangle {
                width: 1
                height: 18
                anchors.centerIn: parent
                radius: 0.5
                color: Qt.alpha(Colors.md3.outline_variant, 0.6)
            }
        }
    }

    Component {
        id: dockItemComponent

        DockItem {
            dockRoot: dockRoot
            hoverPopup: hoverPopup
        }
    }

    DockHover {
        id: hoverPopup
        dockRoot: dockRoot
    }
}
