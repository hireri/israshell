import QtQuick
import Quickshell.Widgets
import "carousel.js" as Geometry

Item {
    id: root

    property var model: []
    property Component delegate
    property string kind: "multiBrowse"
    property real itemSize: 160
    property real spacing: 8
    property real leadingPadding: 16
    property real trailingPadding: 16
    property real verticalPadding: 8
    property real itemRadius: 28
    property real smallWidth: 48

    property real position: 0
    readonly property int count: root.model?.length ?? 0
    readonly property int currentIndex: Math.round(root.position)

    signal activated(int index)

    function scrollTo(index) {
        snap.stop();
        snap.to = Math.max(0, Math.min(root.count - 1, index));
        snap.restart();
    }

    readonly property real _inner: Math.max(0, root.width - root.leadingPadding - root.trailingPadding)
    readonly property var _slots: Geometry.slots(root.kind, root._inner, root.spacing, root.itemSize, root.smallWidth)
    readonly property real _contentWidth: Math.max.apply(null, root._slots)
    readonly property real _step: root._contentWidth + root.spacing
    readonly property var _frame: Geometry.frame(root._slots, root.kind === "uncontained" ? root.itemSize : root.smallWidth, root.spacing, root.leadingPadding, root.position, root.count)

    clip: true

    onCountChanged: root.position = Math.max(0, Math.min(root.position, root.count - 1))

    NumberAnimation {
        id: snap
        target: root
        property: "position"
        duration: 320
        easing.type: Easing.OutCubic
    }

    Timer {
        id: settle
        interval: 140
        onTriggered: root.scrollTo(Math.round(root.position))
    }

    DragHandler {
        id: drag
        target: null
        acceptedButtons: Qt.LeftButton
        yAxis.enabled: false

        property real startPosition
        property real lastX
        property real lastTime
        property real velocity

        onActiveChanged: {
            if (active) {
                snap.stop();
                settle.stop();
                startPosition = root.position;
                lastX = 0;
                lastTime = Date.now();
                velocity = 0;
            } else {
                const v = Date.now() - lastTime > 120 ? 0 : velocity;
                root.scrollTo(Math.round(root.position - (v / root._step) * 0.25));
            }
        }

        onTranslationChanged: {
            if (!active)
                return;
            const now = Date.now();
            if (now > lastTime)
                velocity = 0.7 * velocity + 0.3 * ((translation.x - lastX) / (now - lastTime) * 1000);
            lastX = translation.x;
            lastTime = now;
            root.position = Math.max(0, Math.min(startPosition - translation.x / root._step, root.count - 1));
        }
    }

    WheelHandler {
        target: null
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            event.accepted = true;
            const pixel = Math.abs(event.pixelDelta.x) > Math.abs(event.pixelDelta.y) ? event.pixelDelta.x : event.pixelDelta.y;
            if (pixel !== 0) {
                snap.stop();
                root.position = Math.max(0, Math.min(root.position - pixel / root._step, root.count - 1));
                settle.restart();
            } else {
                const notch = Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y) ? event.angleDelta.x : event.angleDelta.y;
                const from = snap.running ? snap.to : Math.round(root.position);
                root.scrollTo(from + (notch < 0 ? 1 : -1));
            }
        }
    }

    Repeater {
        model: root.model

        delegate: ClippingRectangle {
            id: tile

            required property var modelData
            required property int index

            readonly property bool near: x + width > -root.width * 0.5 && x < root.width * 1.5
            property bool seen: false
            onNearChanged: {
                if (near)
                    seen = true;
            }
            Component.onCompleted: seen = near

            x: root._frame.xs[index] ?? 0
            y: root.verticalPadding
            width: root._frame.ws[index] ?? 0
            height: root.height - root.verticalPadding * 2
            visible: width > 0.5 && x + width > 0 && x < root.width
            radius: Math.min(root.itemRadius, width / 2, height / 2)
            color: "transparent"
            clip: true

            Loader {
                anchors.centerIn: parent
                width: root._contentWidth
                height: parent.height
                active: tile.seen
                sourceComponent: root.delegate
                onLoaded: {
                    item.modelData = tile.modelData;
                    item.index = tile.index;
                    if (item.hasOwnProperty("visibleWidth"))
                        item.visibleWidth = Qt.binding(() => tile.width);
                }
            }

            TapHandler {
                onTapped: root.activated(tile.index)
            }
        }
    }
}
