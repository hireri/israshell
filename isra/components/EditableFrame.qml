import QtQuick
import qs.style
import qs.services

Item {
    id: root

    required property real trackX
    required property real trackY
    required property real trackWidth
    required property real trackHeight

    property string label: ""
    property bool interactive: true
    property bool showChrome: true
    property bool movable: true
    property bool resizable: true
    property bool uniformScale: false
    property real cornerRadius: 12
    property Component quickActions: null

    property string widgetId: ""
    property var widgetScreen: null
    readonly property bool selected: EditModeService.isSelected(root.widgetId, root.widgetScreen)

    signal moveStarted
    signal moveDelta(real dx, real dy)
    signal moveCommitted
    signal resizeStarted
    signal resizeDelta(real dw, real dh)
    signal resizeCommitted
    signal contextRequested(real x, real y)

    x: trackX
    y: trackY
    width: trackWidth
    height: trackHeight
    z: 30

    property bool animateTracking: true

    Behavior on x {
        enabled: root.animateTracking
        NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
    }
    Behavior on y {
        enabled: root.animateTracking
        NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
    }
    Behavior on width {
        enabled: root.animateTracking
        NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
    }
    Behavior on height {
        enabled: root.animateTracking
        NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
    }

    readonly property bool _hovered: bodyMouse.containsMouse || resizeMouse.containsMouse || bodyMouse.pressed || resizeMouse.pressed

    readonly property bool _showOutline: root.showChrome && (root.selected || root._hovered)
    readonly property bool _showActions: root.showChrome && root.selected

    function _takeSelection(): void {
        if (root.showChrome && root.widgetId !== "")
            EditModeService.select(root.widgetId, root.widgetScreen);
    }

    Rectangle {
        id: outlineRect
        anchors.fill: parent
        radius: root.cornerRadius
        color: "transparent"
        border.width: 2
        border.color: Colors.md3.primary
        opacity: root._showOutline ? (root.selected ? 1 : 0.5) : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
    }

    Row {
        id: chipRow
        anchors.left: parent.left
        anchors.bottom: parent.top
        anchors.bottomMargin: 6
        spacing: 6

        Rectangle {
            id: labelChip
            opacity: (root._showOutline && root.label !== "") ? 1 : 0
            visible: opacity > 0
            radius: height / 2
            height: 22
            width: labelText.implicitWidth + 16
            color: Colors.md3.primary_container

            Behavior on opacity {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            Text {
                id: labelText
                anchors.centerIn: parent
                text: root.label
                color: Colors.md3.on_primary_container
                font.family: Config.fontFamily
                font.pixelSize: 11
                font.weight: Font.Medium
            }
        }

        Rectangle {
            id: actionsChip
            opacity: (root._showActions && root.quickActions !== null) ? 1 : 0
            visible: opacity > 0
            radius: height / 2
            height: 22
            width: (quickActionsLoader.item?.width ?? 16) + 6
            color: Colors.md3.surface_container_high

            Behavior on opacity {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            Loader {
                id: quickActionsLoader
                anchors.centerIn: parent
                active: root.quickActions !== null
                sourceComponent: root.quickActions
            }
        }
    }

    MouseArea {
        id: bodyMouse
        anchors.fill: parent
        visible: root.interactive && root.movable
        enabled: root.interactive && root.movable
        hoverEnabled: true
        cursorShape: moved ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        preventStealing: true

        property real pressX: 0
        property real pressY: 0
        property bool moved: false
        readonly property real slop: 4
        property real _startX: 0
        property real _startY: 0

        onPressed: mouse => {
            root._takeSelection();
            const scene = mapToItem(root.parent, mouse.x, mouse.y);
            pressX = scene.x;
            pressY = scene.y;
            moved = false;
            _startX = root.trackX;
            _startY = root.trackY;
        }
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                root._takeSelection();
                const scene = mapToItem(root.parent, mouse.x, mouse.y);
                root.contextRequested(scene.x, scene.y);
            }
        }
        onPositionChanged: mouse => {
            if (!pressed || !(pressedButtons & Qt.LeftButton))
                return;
            const scene = mapToItem(root.parent, mouse.x, mouse.y);
            if (!moved && (Math.abs(scene.x - pressX) > slop || Math.abs(scene.y - pressY) > slop)) {
                moved = true;
                root.moveStarted();
            }
            if (moved) {
                let dx = scene.x - pressX;
                let dy = scene.y - pressY;
                const bounds = root.parent;
                if (bounds) {
                    const maxX = Math.max(0, bounds.width - root.trackWidth);
                    const maxY = Math.max(0, bounds.height - root.trackHeight);
                    dx = Math.min(Math.max(dx, -_startX), maxX - _startX);
                    dy = Math.min(Math.max(dy, -_startY), maxY - _startY);
                }
                root.moveDelta(dx, dy);
            }
        }
        onReleased: mouse => {
            if (moved && mouse.button === Qt.LeftButton)
                root.moveCommitted();
            moved = false;
        }
    }

    Item {
        id: resizeHandle
        visible: root._showActions && root.resizable
        width: 16
        height: 16
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: -8 + Math.round(root.cornerRadius * 0.3)
        anchors.bottomMargin: -8 + Math.round(root.cornerRadius * 0.3)
        z: 2

        Rectangle {
            id: handleBg
            anchors.fill: parent
            radius: 4
            color: Colors.md3.primary
            Behavior on color {
                ColorAnimation { duration: 100 }
            }
        }

        MouseArea {
            id: resizeMouse
            anchors.fill: parent
            anchors.margins: -6
            enabled: root.interactive && root.resizable
            hoverEnabled: true
            cursorShape: Qt.SizeFDiagCursor
            preventStealing: true

            property real pressX: 0
            property real pressY: 0

            onPressed: mouse => {
                root._takeSelection();
                const scene = mapToItem(root.parent, mouse.x, mouse.y);
                pressX = scene.x;
                pressY = scene.y;
                root.resizeStarted();
            }
            onPositionChanged: mouse => {
                if (!pressed)
                    return;
                const scene = mapToItem(root.parent, mouse.x, mouse.y);
                const dx = scene.x - pressX;
                const dy = scene.y - pressY;
                if (root.uniformScale) {
                    const d = (dx + dy) / 2;
                    root.resizeDelta(d, d);
                } else {
                    root.resizeDelta(dx, dy);
                }
            }
            onReleased: root.resizeCommitted()
        }
    }
}
