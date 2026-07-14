import QtQuick
import QtMultimedia
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.style

PanelWindow {
    id: root
    required property var modelData
    screen: modelData
    exclusionMode: ExclusionMode.Ignore

    color: "transparent"
    focusable: (Config.clock.manualPos ?? false) && !LockscreenService.locked

    WlrLayershell.namespace: "quickshell:background"
    WlrLayershell.layer: WlrLayer.Bottom
    anchors { top: true; bottom: true; left: true; right: true }

    readonly property bool shouldBlur: LockscreenService.locked || LockscreenService.lockVisualActive
    
    readonly property string activeWall: {
        const isVid = /\.(mp4|mkv|webm|mov|avi|m4v)$/i.test(WallpaperService.currentWall);
        if (GameModeService.active && isVid && WallpaperService.currentWallPreview) {
            return WallpaperService.currentWallPreview;
        }
        return WallpaperService.currentWall;
    }

    readonly property bool shouldPause: root.lockPauseActive || GameModeService.active

    property bool blurLoaderActive: false
    property bool lockPauseActive: false

    Timer {
        id: lockPauseTimer
        interval: 400
        repeat: false
        onTriggered: root.lockPauseActive = true
    }

    onShouldBlurChanged: {
        if (shouldBlur) {
            blurLoaderActive = true;
            lockPauseTimer.restart();
        } else {
            lockPauseTimer.stop();
            root.lockPauseActive = false;
            unloadDelay.restart();
        }
    }

    Timer {
        id: unloadDelay
        interval: 420
        onTriggered: root.blurLoaderActive = false
    }

    Component.onCompleted: {
        if (shouldBlur)
            blurLoaderActive = true;
    }

    readonly property Item wallpaperVisual: wallpaperLoader.item ? wallpaperLoader.item.wallpaperVisual : null

    Loader {
        id: wallpaperLoader
        anchors.fill: parent
        active: !Config.useAwww
        sourceComponent: Item {
            id: wallpaperContainer
            anchors.fill: parent

            property int frontSlot: 0
            readonly property Item wallpaperVisual: (frontSlot === 0 ? slotA : slotB).wallpaperVisual

            function _swapTo(path) {
                if (!path)
                    return;
                const front = frontSlot === 0 ? slotA : slotB;
                const back = frontSlot === 0 ? slotB : slotA;
                if (front.path === path)
                    return;
                back.path = path;
                back.readyToShow(() => {
                    wallpaperContainer.frontSlot = wallpaperContainer.frontSlot === 0 ? 1 : 0;
                });
            }

            Component.onCompleted: {
                slotA.path = root.activeWall;
            }

            Connections {
                target: root
                function onActiveWallChanged() {
                    wallpaperContainer._swapTo(root.activeWall);
                }
            }

            WallpaperSlot {
                id: slotA
                anchors.fill: parent
                isFront: wallpaperContainer.frontSlot === 0
                pause: root.shouldPause
            }
            WallpaperSlot {
                id: slotB
                anchors.fill: parent
                isFront: wallpaperContainer.frontSlot === 1
                pause: root.shouldPause
            }
        }
    }

    component WallpaperSlot: Item {
        id: slot
        property string path: ""
        property bool isFront: false
        property bool pause: false

        readonly property bool isVideo: path
            ? /\.(mp4|mkv|webm|mov|avi|m4v)$/i.test(path)
            : false

        readonly property bool videoTornDown: isVideo && GameModeService.active

        readonly property Item liveVisual: isVideo ? (videoLoader.item ? videoLoader.item.videoOutput : null) : img
        readonly property Item wallpaperVisual: frozenFrame.visible ? frozenFrame : liveVisual

        readonly property bool shouldPlay: isVideo && isFront && !pause && !videoTornDown

        function readyToShow(cb) {
            if (slot.isVideo || slot.videoTornDown) {
                cb();
                return;
            }

            if (img.status === Image.Ready || img.status === Image.Error || img.source === "") {
                cb();
                return;
            }
            const handler = () => {
                if (img.status === Image.Ready || img.status === Image.Error) {
                    img.statusChanged.disconnect(handler);
                    cb();
                }
            };
            img.statusChanged.connect(handler);
        }

        opacity: isFront ? 1 : 0
        scale: isFront ? 1 : 0.94
        z: isFront ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 550; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 550; easing.type: Easing.OutCubic }
        }

        onPathChanged: frozenFrame.visible = false
        onVideoTornDownChanged: {
            if (videoTornDown) {
                frozenFrame.visible = false;
            }
        }

        AnimatedImage {
            id: img
            anchors.fill: parent
            visible: !slot.isVideo
            asynchronous: true
            cache: true
            source: (!slot.isVideo && slot.path) ? ("file://" + slot.path) : ""
            fillMode: Image.PreserveAspectCrop
        }

        Loader {
            id: videoLoader
            anchors.fill: parent
            asynchronous: false
            active: slot.isVideo && !slot.videoTornDown

            sourceComponent: Component {
                Item {
                    id: videoRoot
                    anchors.fill: parent
                    readonly property alias videoOutput: vo
                    property bool ready: false

                    MediaPlayer {
                        id: player
                        source: slot.path ? ("file://" + slot.path) : ""
                        videoOutput: vo
                        loops: MediaPlayer.Infinite
                        onSourceChanged: videoRoot.ready = false
                        onMediaStatusChanged: {
                            if (mediaStatus === MediaPlayer.Loaded || mediaStatus === MediaPlayer.Buffered) {
                                videoRoot.ready = true;
                            }
                        }
                    }

                    VideoOutput {
                        id: vo
                        anchors.fill: parent
                        visible: !frozenFrame.visible
                        fillMode: VideoOutput.PreserveAspectCrop
                    }

                    Component.onCompleted: {
                        if (slot.shouldPlay) {
                            frozenFrame.visible = false;
                            player.play();
                        } else {
                            player.pause();
                        }
                    }

                    Connections {
                        target: slot
                        function onShouldPlayChanged() {
                            if (slot.shouldPlay) {
                                frozenFrame.visible = false;
                                player.play();
                            } else {
                                frozenFrame.scheduleUpdate();
                                frozenFrame.visible = true;
                                player.pause();
                            }
                        }
                    }
                }
            }
        }

        ShaderEffectSource {
            id: frozenFrame
            anchors.fill: parent
            sourceItem: videoLoader.item ? videoLoader.item.videoOutput : null
            live: false
            hideSource: false
            visible: false
        }
    }

    Loader {
        id: blurLoader
        anchors.fill: parent
        active: root.blurLoaderActive
        z: 2

        onLoaded: {
            item.targetActive = root.shouldBlur;
        }

        sourceComponent: Item {
            id: blurRoot
            anchors.fill: parent

            property bool targetActive: false

            opacity: targetActive ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: 400; easing.type: Easing.InOutCubic }
            }

            Component.onCompleted: {
                Qt.callLater(() => {
                    targetActive = root.shouldBlur;
                });
            }

            Image {
                id: blurSrcImg
                anchors.fill: parent
                source: (WallpaperService.currentWallPreview || WallpaperService.currentWall) 
                    ? ("file://" + (WallpaperService.currentWallPreview || WallpaperService.currentWall)) 
                    : ""
                fillMode: Image.PreserveAspectCrop
                visible: false
            }

            FastBlur {
                anchors.fill: parent
                source: blurSrcImg
                radius: blurRoot.targetActive ? 64 : 0

                Behavior on radius {
                    NumberAnimation { duration: 400; easing.type: Easing.InOutCubic }
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Colors.md3.surface_container, 0.65)
            }

            Connections {
                target: root
                function onShouldBlurChanged() {
                    blurRoot.targetActive = root.shouldBlur;
                }
            }
        }
    }

    Loader {
        anchors.fill: parent
        active: Config.desktopClock
        z: 4
        sourceComponent: ClockWidget { modelData: root.modelData }
    }

    Item {
        anchors.fill: parent

        readonly property int gradientHeight: 120
        readonly property bool gradientOn: Config.bar.transparency === 2 && !root.shouldBlur
        z: 4

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.gradientHeight

            opacity: (parent.gradientOn && Config.bar.position === 0) ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }

            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Qt.alpha(Colors.md3.background, 0.6) }
                GradientStop { position: 1.0; color: Qt.alpha(Colors.md3.background, 0) }
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.gradientHeight

            opacity: (parent.gradientOn && Config.bar.position === 1) ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }

            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Qt.alpha(Colors.md3.background, 0) }
                GradientStop { position: 1.0; color: Qt.alpha(Colors.md3.background, 0.5) }
            }
        }
    }
}