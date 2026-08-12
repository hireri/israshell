import QtQuick
import QtQuick.Effects
import Quickshell
import qs.style
import qs.services
import qs.icons

Item {
    id: root
    required property var modelData

    anchors.fill: parent

    property real _cx: 0
    property real _cy: 0

    property bool _isInitializing: true
    property bool animate: true

    property var _currentTime: new Date()

    function updatePosition() {
        if (Config.clock.manualPos ?? false) return
        const pos = Config.clockPositions?.[modelData?.name]
        if (pos) {
            if (pos.x === _cx && pos.y === _cy) return
            _cx = pos.x
            _cy = pos.y
        } else {
            _cx = (modelData?.width  ?? root.width)  * 0.82
            _cy = (modelData?.height ?? root.height) * 0.10
        }
    }

    function loadSavedPosition() {
        const pos = Config.clockPositions?.[modelData?.name]
        if (pos) {
            _cx = pos.x
            _cy = pos.y
        } else {
            _cx = (modelData?.width  ?? root.width)  * 0.82
            _cy = (modelData?.height ?? root.height) * 0.10
        }
    }

    Connections {
        target: Config
        function onClockPositionsChanged() {
            updatePosition();
        }
    }

    Component.onCompleted: {
        if (modelData === Quickshell.screens[0])
            WallpaperService.reportClockSize(clockRoot.implicitWidth, clockRoot.implicitHeight);
    }

    onWidthChanged: {
        if (!root._isInitializing || width === 0) return
        if (root.forceCentered) {
            clockRoot.currentCx = (modelData?.width  ?? root.width)  / 2
            clockRoot.currentCy = (modelData?.height ?? root.height) / 2
            root._isInitializing = false
            return
        }
        loadSavedPosition()
        clockRoot.currentCx = root._cx
        clockRoot.currentCy = root._cy
        Qt.callLater(() => {
            root._isInitializing = false
            clockRoot.currentCx = clockRoot.targetCx
            clockRoot.currentCy = clockRoot.targetCenterY
        })
    }

    Connections {
        target: clockRoot
        function onImplicitWidthChanged() {
            if (root.modelData === Quickshell.screens[0])
                Qt.callLater(() => WallpaperService.reportClockSize(clockRoot.implicitWidth, clockRoot.implicitHeight));
        }
        function onImplicitHeightChanged() {
            if (root.modelData === Quickshell.screens[0])
                Qt.callLater(() => WallpaperService.reportClockSize(clockRoot.implicitWidth, clockRoot.implicitHeight));
        }
    }

    Timer {
        interval: clockRoot._layoutMode === 3 ? 50 : 500
        running: true
        repeat: true
        onTriggered: {
            const now = new Date();
            if (clockRoot._layoutMode === 3) {
                root._currentTime = now;
            } else if (clockRoot._layoutMode === 1) {
                if (now.getMinutes() !== root._currentTime.getMinutes())
                    root._currentTime = now;
            } else {
                root._currentTime = now;
            }
        }
    }

    property real _dragDx: 0
    property real _dragDy: 0
    property bool _dragActive: false

    property real _resizeScaleDelta: 0
    property bool _resizeActive: false
    property var _resizeFactorBounds: ({ min: 1, max: 1 })
    property real _resizeStartW: 1
    property real _resizeStartH: 1

    function _clockFactorBounds() {
        const layout = Config.clock.layout;
        const fields = ClockSizing.resizableFieldsForLayout(layout);

        let min = 0;
        let max = Infinity;
        let matched = false;
        for (const field of fields) {
            const bounds = ClockSizing.boundsFor(layout, field);
            const current = Config.clock[field] ?? ClockSizing.scaledDefaultFor(field);
            if (!bounds || current <= 0) continue;
            matched = true;
            min = Math.max(min, bounds.min / current);
            max = Math.min(max, bounds.max / current);
        }

        if (!matched) return { min: 1, max: 1 };
        return { min: min, max: Math.max(min, max) };
    }

    property bool forceVisible: false
    property bool forceCentered: false

    Item {
        id: clockRoot

        readonly property bool isClockEnabled: Config.desktopClock || root.forceVisible

        readonly property bool isLockedPosition: root.forceCentered || LockscreenService.lockVisualActive || LockscreenService.locked

        readonly property real targetCx: isLockedPosition
            ? (modelData?.width  ?? root.width)  / 2
            : root._cx

        readonly property real targetCenterY: isLockedPosition
            ? (modelData?.height ?? root.height) / 2
            : root._cy

        property real currentCx: targetCx
        property real currentCy: targetCenterY

        x: currentCx - width / 2 + root._dragDx
        y: currentCy - height / 2 + root._dragDy

        property bool _snapAfterDrag: false

        enabled: isClockEnabled
        visible: opacity > 0
        opacity: isClockEnabled ? 1.0 : 0.0

        Behavior on opacity {
            enabled: root.animate && !root._isInitializing
            NumberAnimation {
                duration: clockRoot.isClockEnabled ? 200 : 150
                easing.type: Easing.OutCubic
            }
        }

        Behavior on currentCx {
            enabled: root.animate && !root._isInitializing && !root._dragActive && !clockRoot._snapAfterDrag
            NumberAnimation {
                duration: 350
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1]
            }
        }
        Behavior on currentCy {
            enabled: root.animate && !root._isInitializing && !root._dragActive && !clockRoot._snapAfterDrag
            NumberAnimation {
                duration: 350
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1]
            }
        }

        Timer {
            id: lockAnimationDelay
            interval: 30
            repeat: false
            onTriggered: {
                clockRoot.currentCx = clockRoot.targetCx
                clockRoot.currentCy = clockRoot.targetCenterY
            }
        }

        onTargetCxChanged: {
            if (clockRoot.isLockedPosition) {
                lockAnimationDelay.restart()
            } else {
                lockAnimationDelay.stop()
                currentCx = targetCx
            }
        }
        
        onTargetCenterYChanged: {
            if (clockRoot.isLockedPosition) {
                lockAnimationDelay.restart()
            } else {
                lockAnimationDelay.stop()
                currentCy = targetCenterY
            }
        }

        Connections {
            target: root
            function on_CxChanged() {
                if (!clockRoot.isLockedPosition) clockRoot.currentCx = root._cx
            }
            function on_CyChanged() {
                if (!clockRoot.isLockedPosition) clockRoot.currentCy = root._cy
                }
        }

        readonly property real _configScale: Math.max(root._resizeFactorBounds.min, Math.min(root._resizeFactorBounds.max, 1.0 + root._resizeScaleDelta))

        scale: (!isClockEnabled ? 0.9 : (root._dragActive ? 1.06 : 1.0)) * _configScale
        transformOrigin: Item.Center
        Behavior on scale {
            enabled: root.animate && !root._isInitializing && !root._resizeActive
            NumberAnimation {
                duration: clockRoot.isClockEnabled ? (root._dragActive ? 220 : 200) : 150
                easing.type: Easing.OutCubic
            }
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: ((Config.clock.shadowBlur ?? 16) / 32)
            shadowColor: Qt.alpha("black", Config.clock.shadowOpacity ?? 0.2)
            shadowHorizontalOffset: Config.clock.shadowX ?? 0
            shadowVerticalOffset: Config.clock.shadowY ?? 4
        }

        HoverHandler {
            cursorShape: root._dragActive ? Qt.ClosedHandCursor : (clockEditFrame.interactive ? Qt.OpenHandCursor : Qt.ArrowCursor)
        }

        readonly property string _font: Config.clock.fontFamily !== "" ? Config.clock.fontFamily : Config.fontFamily
        readonly property color _textColor: Colors.md3[Config.clock.colorRole] ?? Colors.md3.on_surface
        readonly property color _subColor: Colors.md3[Config.clock.subColorRole] ?? Colors.md3.on_surface_variant

        readonly property int _autoHalign: {
            const screenW = modelData?.width ?? root.width
            if (screenW <= 0) return Text.AlignHCenter
            const third = screenW / 3
            if (clockRoot.targetCx < third) return Text.AlignLeft
            if (clockRoot.targetCx > third * 2) return Text.AlignRight
            return Text.AlignHCenter
        }

        readonly property int _halign: Config.clock.align === "left" ? Text.AlignLeft
            : Config.clock.align === "right" ? Text.AlignRight
            : Config.clock.align === "auto" ? _autoHalign
            : Text.AlignHCenter
        readonly property int _layoutMode: Config.clock.layout === "horizontal" ? 0 : Config.clock.layout === "vertical" ? 1 : Config.clock.layout === "word" ? 2 : Config.clock.layout === "analog" ? 3 : 0
        readonly property int _analogSize: Config.clock.analogSize ?? 200
        readonly property bool _showSeconds: Config.clock.showSeconds ?? false
        readonly property bool _is12h: Config.hourFormat !== 0

        Loader {
            id: styleLoader
            
            property var activeComponent: null
            property var targetComponent: {
                switch (clockRoot._layoutMode) {
                case 0: return horizontalComp
                case 1: return verticalComp
                case 2: return wordComp
                case 3: return analogComp
                default: return horizontalComp
                }
            }
            
            onTargetComponentChanged: {
                if (root.animate && !root._isInitializing) {
                    transitionSeq.restart()
                } else {
                    styleLoader.activeComponent = styleLoader.targetComponent
                }
            }
            sourceComponent: activeComponent
            
            SequentialAnimation {
                id: transitionSeq
                ParallelAnimation {
                    NumberAnimation { target: styleLoader; property: "opacity"; to: 0; duration: 150; easing.type: Easing.OutCubic }
                    NumberAnimation { target: styleLoader; property: "scale"; to: 0.9; duration: 150; easing.type: Easing.OutCubic }
                }
                ScriptAction {
                    script: styleLoader.activeComponent = styleLoader.targetComponent
                }
                ParallelAnimation {
                    NumberAnimation { target: styleLoader; property: "opacity"; to: 1; duration: 200; easing.type: Easing.OutCubic }
                    NumberAnimation { target: styleLoader; property: "scale"; to: 1; duration: 200; easing.type: Easing.OutCubic }
                }
            }
            
            Component.onCompleted: {
                styleLoader.activeComponent = styleLoader.targetComponent
            }

            onLoaded: {
                item.currentTime  = Qt.binding(() => root._currentTime)
                item.clockFont    = Qt.binding(() => clockRoot._font)
                item.textColor    = Qt.binding(() => clockRoot._textColor)
                item.subColor     = Qt.binding(() => clockRoot._subColor)
                item.halign       = Qt.binding(() => clockRoot._halign)
                item.showSeconds  = Qt.binding(() => clockRoot._showSeconds)
                item.is12h        = Qt.binding(() => clockRoot._is12h)
                item.analogSize   = Qt.binding(() => clockRoot._analogSize)
            }
        }

        implicitWidth:  styleLoader.item?.implicitWidth  ?? 0
        implicitHeight: styleLoader.item?.implicitHeight ?? 0

        Component { id: horizontalComp; ClockHorizontal {} }
        Component { id: verticalComp;   ClockVertical   {} }
        Component { id: wordComp;       ClockWord       {} }
        Component { id: analogComp;     ClockAnalog     {} }
    }

    readonly property real _clockVisualWidth: clockRoot.width * clockRoot.scale
    readonly property real _clockVisualHeight: clockRoot.height * clockRoot.scale
    readonly property real _clockVisualX: clockRoot.x - (_clockVisualWidth - clockRoot.width) / 2
    readonly property real _clockVisualY: clockRoot.y - (_clockVisualHeight - clockRoot.height) / 2

    EditableFrame {
        id: clockEditFrame
        trackX: root._clockVisualX
        trackY: root._clockVisualY
        trackWidth: root._clockVisualWidth
        trackHeight: root._clockVisualHeight
        label: "Clock"
        interactive: (EditModeService.active || (Config.clock.manualPos ?? false)) && clockRoot.isClockEnabled
        showChrome: EditModeService.active
        movable: true
        resizable: EditModeService.active
        uniformScale: true
        cornerRadius: 16

        quickActions: Component {
            Rectangle {
                readonly property bool _manualPos: Config.clock.manualPos ?? false
                width: 16
                height: 16
                radius: 8
                color: pinMouse.containsMouse ? Qt.alpha(Colors.md3.on_primary_container, 0.15) : "transparent"

                Behavior on color {
                    ColorAnimation { duration: 100 }
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    name: "keep"
                    filled: parent._manualPos
                    iconSize: 12
                    color: Colors.md3.on_primary_container
                }

                MouseArea {
                    id: pinMouse
                    anchors.fill: parent
                    anchors.margins: -3
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Config.update({
                        clock: Object.assign({}, Config.clock, { manualPos: !(Config.clock.manualPos ?? false) })
                    })
                }
            }
        }

        onMoveStarted: root._dragActive = true
        onMoveDelta: (dx, dy) => {
            root._dragDx = dx;
            root._dragDy = dy;
        }
        onMoveCommitted: {
            root._dragActive = false;

            const newCx = root._cx + root._dragDx;
            const newCy = root._cy + root._dragDy;
            root._dragDx = 0;
            root._dragDy = 0;

            const positions = Object.assign({}, Config.clockPositions ?? {});
            positions[root.modelData.name] = {
                x: newCx,
                y: newCy
            };
            Config.update({
                clockPositions: positions,
                clock: Object.assign({}, Config.clock, { manualPos: true })
            });

            root._cx = newCx;
            root._cy = newCy;

            clockRoot._snapAfterDrag = true;
            clockRoot.currentCx = clockRoot.targetCx;
            clockRoot.currentCy = clockRoot.targetCenterY;
            clockRoot._snapAfterDrag = false;
        }
        onResizeStarted: {
            root._resizeActive = true;
            root._resizeScaleDelta = 0;
            root._resizeStartW = clockEditFrame.trackWidth;
            root._resizeStartH = clockEditFrame.trackHeight;
            root._resizeFactorBounds = root._clockFactorBounds();
        }
        onResizeDelta: (dw, dh) => {
            root._resizeScaleDelta = 2 * (dw + dh) / Math.max(1, root._resizeStartW + root._resizeStartH);
        }
        onResizeCommitted: {
            const bounds = root._resizeFactorBounds;
            const factor = Math.max(bounds.min, Math.min(bounds.max, 1.0 + root._resizeScaleDelta));
            root._resizeScaleDelta = 0;
            root._resizeActive = false;

            const changes = {};
            for (const field of ClockSizing.scaledFields()) {
                const b = ClockSizing.scaledBoundsFor(field);
                const current = Config.clock[field] ?? ClockSizing.scaledDefaultFor(field);
                changes[field] = Math.max(b.min, Math.min(b.max, Math.round(current * factor)));
            }

            Config.update({
                clock: Object.assign({}, Config.clock, changes)
            });
        }
    }
}