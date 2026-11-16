pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.components.screensaver
import qs.services
import qs.style

Item {
    WlSessionLock {
        locked: LockscreenService.locked

        WlSessionLockSurface {
            id: lockSurface
            color: slate ? Colors.md3.surface : "black"

            property bool forceShow: false
            readonly property bool mountedAlreadyBlurred: LockscreenService.lockVisualActive
            property bool slate: LockscreenService.fromSaver
            property bool stageLive: LockscreenService.fromSaver
            property bool waking: false

            function wake(): void {
                if (!slate || waking)
                    return;
                waking = true;
                slate = false;
                if (stageLoader.item)
                    stageFade.start();
                else
                    stageLive = false;
            }

            function sleep(): void {
                if (slate)
                    return;
                waking = false;
                clockFadeIn.stop();
                fadeInAnimation.stop();
                clockWrapper.opacity = 0;
                lockContent.opacity = 0;
                stageLoader.opacity = 1;
                wakeSensor.armed = false;
                wakeSensor.hx = -1;
                stageLive = true;
                slate = true;
            }

            Connections {
                target: LockscreenService
                function onSaverStart() { lockSurface.sleep(); }
            }

            onSlateChanged: if (!slate && !LockscreenService.unlockAnimating) {
                clockWrapper.tryFadeIn();
                lockContent.tryFadeIn();
            }

            Image {
                id: lockWallImg
                anchors.fill: parent
                asynchronous: true
                cache: true
                source: LockscreenService.artBackground() || (WallpaperService.currentWall ? ("file://" + WallpaperService.currentWallPreview) : "")
                fillMode: Image.PreserveAspectCrop
                visible: false
                sourceSize.width: lockSurface.screen ? Math.max(1, Math.round(lockSurface.screen.width * lockSurface.screen.devicePixelRatio / LockscreenService.decodeDivisor)) : 480
                smooth: false

                readonly property bool settled: status === Image.Ready || status === Image.Error || source === ""
            }

            Timer {
                interval: 2000
                running: !lockWallImg.settled
                onTriggered: lockSurface.forceShow = true
            }

            MultiEffect {
                id: lockBlur
                anchors.fill: lockWallImg
                source: lockWallImg
                blurEnabled: true
                autoPaddingEnabled: false
                blurMax: 64
                blur: LockscreenService.blurAmount

                opacity: (lockWallImg.settled || lockSurface.forceShow) ? 1 : 0

                property bool blurBehaviorEnabled: false
                Component.onCompleted: {
                    if (!lockSurface.mountedAlreadyBlurred)
                        blurBehaviorEnabled = true;
                }

                Behavior on opacity {
                    enabled: lockBlur.blurBehaviorEnabled
                    NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Colors.md3.surface_container, 0.65)
            }

            CavaVisualizer {
                id: cavaVisualizer
                anchors.fill: parent
                pause: lockSurface.stageLive
                visible: Config.cava.enabled
            }

            Loader {
                id: stageLoader
                anchors.fill: parent
                active: lockSurface.stageLive

                sourceComponent: SaverStage {
                    mode: Config.screensaver.mode
                    speed: Config.screensaver.speed
                    showClock: Config.screensaver.showClock
                    monochrome: Config.screensaver.monochrome
                    shuffleSec: Config.screensaver.shuffleMinutes * 60
                }

                NumberAnimation {
                    id: stageFade
                    target: stageLoader
                    property: "opacity"
                    to: 0
                    duration: 400
                    easing.type: Easing.OutCubic
                    onFinished: lockSurface.stageLive = false
                }
            }

            Item {
                id: clockWrapper
                anchors.fill: parent
                opacity: 0

                function tryFadeIn() {
                    if (!lockSurface.slate && (!Config.desktopClock || LockscreenService.lockVisualActive))
                        clockFadeIn.start()
                }

                Component.onCompleted: tryFadeIn()

                Connections {
                    target: LockscreenService
                    function onLockVisualActiveChanged() {
                        if (LockscreenService.lockVisualActive)
                            clockWrapper.tryFadeIn()
                    }
                    function onUnlockAnimationStart() {
                        clockFadeIn.stop()
                        clockFadeOut.start()
                    }
                }

                NumberAnimation {
                    id: clockFadeIn
                    target: clockWrapper; property: "opacity"
                    from: 0; to: 1
                    duration: Config.desktopClock ? 0 : 200
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    id: clockFadeOut
                    target: clockWrapper; property: "opacity"
                    from: 1; to: 0; duration: 150
                    easing.type: Easing.InCubic
                }

                ClockWidget {
                    anchors.fill: parent
                    modelData: lockSurface.screen
                    forceVisible: true
                    forceCentered: true
                    animate: false
                }
            }

            Item {
                id: lockContent
                anchors.fill: parent
                opacity: 0

                function tryFadeIn() {
                    if (!lockSurface.slate && (!Config.desktopClock || LockscreenService.lockVisualActive))
                        fadeInAnimation.start()
                }

                Component.onCompleted: tryFadeIn()

                Connections {
                    target: LockscreenService
                    function onLockVisualActiveChanged() {
                        if (LockscreenService.lockVisualActive)
                            lockContent.tryFadeIn()
                    }
                    function onUnlockAnimationStart() {
                        fadeInAnimation.stop()
                        fadeOutAnimation.start()
                    }
                }

                NumberAnimation {
                    id: fadeInAnimation
                    target: lockContent; property: "opacity"
                    from: 0; to: 1; duration: 200
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    id: fadeOutAnimation
                    target: lockContent; property: "opacity"
                    from: 1; to: 0; duration: 150
                    easing.type: Easing.InCubic
                }

                LockSurface { anchors.fill: parent }
            }

            Item {
                id: wakeSensor
                anchors.fill: parent
                z: 100
                property bool armed: false
                property real hx: -1
                property real hy: -1

                Timer {
                    running: lockSurface.slate
                    interval: 600
                    onTriggered: wakeSensor.armed = true
                }

                HoverHandler {
                    enabled: lockSurface.slate
                    onPointChanged: {
                        if (wakeSensor.hx < 0) {
                            wakeSensor.hx = point.position.x;
                            wakeSensor.hy = point.position.y;
                        } else if (wakeSensor.armed && Math.hypot(point.position.x - wakeSensor.hx, point.position.y - wakeSensor.hy) > 24) {
                            LockscreenService.saverWake();
                        }
                    }
                }

                Connections {
                    target: LockscreenService
                    function onSaverWake() { lockSurface.wake(); }
                    function onCurrentTextChanged() {
                        if (wakeSensor.armed && lockSurface.slate)
                            LockscreenService.saverWake();
                    }
                }
            }

            component LockCornerBlock: Item {
                id: block
                readonly property int cr: 26
                property int type: 0
                width: cr; height: cr
                clip: true
                visible: Config.screenCorners
                Rectangle {
                    width: block.cr * 4; height: block.cr * 4
                    radius: block.cr * 2
                    color: "transparent"
                    border.width: block.cr
                    border.color: GameModeService.active ? "transparent" : "black"
                    x: (block.type === 1 || block.type === 3) ? -block.cr * 2 : -block.cr
                    y: (block.type === 2 || block.type === 3) ? -block.cr * 2 : -block.cr
                }
            }

            LockCornerBlock { type: 0; anchors.top: parent.top;    anchors.left:  parent.left  }
            LockCornerBlock { type: 1; anchors.top: parent.top;    anchors.right: parent.right }
            LockCornerBlock { type: 2; anchors.bottom: parent.bottom; anchors.left:  parent.left  }
            LockCornerBlock { type: 3; anchors.bottom: parent.bottom; anchors.right: parent.right }
        }
    }
}