import QtQuick
import QtQuick.Effects
import QtQuick.Window
import QtMultimedia
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

    WlrLayershell.namespace: "quickshell:wallpaper"
    WlrLayershell.layer: WlrLayer.Background
    anchors { top: true; bottom: true; left: true; right: true }

    property int audioEpoch: 0

    Connections {
        target: AudioService
        function onSinkChanged() {
            sinkSettleTimer.restart();
        }
    }

    Timer {
        id: sinkSettleTimer
        interval: 350
        onTriggered: root.audioEpoch++
    }

    readonly property string activeWallPath: {
        const isVid = /\.(mp4|mkv|webm|mov|avi|m4v)$/i.test(WallpaperService.currentWall);
        if (GameModeService.active && isVid && WallpaperService.currentWallPreview) {
            return WallpaperService.currentWallPreview;
        }
        return WallpaperService.currentWall;
    }

    readonly property bool shouldPause: root.lockPauseActive || GameModeService.active

    property bool lockPauseActive: false

    readonly property bool shouldBlur: LockscreenService.locked || LockscreenService.lockVisualActive

    Timer {
        id: lockPauseTimer
        interval: 400
        repeat: false
        onTriggered: root.lockPauseActive = true
    }

    onShouldBlurChanged: {
        if (shouldBlur) {
            lockPauseTimer.restart();
        } else {
            lockPauseTimer.stop();
            root.lockPauseActive = false;
        }
    }

    Loader {
        id: wallpaperLoader
        anchors.fill: parent
        active: !Config.useAwww
        sourceComponent: Item {
            id: wallpaperContainer
            anchors.fill: parent

            property int frontSlot: 0
            property string activeTransitionType: "crossfade"

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
                slotA.path = root.activeWallPath;
            }

            Connections {
                target: root
                function onActiveWallPathChanged() {
                    wallpaperContainer._swapTo(root.activeWallPath);
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

    Item {
        id: editDim
        z: 1
        anchors.fill: parent
        opacity: (EditModeService.active || EditModeService.settingsOpen) ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.InOutCubic }
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(Colors.md3.surface_container, 0.65)
        }

        Item {
            id: editGrid
            anchors.fill: parent

            readonly property int cols: WidgetGrid.columns(root.screen)
            readonly property int rows: WidgetGrid.rows(root.screen)

            Repeater {
                model: (EditModeService.active || editDim.visible) ? editGrid.cols * editGrid.rows : 0

                Rectangle {
                    id: dot
                    required property int index

                    width: 3
                    height: 3
                    radius: width / 2
                    antialiasing: true
                    color: Qt.alpha(Colors.md3.primary, 0.45)

                    x: WidgetGrid.cellX(root.screen, dot.index % editGrid.cols) + (WidgetGrid.cellWidth(root.screen) - width) / 2
                    y: WidgetGrid.cellY(root.screen, Math.floor(dot.index / editGrid.cols)) + (WidgetGrid.cellHeight(root.screen) - height) / 2
                }
            }
        }
    }

    Item {
        z: 2
        anchors.fill: parent

        readonly property int gradientHeight: 120
        readonly property bool gradientOn: Config.bar.transparency === 2 && !root.shouldBlur

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

        opacity: transitionType === "crossfade" ? (isFront ? _progress : 1) : 1
        scale: transitionType === "crossfade" ? _crossfadeScale : 1
        z: (transitionType === "circle" && Config.background.circleReverse)
            ? (isFront ? 0 : 1)
            : (isFront ? 1 : 0)

        onPathChanged: {
            frozenFrame.visible = false;
            unloadTimer.stop();
        }
        onVideoTornDownChanged: {
            if (videoTornDown) {
                frozenFrame.visible = false;
            }
        }

        onIsFrontChanged: {
            if (isFront) {
                unloadTimer.stop();
            } else {
                unloadTimer.restart();
            }
        }

        Timer {
            id: unloadTimer
            interval: slot.transitionDuration + 150
            onTriggered: {
                if (!slot.isFront && !slot.isVideo)
                    slot.path = "";
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
                    sourceSize.width: root.screen ? Math.round(root.screen.width * root.screen.devicePixelRatio) : 1080
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

                            Component {
                                id: audioOutComp
                                AudioOutput {
                                    muted: !Config.background.videoSound || root.screen !== Quickshell.screens[0]
                                    volume: Config.background.videoVolume ?? 0.5
                                }
                            }

                            Connections {
                                target: root
                                function onAudioEpochChanged() {
                                    const old = player.audioOutput;
                                    player.audioOutput = audioOutComp.createObject(player);
                                    if (old)
                                        old.destroy();
                                }
                            }

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
                                Component.onCompleted: audioOutput = audioOutComp.createObject(player)
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
}
