import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.style

Item {
    WlSessionLock {
        locked: LockscreenService.locked

        WlSessionLockSurface {
            id: lockSurface
            color: "black"

            Image {
                id: lockWallImg
                anchors.fill: parent
                asynchronous: true
                cache: true
                source: WallpaperService.currentWall ? ("file://" + WallpaperService.currentWallPreview) : ""
                fillMode: Image.PreserveAspectCrop
                visible: false

                function _isSettled() {
                    return status === Image.Ready || status === Image.Error || source === "";
                }

                onStatusChanged: if (_isSettled()) lockBlur.opacity = 1
                Component.onCompleted: if (_isSettled()) lockBlur.opacity = 1
            }

            Timer {
                interval: 2000
                running: true
                onTriggered: lockBlur.opacity = 1
            }

            FastBlur {
                id: lockBlur
                anchors.fill: lockWallImg
                source: lockWallImg
                radius: 64
                opacity: 0

                Behavior on opacity {
                    NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.alpha(Colors.md3.surface_container, 0.65)
                }
            }

            Item {
                id: clockWrapper
                anchors.fill: parent
                opacity: 0

                function tryFadeIn() {
                    if (!Config.desktopClock || LockscreenService.lockVisualActive)
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
                    if (!Config.desktopClock || LockscreenService.lockVisualActive)
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