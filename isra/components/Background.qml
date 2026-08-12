import QtQuick
import QtQuick.Effects
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

    WlrLayershell.namespace: "quickshell:background"
    WlrLayershell.layer: WlrLayer.Background
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
            property string activeTransitionType: "crossfade"
            readonly property Item wallpaperVisual: (frontSlot === 0 ? slotA : slotB).wallpaperVisual

            function _swapTo(path) {
                if (!path)
                    return;
                const front = frontSlot === 0 ? slotA : slotB;
                const back = frontSlot === 0 ? slotB : slotA;
                if (front.path === path)
                    return;
                wallpaperContainer.activeTransitionType = Config.background.transitionType === "random"
                    ? ["crossfade", "wipe", "circle"][Math.floor(Math.random() * 3)]
                    : Config.background.transitionType;
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
                transitionType: wallpaperContainer.activeTransitionType
            }
            WallpaperSlot {
                id: slotB
                anchors.fill: parent
                isFront: wallpaperContainer.frontSlot === 1
                pause: root.shouldPause
                transitionType: wallpaperContainer.activeTransitionType
            }
        }
    }

    component WallpaperSlot: Item {
        id: slot
        property string path: ""
        property bool isFront: false
        property bool pause: false
        property string transitionType: "crossfade"

        readonly property bool isVideo: path
            ? /\.(mp4|mkv|webm|mov|avi|m4v)$/i.test(path)
            : false

        readonly property bool videoTornDown: isVideo && GameModeService.active

        readonly property Item liveVisual: isVideo ? (videoLoader.item ? videoLoader.item.videoOutput : null) : img
        readonly property Item wallpaperVisual: frozenFrame.visible ? frozenFrame : liveVisual

        readonly property bool shouldPlay: isVideo && isFront && !pause && !videoTornDown

        readonly property int transitionDuration: Config.background.transitionDuration ?? 550
        readonly property real _diagonal: Math.sqrt(width * width + height * height)

        readonly property bool _maskThisSlot: (transitionType === "circle"
                && (Config.background.circleReverse ? !isFront : isFront)
                && _progress < 1)
            || (transitionType === "wipe" && isFront && _progress < 1)

        readonly property real _wipeAngleRad: (Config.background.wipeAngle ?? 0) * Math.PI / 180
        readonly property real _wipeDx: Math.cos(_wipeAngleRad)
        readonly property real _wipeDy: Math.sin(_wipeAngleRad)

        readonly property real _wipeAx: Math.abs(_wipeDx)
        readonly property real _wipeAy: Math.abs(_wipeDy)

        readonly property real _wipeSpan: _wipeAx * width + _wipeAy * height
        readonly property real _displacement: Math.max(0, Math.min(1,
            (Config.background.transitionDisplacement ?? 20) / 100))

        readonly property real _wipeDrift: _displacement * _wipeSpan * (1 - _progress)

        readonly property real _contentOffsetX: transitionType === "wipe"
            ? (isFront ? -1 : 1) * _wipeDrift * _wipeDx
            : 0
        readonly property real _contentOffsetY: transitionType === "wipe"
            ? (isFront ? -1 : 1) * _wipeDrift * _wipeDy
            : 0

        readonly property real _wipePeakAtX: _wipeSpan > 0 ? width * _wipeAx / _wipeSpan : 1
        readonly property real _wipePeakAtY: _wipeSpan > 0 ? height * _wipeAy / _wipeSpan : 1

        readonly property real _wipeScale: width > 0 && height > 0 ? Math.max(
            1 + 2 * _displacement * _wipeSpan * _wipeAx
                * (1 - Math.max(_progress, _wipePeakAtX)) / width,
            1 + 2 * _displacement * _wipeSpan * _wipeAy
                * (1 - Math.max(_progress, _wipePeakAtY)) / height) : 1

        readonly property real _circleScale: 1 + _displacement * (1 - _progress)

        readonly property real _crossfadeScale: 1 - 0.3 * _displacement * (1 - _progress)

        readonly property real _contentScale: {
            if (transitionType === "wipe")
                return _wipeScale;
            if (transitionType === "circle")
                return _circleScale;
            return 1;
        }

        property real _progress: isFront ? 1 : 0
        Behavior on _progress {
            NumberAnimation { duration: slot.transitionDuration; easing.type: Easing.OutCubic }
        }

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

        opacity: transitionType === "crossfade" ? _progress : 1
        scale: transitionType === "crossfade" ? _crossfadeScale : 1
        z: (transitionType === "circle" && Config.background.circleReverse)
            ? (isFront ? 0 : 1)
            : (isFront ? 1 : 0)

        onPathChanged: frozenFrame.visible = false
        onVideoTornDownChanged: {
            if (videoTornDown) {
                frozenFrame.visible = false;
            }
        }

        Item {
            id: content
            anchors.fill: parent

            layer.enabled: slot._maskThisSlot
            layer.samples: 4
            layer.smooth: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: slot.transitionType === "wipe" ? wipeMask : circleMask
            }

            Item {
                id: shifted
                anchors.fill: parent
                transform: [
                    Scale {
                        origin.x: shifted.width / 2
                        origin.y: shifted.height / 2
                        xScale: slot._contentScale
                        yScale: slot._contentScale
                    },
                    Translate {
                        x: slot._contentOffsetX
                        y: slot._contentOffsetY
                    }
                ]

                AnimatedImage {
                    id: img
                    anchors.fill: parent
                    visible: !slot.isVideo
                    asynchronous: true
                    source: (!slot.isVideo && slot.path) ? ("file://" + slot.path) : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.height: root.screen ? Math.round(root.screen.height * root.screen.devicePixelRatio) : 1080
                    playing: slot.isFront && !slot.pause
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
        }

        Item {
            id: wipeMask
            width: slot.width
            height: slot.height
            visible: false
            layer.enabled: true
            layer.samples: 4
            layer.smooth: true

            readonly property real _sweep: slot._wipeSpan * (slot._progress - 0.5) - slot._diagonal
            readonly property real _cx: slot.width / 2 + slot._wipeDx * _sweep
            readonly property real _cy: slot.height / 2 + slot._wipeDy * _sweep

            Rectangle {
                width: slot._diagonal * 2
                height: slot._diagonal * 4
                x: wipeMask._cx - width / 2
                y: wipeMask._cy - height / 2
                rotation: Config.background.wipeAngle
                color: "black"
            }
        }

        Item {
            id: circleMask
            width: slot.width
            height: slot.height
            visible: false
            layer.enabled: true
            layer.samples: 4
            layer.smooth: true

            Rectangle {
                width: slot._diagonal * slot._progress
                height: width
                radius: width / 2
                anchors.centerIn: parent
                color: "black"
            }
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
                layer.enabled: true
                layer.textureSize: Qt.size(sourceSize.width, sourceSize.height)

                sourceSize.width: root.screen ? Math.max(1, Math.round(root.screen.width * root.screen.devicePixelRatio / (Config.blurEffects ? 4 : 1))) : 480
                sourceSize.height: root.screen ? Math.max(1, Math.round(root.screen.height * root.screen.devicePixelRatio / (Config.blurEffects ? 4 : 1))) : 270
            }

            FastBlur {
                anchors.fill: parent
                source: blurSrcImg
                radius: blurRoot.targetActive && Config.blurEffects ? 64 : 0

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

    Item {
        id: editDim
        anchors.fill: parent
        z: 2
        opacity: EditModeService.active ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.InOutCubic }
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.alpha("black", 0.35)
        }

        Canvas {
            id: editGridCanvas
            anchors.fill: parent
            readonly property real spacing: 24
            readonly property real dotRadius: 1.2

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                ctx.fillStyle = Qt.alpha(Colors.md3.primary, 0.45);
                for (let x = 0; x <= width; x += spacing) {
                    for (let y = 0; y <= height; y += spacing) {
                        ctx.beginPath();
                        ctx.arc(x, y, dotRadius, 0, Math.PI * 2);
                        ctx.fill();
                    }
                }
            }

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
        }
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
