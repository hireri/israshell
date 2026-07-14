import QtQuick
import QtQuick.Effects
import Quickshell
import qs.style
import qs.services

Item {
    id: root
    required property var modelData

    anchors.fill: parent

    property real _cx: 0
    property real _cy: 0

    property bool _isInitializing: true
    property bool animate: true

    Behavior on _cx {
        enabled: root.animate && !root._isInitializing && !Config.loading && !(Config.clock.manualPos ?? false)
        NumberAnimation {
            duration: 350
            easing.type: Easing.OutQuint
        }
    }
    Behavior on _cy {
        enabled: root.animate && !root._isInitializing && !Config.loading && !(Config.clock.manualPos ?? false)
        NumberAnimation {
            duration: 350
            easing.type: Easing.OutQuint
        }
    }

    property var _currentTime: new Date()

    function updatePosition() {
        if (Config.clock.manualPos ?? false) return
        const pos = Config.clockPositions?.[modelData?.name]
        if (!pos || (pos.x === _cx && pos.y === _cy)) return
        _cx = pos.x
        _cy = pos.y
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

    property bool forceVisible: false
    property bool forceCentered: false

    Item {
        id: clockRoot

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

        Behavior on currentCx {
            enabled: root.animate && !root._isInitializing && !dragHandler.active && !clockRoot._snapAfterDrag
            NumberAnimation {
                duration: 350
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1]
            }
        }
        Behavior on currentCy {
            enabled: root.animate && !root._isInitializing && !dragHandler.active && !clockRoot._snapAfterDrag
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

        scale: dragHandler.active ? 1.06 : 1.0
        transformOrigin: Item.Center
        Behavior on scale {
            enabled: root.animate
            NumberAnimation {
                duration: 220
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
            cursorShape: dragHandler.active ? Qt.ClosedHandCursor : (Config.clock.manualPos ?? false) ? Qt.OpenHandCursor : Qt.ArrowCursor
        }

        DragHandler {
            id: dragHandler
            enabled: Config.clock.manualPos ?? false
            target: null
            onActiveChanged: {
                if (!active) {
                    root._cx += root._dragDx;
                    root._cy += root._dragDy;
                    root._dragDx = 0;
                    root._dragDy = 0;

                    const positions = Object.assign({}, Config.clockPositions ?? {});
                    positions[root.modelData.name] = {
                        x: root._cx,
                        y: root._cy
                    };
                    Config.update({
                        clockPositions: positions
                    });

                    clockRoot._snapAfterDrag = true;
                    clockRoot.currentCx = clockRoot.targetCx;
                    clockRoot.currentCy = clockRoot.targetCenterY;
                    clockRoot._snapAfterDrag = false;
                }
            }
            onTranslationChanged: {
                if (active) {
                    root._dragDx = translation.x;
                    root._dragDy = translation.y;
                }
            }
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
}