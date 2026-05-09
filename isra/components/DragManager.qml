import QtQuick

MouseArea {
    id: root

    hoverEnabled: false
    acceptedButtons: Qt.LeftButton

    property bool interactive: true
    property bool automaticallyReset: true

    readonly property real dragDiffX: _dragDiffX
    readonly property real dragDiffY: _dragDiffY
    property real startX: 0
    property real startY: 0

    signal dragReleased(diffX: real, diffY: real, velocityX: real)

    property bool dragging: false
    property real _dragDiffX: 0
    property real _dragDiffY: 0

    property int _lockDir: 0
    readonly property real _lockThreshold: 8

    property real _velX: 0
    property real _lastMouseX: 0
    property real _lastTime: 0

    function resetDrag() {
        _dragDiffX = 0;
        _dragDiffY = 0;
        _lockDir = 0;
        _velX = 0;
        dragging = false;
        preventStealing = false;
    }

    onPressed: mouse => {
        if (!root.interactive) {
            if (mouse.button === Qt.LeftButton)
                mouse.accepted = false;
            return;
        }
        startX = mouse.x;
        startY = mouse.y;
        _lockDir = 0;
        _velX = 0;
        _lastMouseX = mouse.x;
        _lastTime = Date.now();
        preventStealing = false;
    }

    onReleased: mouse => {
        if (!root.interactive)
            return;
        preventStealing = false;
        const vx = _velX;
        dragging = false;
        root.dragReleased(_dragDiffX, _dragDiffY, vx);
        if (root.automaticallyReset)
            root.resetDrag();
    }

    onPositionChanged: mouse => {
        if (!root.interactive)
            return;
        if (!(mouse.buttons & Qt.LeftButton))
            return;

        const dx = mouse.x - startX;
        const dy = mouse.y - startY;

        if (_lockDir === 0) {
            if (Math.abs(dx) > _lockThreshold || Math.abs(dy) > _lockThreshold) {
                _lockDir = Math.abs(dx) >= Math.abs(dy) ? 1 : 2;
                preventStealing = (_lockDir === 1);
                if (_lockDir === 2) {
                    mouse.accepted = false;
                    return;
                }
            }
        }

        if (_lockDir === 2) {
            mouse.accepted = false;
            return;
        }

        if (_lockDir === 1) {
            root._dragDiffX = dx;
            root._dragDiffY = dy;
            root.dragging = true;

            const now = Date.now();
            const dt = now - _lastTime;
            if (dt > 0) {
                const instant = (mouse.x - _lastMouseX) / dt;
                _velX = _velX * 0.6 + instant * 0.4;
            }
            _lastMouseX = mouse.x;
            _lastTime = now;
        }
    }

    onCanceled: {
        preventStealing = false;
        dragging = false;
        _dragDiffX = 0;
        _dragDiffY = 0;
        _lockDir = 0;
        _velX = 0;
    }
}
