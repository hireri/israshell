pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects
import QtQuick

import qs.style
import qs.services

Item {
    id: root

    property var modelData: null
    required property Item dockRoot
    required property DockHover hoverPopup

    readonly property bool isVertical: dockRoot.orientation === 1

    readonly property int glyphSize: dockRoot.itemGlyphSize ?? 18
    readonly property int cellSize: dockRoot.itemCellSize ?? 28

    readonly property string appId: modelData ? (modelData.appId ?? "") : ""
    readonly property var toplevels: modelData ? (modelData.toplevels ?? []) : []
    readonly property bool isRunning: toplevels.length > 0
    readonly property bool isPinned: modelData ? !!modelData.isPinned : false
    readonly property string itemKey: modelData ? (modelData.key ?? "") : ""

    readonly property bool isActive: {
        for (let i = 0; i < toplevels.length; i++) {
            const tl = toplevels[i];
            if (!tl)
                continue;
            if (tl.activated === true)
                return true;
            if (tl.address !== undefined && CompositorService.activeWindow
                && tl.address === CompositorService.activeWindow.address)
                return true;
        }
        return false;
    }

    function focusToplevel(tl: var): void {
        if (!tl)
            return;
        if (typeof tl.activate === "function")
            tl.activate();
        else if (tl.address !== undefined)
            CompositorService.focusWindow(tl.address);
    }

    property int lastFocusIndex: 0
    property var desktopEntry: null

    function updateDesktopEntry(): void {
        if (!dockRoot || !root.appId) {
            desktopEntry = null;
            return;
        }
        desktopEntry = dockRoot.getDesktopEntry(root.appId);
    }

    onAppIdChanged: updateDesktopEntry()

    Connections {
        target: DesktopEntries
        function onApplicationsChanged(): void {
            root.updateDesktopEntry();
        }
    }

    Component.onCompleted: {
        updateDesktopEntry();
    }

    Component.onDestruction: {
        if (root.hoverPopup)
            root.hoverPopup.forget(root);
    }

    readonly property string iconPath: {
        let name = desktopEntry ? desktopEntry.icon : root.appId;
        return Quickshell.iconPath(name, "application-x-executable");
    }

    property bool dragging: false
    property real dragStartPos: 0

    onDraggingChanged: {
        if (dragging) {
            root.hoverPopup.release(root);
        }
    }

    implicitWidth: cellSize
    implicitHeight: cellSize
    width: implicitWidth
    height: implicitHeight
    z: dragging ? 100 : 0

    Behavior on scale {
        enabled: !root.dragging
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
    }

    scale: dragging ? 1.15 : 1.0

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.isActive
            ? Colors.md3.secondary_container
            : (mouseArea.containsMouse ? Qt.alpha(Colors.md3.on_surface, 0.08) : Qt.alpha(Colors.md3.secondary_container, 0))

        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        IconImage {
            id: appIcon
            anchors.centerIn: parent
            implicitSize: root.glyphSize
            source: root.iconPath
            asynchronous: true
            visible: !Config.tintIcons

            scale: mouseArea.containsMouse && !root.dragging ? 1.12 : 1.0

            Behavior on scale {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }
        }

        Loader {
            active: Config.tintIcons
            anchors.fill: appIcon
            scale: appIcon.scale
            sourceComponent: Colorize {
                source: appIcon
                hue: Qt.color(Colors.md3.on_surface).hslHue
                saturation: Qt.color(Colors.md3.on_surface).hslSaturation
                lightness: 0.0
            }
        }

        Row {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 2
            visible: root.isRunning

            Repeater {
                model: Math.min(root.toplevels.length, 3)

                delegate: Rectangle {
                    width: root.isActive ? 5 : 3
                    height: 3
                    radius: 1.5
                    color: root.isActive ? Colors.md3.on_secondary_container : Colors.md3.outline

                    Behavior on width {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: root.isPinned && root.dragging ? Qt.ClosedHandCursor : Qt.ArrowCursor

        readonly property int dragThreshold: 6
        property real pressLocalX: 0
        property bool passedThreshold: false
        property bool suppressNextClick: false

        function scenePointOf(mouse): point {
            return root.mapToItem(root.dockRoot.rowContainer, mouse.x, mouse.y);
        }

        onPressed: mouse => {
            passedThreshold = false;
            let p = scenePointOf(mouse);
            root.dragStartPos = root.isVertical ? p.y : p.x;
        }

        onPositionChanged: mouse => {
            if (!root.isPinned || !pressed) return;

            let p = scenePointOf(mouse);
            let scenePos = root.isVertical ? p.y : p.x;

            if (!passedThreshold) {
                if (Math.abs(scenePos - root.dragStartPos) < dragThreshold) return;
                passedThreshold = true;
                root.dragging = true;
                root.dockRoot.beginDrag(root.itemKey, scenePos);
            }

            root.dockRoot.updateDrag(root.itemKey, scenePos);
            if (root.dockRoot.updateDragPoint) root.dockRoot.updateDragPoint(p);
        }

        onReleased: {
            if (root.dragging) {
                root.dragging = false;
                suppressNextClick = true;
                root.dockRoot.endDrag();
            }
        }

        onClicked: mouse => {
            if (suppressNextClick) {
                suppressNextClick = false;
                return;
            }
            if (mouse.button === Qt.LeftButton) {
                if (root.isRunning) {
                    if (root.toplevels.length === 1) {
                        root.focusToplevel(root.toplevels[0]);
                    } else {
                        root.lastFocusIndex = (root.lastFocusIndex + 1) % root.toplevels.length;
                        root.focusToplevel(root.toplevels[root.lastFocusIndex]);
                    }
                } else {
                    if (root.desktopEntry) {
                        root.desktopEntry.execute();
                    } else {
                        CompositorService.exec(root.appId);
                    }
                }
            } else if (mouse.button === Qt.MiddleButton) {
                if (root.desktopEntry) {
                    root.desktopEntry.execute();
                } else {
                    CompositorService.exec(root.appId);
                }
            } else if (mouse.button === Qt.RightButton) {
                root.dockRoot.togglePinned(root.appId);
            }
        }

        onEntered: {
            if (root.isRunning && !root.dragging && dockRoot.draggingKey === "") {
                root.hoverPopup.request(root);
            }
        }
        onExited: {
            root.hoverPopup.release(root);
        }
    }
}