import QtQuick
import Quickshell.Widgets
import qs.style
import qs.services
import qs.icons

Item {
    id: root

    required property string tileId
    required property int size

    property bool editMode: false
    property bool removedMode: false

    property real targetX: 0
    property real targetY: 0
    property real targetWidth: 0
    property real tileHeight: 64

    property real unitWidth: 100
    property real gap: 8

    property bool isDragging: false
    property bool isResizing: false

    signal removeRequested
    signal restoreRequested
    signal bodyDragStarted(real sceneX, real sceneY)
    signal bodyDragMoved(real sceneX, real sceneY)
    signal bodyDragEnded
    signal resizePreview(int previewSize)
    signal resizeCommitted(int finalSize)

    function widthForSize(sz) {
        return (sz / 25) * unitWidth - gap;
    }

    property bool layoutReady: false

    x: isDragging ? _liveX : targetX
    y: isDragging ? _liveY : targetY
    width: isResizing ? Math.max(_minWidth, _snapWidth + _pullOffset) : targetWidth
    height: tileHeight

    Behavior on x {
        enabled: root.layoutReady && !root.isDragging
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
    }
    Behavior on y {
        enabled: root.layoutReady && !root.isDragging
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
    }
    Behavior on width {
        enabled: root.layoutReady && !root.isResizing
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    property real _liveX: targetX
    property real _liveY: targetY
    property int _previewSize: size

    property real _snapWidth: 0
    property bool _snapInstant: false
    Behavior on _snapWidth {
        enabled: !root._snapInstant
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }
    property real _pullOffset: 0

    NumberAnimation {
        id: settleAnim
        target: root
        property: "_pullOffset"
        to: 0
        duration: 120
        easing.type: Easing.OutCubic
        onFinished: root.isResizing = false
    }

    readonly property real _minWidth: widthForSize(25) * 0.72

    readonly property bool isWide: (isResizing ? _previewSize : size) === 100

    property bool _wideVisual: isWide
    onIsWideChanged: wideFadeTimer.restart()
    Timer {
        id: wideFadeTimer
        interval: 150
        onTriggered: root._wideVisual = root.isWide
    }

    readonly property var _bgSource: isWide ? wideLoader.item : compactLoader.item

    ClippingRectangle {
        id: tileBg
        anchors.fill: parent
        clip: true

        color: (root._bgSource && root._bgSource.bgColor !== undefined)
            ? root._bgSource.bgColor
            : Qt.alpha(Colors.md3.surface_container_high, Config.blurOpacity)
        radius: (root._bgSource && root._bgSource.bgRadius !== undefined)
            ? root._bgSource.bgRadius
            : 26

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on radius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        Loader {
            id: compactLoader
            anchors.fill: parent
            sourceComponent: QsTileService.compactComponentMap[root.tileId]
            opacity: (!root.isWide && !root._wideVisual) ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            Binding {
                target: compactLoader.item
                property: "forceOff"
                value: root.editMode
                when: compactLoader.status === Loader.Ready && compactLoader.item && compactLoader.item.hasOwnProperty("forceOff")
            }
        }

        Loader {
            id: wideLoader
            anchors.fill: parent
            sourceComponent: QsTileService.wideComponentMap[root.tileId]
            opacity: (root.isWide && root._wideVisual) ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            Binding {
                target: wideLoader.item
                property: "forceOff"
                value: root.editMode
                when: wideLoader.status === Loader.Ready && wideLoader.item && wideLoader.item.hasOwnProperty("forceOff")
            }
        }
    }

    Rectangle {
        id: hoverOutline
        anchors.fill: parent
        radius: tileBg.radius
        color: "transparent"
        border.width: 2
        border.color: (root.editMode && root._tileHovered) ? Colors.md3.primary : "transparent"
        z: 9

        Behavior on border.color { ColorAnimation { duration: 120 } }
    }

    MouseArea {
        anchors.fill: parent
        visible: root.editMode
        enabled: root.editMode
        acceptedButtons: Qt.RightButton
    }

    readonly property bool _tileHovered: bodyMouse.containsMouse || resizeMouse.containsMouse || isDragging || isResizing

    MouseArea {
        id: bodyMouse
        anchors.fill: parent
        visible: root.editMode
        enabled: root.editMode
        hoverEnabled: root.editMode
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        preventStealing: true

        property real pressX: 0
        property real pressY: 0
        property bool moved: false
        readonly property real slop: 7

        onPressed: mouse => {
            const scene = mapToItem(root.parent, mouse.x, mouse.y);
            pressX = scene.x;
            pressY = scene.y;
            moved = false;
        }
        onPositionChanged: mouse => {
            if (!pressed || root.removedMode)
                return;
            const scene = mapToItem(root.parent, mouse.x, mouse.y);
            if (!moved && (Math.abs(scene.x - pressX) > slop || Math.abs(scene.y - pressY) > slop)) {
                moved = true;
                root._liveX = root.x;
                root._liveY = root.y;
                root.isDragging = true;
                root.bodyDragStarted(scene.x, scene.y);
            }
            if (moved) {
                root._liveX += scene.x - pressX;
                root._liveY += scene.y - pressY;
                pressX = scene.x;
                pressY = scene.y;
                root.bodyDragMoved(root._liveX + root.width / 2, root._liveY + root.height / 2);
            }
        }
        onReleased: {
            if (moved) {
                root.targetX = root._liveX;
                root.targetY = root._liveY;
                root.isDragging = false;
                root.bodyDragEnded();
            } else if (root.removedMode) {
                root.restoreRequested();
            } else {
                root.removeRequested();
            }
        }
    }

    Rectangle {
        id: badge
        visible: root.editMode
        opacity: (visible && !root.isResizing) ? 1 : 0
        width: 18
        height: 18
        radius: 9
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: -4
        anchors.rightMargin: -4
        color: Colors.md3.primary_container
        z: 10

        Behavior on opacity { NumberAnimation { duration: 120 } }

        MaterialIcon {
            anchors.centerIn: parent
            name: root.removedMode ? "add" : "remove"
            iconSize: 12
            color: Colors.md3.on_primary_container
        }
    }

    Rectangle {
        id: resizeHandle
        visible: root.editMode && !root.removedMode
        opacity: root._tileHovered ? 1 : 0
        width: 7
        height: 16
        radius: 3.5
        color: Colors.md3.primary
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: -width / 2
        z: 11

        Behavior on opacity { NumberAnimation { duration: 120 } }

        MouseArea {
            id: resizeMouse
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: root.editMode && !root.removedMode
            enabled: root.editMode && !root.removedMode
            cursorShape: Qt.SizeHorCursor
            preventStealing: true

            readonly property var steps: [25, 50, 75, 100]

            property real startSceneX: 0
            property int startIdx: 0

            readonly property real pull: 0.38

            onPressed: mouse => {
                settleAnim.stop();
                const scene = mapToItem(root.parent, mouse.x, mouse.y);
                startSceneX = scene.x;
                startIdx = Math.max(0, steps.indexOf(root.size));
                root._previewSize = root.size;
                root._pullOffset = 0;
                root._snapInstant = true;
                root._snapWidth = root.width;
                root._snapInstant = false;
                root.isResizing = true;
            }
            onPositionChanged: mouse => {
                if (!pressed)
                    return;
                const scene = mapToItem(root.parent, mouse.x, mouse.y);
                const rawSteps = (scene.x - startSceneX) / root.unitWidth;

                const wantedIdx = startIdx + Math.round(rawSteps);
                const clampedIdx = Math.max(0, Math.min(steps.length - 1, wantedIdx));
                const size = steps[clampedIdx];

                let remaining = rawSteps - (clampedIdx - startIdx);
                remaining = Math.max(-1.0, Math.min(1.0, remaining));
                const newPull = remaining * root.unitWidth * pull;

                if (size !== root._previewSize) {
                    const shownWidth = root.width;
                    root._snapInstant = true;
                    root._snapWidth = shownWidth - newPull;
                    root._snapInstant = false;

                    root._previewSize = size;
                    root.resizePreview(size);
                }

                root._pullOffset = newPull;
                root._snapWidth = root.widthForSize(size);
            }
            onReleased: {
                root.resizeCommitted(root._previewSize);
                settleAnim.restart();
            }
        }
    }
}
