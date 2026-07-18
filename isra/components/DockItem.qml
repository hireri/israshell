pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick

import qs.style

Item {
    id: root

    property var modelData: null
    required property Item dockRoot
    required property DockHover hoverPopup

    readonly property string appId: modelData ? (modelData.appId ?? "") : ""
    readonly property var toplevels: modelData ? (modelData.toplevels ?? []) : []
    readonly property bool isRunning: toplevels.length > 0
    readonly property bool isPinned: modelData ? !!modelData.isPinned : false
    readonly property string itemKey: modelData ? (modelData.key ?? "") : ""

    readonly property bool isActive: {
        for (let i = 0; i < toplevels.length; i++) {
            if (toplevels[i] && toplevels[i].activated) return true;
        }
        return false;
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

    readonly property string iconPath: {
        let name = desktopEntry ? desktopEntry.icon : root.appId;
        return Quickshell.iconPath(name, "application-x-executable");
    }

    property bool dragging: false
    property real dragStartMouseX: 0

    onDraggingChanged: {
        if (dragging) {
            root.hoverPopup.release(root);
        }
    }

    implicitWidth: 28
    implicitHeight: 28
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
        radius: 8
        color: root.isActive
            ? Qt.alpha(Colors.md3.primary, 0.15)
            : (mouseArea.containsMouse ? Qt.alpha(Colors.md3.on_surface_variant, 0.1) : "transparent")

        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        Image {
            id: appIcon
            anchors.centerIn: parent
            width: 18
            height: 18
            source: root.iconPath
            fillMode: Image.PreserveAspectFit
            asynchronous: true

            scale: mouseArea.containsMouse && !root.dragging ? 1.12 : 1.0

            Behavior on scale {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
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
                    color: root.isActive ? Colors.md3.primary : Colors.md3.outline

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

        onPressed: mouse => {
            pressLocalX = mouse.x;
            passedThreshold = false;
            
            let scenePos = root.mapToItem(root.dockRoot.rowContainer, mouse.x, 0);
            root.dragStartMouseX = scenePos.x;
        }

        onPositionChanged: mouse => {
            if (!root.isPinned || !pressed) return;

            let scenePos = root.mapToItem(root.dockRoot.rowContainer, mouse.x, 0);

            if (!passedThreshold) {
                if (Math.abs(scenePos.x - root.dragStartMouseX) < dragThreshold) return;
                passedThreshold = true;
                root.dragging = true;
                root.dockRoot.beginDrag(root.itemKey, scenePos.x);
            }

            root.dockRoot.updateDrag(root.itemKey, scenePos.x);
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
                        root.toplevels[0].activate();
                    } else {
                        root.lastFocusIndex = (root.lastFocusIndex + 1) % root.toplevels.length;
                        root.toplevels[root.lastFocusIndex].activate();
                    }
                } else {
                    if (root.desktopEntry) {
                        root.desktopEntry.execute();
                    } else {
                        Hyprland.dispatch("exec " + root.appId);
                    }
                }
            } else if (mouse.button === Qt.MiddleButton) {
                if (root.desktopEntry) {
                    root.desktopEntry.execute();
                } else {
                    Hyprland.dispatch("exec " + root.appId);
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